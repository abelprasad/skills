# setup-local-ai.ps1
# Local AI setup for a Windows work laptop (64 GB RAM).
# Interactive installer: it scans the machine first, shows a short one-line
# list of the models that can be installed, then lets you pick a set from a
# menu, like the Claude Code installer. One command, then choose.
# Installs Ollama + a model set, plus Python + faster-whisper for local transcription.
# Everything runs locally. No accounts, no API keys, no cloud.
# Idempotent: re-running skips anything already installed.
#
# Run from PowerShell (admin NOT required, but fine if you are admin):
#   powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1
#
# Automation (no prompts):
#   powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -All        # Recommended set, no prompt
#   powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -Minimal    # instruct + embeddings only
#   powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -Full       # Recommended + vision (GPU only)
#   powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -Yes        # skip the download confirm
#   powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -CpuOnly    # force the CPU model set
#   powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -SkipVision # skip the vision model
#   powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -SkillsAll  # also install all bundled skills into every detected AI setup
#   powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -SkillsSkip # skip the Skills step entirely
#   powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -Skills "claude,cursor"  # skills into those setups only
#   powershell -ExecutionPolicy Bypass -File setup-local-ai.ps1 -SkillsAll -IncludeClaudeMem -IncludeSecurityAudit  # + opt-in external installs
#
# Model sets (see models.md for sizes and benchmarks):
#   Recommended (default): qwen3.5:4b + qwen3:8b + coder + nomic-embed-text
#   Minimal:               qwen3.5:4b + nomic-embed-text only
#   Full:                  Recommended + qwen2.5vl:7b vision (GPU only)
#   Custom:                pick individual models from the list by number
# Python + faster-whisper (Whisper small, ~470 MB) are installed in every set:
# they are the transcription half of the meeting note taker.

param(
    [switch]$CpuOnly,
    [switch]$SkipVision,
    [switch]$All,
    [switch]$Minimal,
    [switch]$Full,
    [switch]$Yes,
    [switch]$SkillsAll,
    [switch]$SkillsSkip,
    [string]$Skills,
    [string]$SkillNames,
    [switch]$IncludeClaudeMem,
    [switch]$IncludeSecurityAudit
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$results = New-Object System.Collections.Generic.List[object]

# Shared Skills step (skills-install.ps1 next to this file). Dot-sourced so
# Invoke-SkillsStep can append to $results. If the file is missing, the
# step reports SKIP instead of failing the install.
$skillsScript = Join-Path $PSScriptRoot "skills-install.ps1"
if (Test-Path $skillsScript) { . $skillsScript }

function Add-Result {
    param([string]$Step, [string]$Status, [string]$Detail)
    $results.Add([PSCustomObject]@{ Step = $Step; Result = $Status; Detail = $Detail }) | Out-Null
    $color = "Green"
    if ($Status -eq "FAIL") { $color = "Red" }
    if ($Status -eq "SKIP") { $color = "Yellow" }
    Write-Host ("[{0}] {1} - {2}" -f $Status, $Step, $Detail) -ForegroundColor $color
}

function Test-Command {
    param([string]$Name)
    return [bool](Get-Command $Name -ErrorAction SilentlyContinue)
}

function Refresh-Path {
    $machine = [System.Environment]::GetEnvironmentVariable("Path", "Machine")
    $user = [System.Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = "$machine;$user"
}

function Wait-Ollama {
    param([int]$Seconds = 60)
    $deadline = (Get-Date).AddSeconds($Seconds)
    while ((Get-Date) -lt $deadline) {
        try {
            Invoke-RestMethod -Uri "http://localhost:11434/api/tags" -TimeoutSec 3 -ErrorAction Stop | Out-Null
            return $true
        } catch {
            Start-Sleep -Seconds 2
        }
    }
    return $false
}

function Test-OllamaModel {
    param([string]$Model)
    $list = (& ollama list 2>$null) -join "`n"
    return ($list -match ("(?m)^" + [regex]::Escape($Model) + "\s"))
}

Write-Host "=== Local AI setup (Ollama + faster-whisper) ===" -ForegroundColor Cyan
Write-Host "Everything stays on this laptop. No accounts, no API keys, no cloud." -ForegroundColor Cyan
Write-Host ""

# ---------- Step 0: Machine scan (runs FIRST, before the menu) ----------
# Detects what this machine can actually run, so the model list below is
# honest about what fits. Nothing is downloaded in this step.
$osName = "unknown OS"
$psVersion = $PSVersionTable.PSVersion.ToString()
$cpuName = "unknown CPU"
$cpuCores = 0
$totalRAMGB = 0
$freeRAMGB = 0
$gpuName = ""
$gpuVramMB = 0
$hasGpu = $false
$freeGB = 0
$ollamaVersion = $null
$installedModels = @()
try { $osName = (Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).Caption } catch { }
try {
    $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
    $totalRAMGB = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
} catch { }
try {
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction Stop
    $freeRAMGB = [math]::Round($os.FreePhysicalMemory / 1048576, 1)
} catch { }
try {
    $procs = Get-CimInstance Win32_Processor -ErrorAction Stop
    $cpuName = ($procs | Select-Object -First 1).Name
    $cpuCores = ($procs | Measure-Object -Property NumberOfCores -Sum).Sum
} catch { }
try { $freeGB = [math]::Round((Get-PSDrive C -ErrorAction Stop).Free / 1GB, 1) } catch { }
if (-not $CpuOnly -and (Test-Command "nvidia-smi")) {
    try {
        $smi = nvidia-smi --query-gpu=name,memory.total --format=csv,noheader 2>$null
        if ($LASTEXITCODE -eq 0 -and $smi) {
            $parts = ($smi -split ",")
            $gpuName = $parts[0].Trim()
            $vramText = ($parts[1].Trim() -split "\s+")[0]
            $gpuVramMB = [int]$vramText
            if ($gpuVramMB -ge 8192) { $hasGpu = $true }
        }
    } catch { }
}
if (Test-Command "ollama") {
    $ollamaVersion = ((& ollama --version 2>$null) -join " ").Trim()
    if (-not $ollamaVersion) { $ollamaVersion = "installed (version unknown)" }
    try {
        $installedModels = @(& ollama list 2>$null | Select-Object -Skip 1 | ForEach-Object { ($_ -split "\s+")[0] } | Where-Object { $_ })
    } catch { $installedModels = @() }
}
if ($CpuOnly) {
    Write-Host "CpuOnly: forcing the CPU model set." -ForegroundColor Yellow
}

Write-Host "--- Machine scan ---" -ForegroundColor Cyan
Write-Host ("OS: {0} | PowerShell {1}" -f $osName, $psVersion)
Write-Host ("CPU: {0} ({1} cores) | RAM: {2} GB total, {3} GB free" -f $cpuName, $cpuCores, $totalRAMGB, $freeRAMGB)
if ($gpuName) {
    Write-Host ("GPU: {0} ({1} MB VRAM)" -f $gpuName, $gpuVramMB)
} else {
    Write-Host "GPU: no NVIDIA GPU detected"
}
Write-Host ("Disk: {0} GB free on C:" -f $freeGB)
if ($ollamaVersion) {
    $already = if ($installedModels.Count -gt 0) { ($installedModels -join ", ") } else { "none pulled yet" }
    Write-Host ("Ollama: {0} | Already pulled: {1}" -f $ollamaVersion, $already)
} else {
    Write-Host "Ollama: not installed"
}
Write-Host ""
if ($hasGpu) { Add-Result "GPU detection" "PASS" ("$gpuName, ${gpuVramMB} MB VRAM") }
else { Add-Result "GPU detection" "PASS" "CPU path" }

# ---------- One-line model list (max 7, each model is exactly one line) ----------
# Benchmarks are vendor-reported, not head-to-head (see models.md).
$modelList = @(
    @{ Num = 1; Tag = "qwen3.5:4b";        Params = "4B";   SizeGB = 4.0; Size = "3.3-4GB"; Context = "256K"; Speed = "fast on CPU";            Capability = "instruct + summaries, multimodal text+image, MMLU-Pro 79.1"; Joke = "Brain of a sharp intern who never sleeps.";         MinRAMGB = 4;  NeedsGPU = $false },
    @{ Num = 2; Tag = "qwen3:8b";          Params = "8B";   SizeGB = 5.2; Size = "5.2GB";   Context = "256K"; Speed = "brisk on CPU, faster on GPU"; Capability = "general chat + reasoning, stronger than the 4B";          Joke = "Brain of a grad student who actually read the docs.";      MinRAMGB = 8;  NeedsGPU = $false },
    @{ Num = 3; Tag = "qwen3:14b";         Params = "14B";  SizeGB = 9.3; Size = "9.3GB";   Context = "256K"; Speed = "slow on CPU, wants a GPU";    Capability = "strongest general reasoning here";                          Joke = "Brain of a senior who knows everything but thinks out loud slowly."; MinRAMGB = 16; NeedsGPU = $false },
    @{ Num = 4; Tag = "qwen2.5-coder:7b";  Params = "7.6B"; SizeGB = 4.7; Size = "4.7GB";   Context = "32K";  Speed = "fast on CPU";            Capability = "code completion, explain, review";                         Joke = "Brain of a junior dev who only speaks in code.";           MinRAMGB = 6;  NeedsGPU = $false },
    @{ Num = 5; Tag = "qwen2.5-coder:14b"; Params = "14.7B"; SizeGB = 9.0; Size = "9.0GB";  Context = "32K";  Speed = "slow on CPU, wants a GPU";    Capability = "deeper code review";                                       Joke = "Brain of a staff engineer who reviews your PR at 3am.";     MinRAMGB = 16; NeedsGPU = $false },
    @{ Num = 6; Tag = "qwen2.5vl:7b";      Params = "7B";   SizeGB = 6.0; Size = "6.0GB";   Context = "125K"; Speed = "GPU only";               Capability = "describe screenshots, read UI";                          Joke = "Brain of an art student who also reads screenshots.";        MinRAMGB = 8;  NeedsGPU = $true },
    @{ Num = 7; Tag = "nomic-embed-text";  Params = "137M"; SizeGB = 0.3; Size = "274MB";  Context = "2K";   Speed = "instant, tiny";          Capability = "embeddings: search / RAG over notes";                      Joke = "Brain of a librarian who remembers where every book is.";    MinRAMGB = 1;  NeedsGPU = $false }
)

function Get-FitNote {
    param($Model)
    if ($installedModels -contains $Model.Tag) { return "ALREADY INSTALLED" }
    if ($Model.NeedsGPU -and -not $hasGpu) { return "NOT RECOMMENDED on this machine: needs a GPU" }
    if ($totalRAMGB -gt 0 -and $totalRAMGB -lt $Model.MinRAMGB) { return ("NOT RECOMMENDED on this machine: needs {0}GB+ RAM" -f $Model.MinRAMGB) }
    if ($freeGB -gt 0 -and $freeGB -lt ($Model.SizeGB + 5)) { return ("NOT RECOMMENDED on this machine: needs {0}GB free disk" -f ($Model.SizeGB + 5)) }
    return "FITS"
}

function Show-ModelList {
    Write-Host "--- Models you can install (one line each) ---" -ForegroundColor Cyan
    foreach ($m in $modelList) {
        $fit = Get-FitNote -Model $m
        $default = if ($m.Tag -eq "qwen3.5:4b") { " (default)" } else { "" }
        Write-Host ("[{0}] {1}{2} - {3}, {4}, {5} ctx, {6}, {7} | {8} | {9}" -f $m.Num, $m.Tag, $default, $m.Params, $m.Size, $m.Context, $m.Speed, $m.Capability, $m.Joke, $fit)
    }
    Write-Host "Scores are vendor-reported, not head-to-head. Models marked NOT RECOMMENDED are shown, not hidden."
    Write-Host ""
}

Show-ModelList

function Show-ModelMenu {
    Write-Host "Pick a model set:"
    Write-Host "  [1] Recommended (default) - qwen3.5:4b + qwen3:8b + coder + embeddings"
    Write-Host "  [2] Minimal                - qwen3.5:4b + embeddings only (smallest download)"
    if ($hasGpu) {
        Write-Host "  [3] Full                   - Recommended + vision (qwen2.5vl:7b, GPU only)"
    } else {
        Write-Host "  [3] Full                   - Recommended + vision (needs a GPU, not available here)"
    }
    Write-Host "  [4] Custom                 - pick individual models from the list by number"
    Write-Host "  [5] Quit"
    Write-Host ""
    Write-Host "Python + faster-whisper (transcription) are included in every set."
    Write-Host ""
    $choice = Read-Host "Pick one [1-5, default 1]"
    switch ($choice) {
        "2" { return "minimal" }
        "3" { return "full" }
        "4" { return "custom" }
        "5" { Write-Host "Cancelled. Nothing installed."; exit 0 }
        default { return "recommended" }
    }
}

# ---------- Model-set selection (menu or flags) ----------
$setName = $null
$interactive = $false
if ($Minimal) { $setName = "minimal" }
elseif ($Full) { $setName = "full" }
elseif ($All) { $setName = "recommended" }
if (-not $setName) {
    $interactive = $true
    $setName = Show-ModelMenu
}

# ---------- Build the model list for the chosen set ----------
# Main instruct model is qwen3.5:4b on both paths (smallest most capable;
# it also takes image input, so the separate vision model is optional).
$instructModel = "qwen3.5:4b"
$smallModel = "qwen3:8b"
$embedModel = "nomic-embed-text"
if ($hasGpu) {
    $codeModel = "qwen2.5-coder:14b"
    $visionModel = "qwen2.5vl:7b"
} else {
    $codeModel = "qwen2.5-coder:7b"
    $visionModel = ""
}
# Download sizes in GB, for the disk-space check.
$sizes = @{
    "qwen3.5:4b" = 4.0; "qwen3:8b" = 5.2; "qwen3:14b" = 9.3
    "qwen2.5-coder:14b" = 9.0; "qwen2.5-coder:7b" = 4.7
    "nomic-embed-text" = 0.3; "qwen2.5vl:7b" = 6.0
}

$models = @(
    @{ Name = $instructModel; Role = "instruct / summaries (note taker)" }
)
switch ($setName) {
    "recommended" {
        $models += @{ Name = $smallModel; Role = "small / fast" }
        $models += @{ Name = $codeModel; Role = "code" }
        $models += @{ Name = $embedModel; Role = "embeddings / search" }
    }
    "minimal" {
        $models += @{ Name = $embedModel; Role = "embeddings / search" }
    }
    "full" {
        $models += @{ Name = $smallModel; Role = "small / fast" }
        $models += @{ Name = $codeModel; Role = "code" }
        $models += @{ Name = $embedModel; Role = "embeddings / search" }
        if ($hasGpu -and -not $SkipVision) {
            $models += @{ Name = $visionModel; Role = "vision / screenshots (optional, GPU only)" }
        } elseif ($hasGpu) {
            Write-Host "Vision skipped (-SkipVision)." -ForegroundColor Yellow
        } else {
            Write-Host "Full set needs a GPU for the vision model - vision skipped, everything else installs." -ForegroundColor Yellow
        }
    }
    "custom" {
        # Toggle individual models from the list by number. qwen3.5:4b is
        # always included (it is the main model the test prompt checks).
        $defaultNums = if ($hasGpu) { "1 2 5 7" } else { "1 2 4 7" }
        Write-Host "Enter the numbers of the models to install, separated by spaces."
        Write-Host "qwen3.5:4b (#1) is always included - it is the main model."
        $nums = Read-Host ("Model numbers [default: " + $defaultNums + "]")
        if (-not $nums) { $nums = $defaultNums }
        $picked = @()
        foreach ($n in ($nums -split "[\s,]+")) {
            if ($n -match "^\d+$") {
                $entry = $modelList | Where-Object { $_.Num -eq [int]$n }
                if ($entry -and $entry.Tag -notin ($picked | ForEach-Object { $_.Name })) {
                    $fit = Get-FitNote -Model $entry
                    if ($fit -like "NOT RECOMMENDED*") {
                        Write-Host ("Warning: {0} is {1} - installing it anyway." -f $entry.Tag, $fit) -ForegroundColor Yellow
                    }
                    $picked += @{ Name = $entry.Tag; Role = $entry.Capability }
                }
            }
        }
        if (-not ($picked | Where-Object { $_.Name -eq $instructModel })) {
            $picked = @(@{ Name = $instructModel; Role = "instruct / summaries (note taker)" }) + $picked
        }
        $models = $picked
        if ($SkipVision) {
            $models = @($models | Where-Object { $_.Name -ne "qwen2.5vl:7b" })
        }
    }
}
$needGB = [math]::Ceiling(($models | ForEach-Object { $sizes[$_.Name] } | Measure-Object -Sum).Sum)
Write-Host ("Model set: {0} ({1} models, about {2} GB + 5 GB free-space buffer)." -f $setName, $models.Count, $needGB) -ForegroundColor Cyan
foreach ($m in $models) { Write-Host ("  - {0} ({1})" -f $m.Name, $m.Role) }

# ---------- Confirm before downloading (interactive mode only) ----------
if ($interactive -and -not $Yes) {
    $ans = Read-Host "Download about $needGB GB of models and install Ollama + Python + faster-whisper? [Y/n]"
    if ($ans -match "^[nN]") { Write-Host "Cancelled. Nothing installed."; exit 0 }
}

# ---------- Step 1: Ollama ----------
if (Test-Command "ollama") {
    Add-Result "Ollama installed" "SKIP" "ollama already on PATH"
} else {
    $installed = $false
    if (Test-Command "winget") {
        Write-Host "Installing Ollama with winget..." -ForegroundColor Cyan
        winget install --id Ollama.Ollama -e --silent --accept-source-agreements --accept-package-agreements
        Refresh-Path
        if (Test-Command "ollama") { $installed = $true }
    }
    if (-not $installed) {
        Write-Host "winget route did not work, falling back to the official installer..." -ForegroundColor Yellow
        $installer = Join-Path $env:TEMP "OllamaSetup.exe"
        Invoke-WebRequest -Uri "https://ollama.com/download/OllamaSetup.exe" -OutFile $installer
        # OllamaSetup.exe is an Inno Setup installer: silent flags confirmed
        # from Ollama's own updater source (/VERYSILENT /SUPPRESSMSGBOXES /NORESTART).
        Start-Process -FilePath $installer -ArgumentList "/VERYSILENT", "/SUPPRESSMSGBOXES", "/NORESTART" -Wait
        Refresh-Path
        if (Test-Command "ollama") { $installed = $true }
    }
    if ($installed) { Add-Result "Ollama installed" "PASS" "ollama is now on PATH" }
    else { Add-Result "Ollama installed" "FAIL" "ollama not found after install; open a new terminal and re-run" }
}

# ---------- Step 2: Ollama service ----------
if (Wait-Ollama -Seconds 15) {
    Add-Result "Ollama service" "PASS" "API responding on localhost:11434"
} else {
    Write-Host "Starting ollama serve in the background..." -ForegroundColor Cyan
    Start-Process -FilePath "ollama" -ArgumentList "serve" -WindowStyle Hidden
    if (Wait-Ollama -Seconds 60) { Add-Result "Ollama service" "PASS" "started ollama serve, API responding" }
    else { Add-Result "Ollama service" "FAIL" "API did not respond; start Ollama from the Start menu and re-run" }
}

# ---------- Step 3: Disk space ----------
$freeGB = [math]::Round((Get-PSDrive C).Free / 1GB, 1)
if ($freeGB -lt ($needGB + 5)) {
    Add-Result "Disk space" "FAIL" ("Only {0} GB free on C:, need about {1} GB for models" -f $freeGB, ($needGB + 5))
} else {
    Add-Result "Disk space" "PASS" ("{0} GB free on C:, need about {1} GB" -f $freeGB, ($needGB + 5))
}

# ---------- Step 4: model pulls ----------
foreach ($m in $models) {
    if (Test-OllamaModel $m.Name) {
        Add-Result ("Model " + $m.Name) "SKIP" ("already present (" + $m.Role + ")")
    } else {
        Write-Host ("Pulling {0} ({1})..." -f $m.Name, $m.Role) -ForegroundColor Cyan
        ollama pull $m.Name
        if (Test-OllamaModel $m.Name) { Add-Result ("Model " + $m.Name) "PASS" ("pulled (" + $m.Role + ")") }
        else { Add-Result ("Model " + $m.Name) "FAIL" "pull did not complete; re-run the script" }
    }
}

# ---------- Step 5: Python + faster-whisper ----------
$py = $null
foreach ($cmd in @("py", "python")) {
    if (Test-Command $cmd) { $py = $cmd; break }
}
if (-not $py) {
    Write-Host "Python not found, installing with winget..." -ForegroundColor Cyan
    if (Test-Command "winget") {
        winget install --id Python.Python.3.12 -e --silent --accept-source-agreements --accept-package-agreements
        Refresh-Path
        foreach ($cmd in @("py", "python")) {
            if (Test-Command $cmd) { $py = $cmd; break }
        }
    }
}
if ($py) {
    $pyVer = & $py --version 2>&1
    Add-Result "Python" "PASS" ("$py ($pyVer)")
} else {
    Add-Result "Python" "FAIL" "Python not found and winget install failed; install Python 3.12 from python.org and re-run"
}

if ($py) {
    $fw = & $py -m pip show faster-whisper 2>$null
    if ($fw) {
        Add-Result "faster-whisper" "SKIP" "already installed"
    } else {
        & $py -m pip install --upgrade faster-whisper
        $fw = & $py -m pip show faster-whisper 2>$null
        if ($fw) { Add-Result "faster-whisper" "PASS" "installed via pip" }
        else { Add-Result "faster-whisper" "FAIL" "pip install failed; check Python/pip and re-run" }
    }
}

# ---------- Step 6: Whisper small model + transcription smoke test ----------
if ($py) {
    $helper = Join-Path $env:TEMP "local-ai-whisper-test.py"
    $wavPath = Join-Path $env:TEMP "local-ai-test.wav"
    @'
import sys, math, wave, struct
from faster_whisper import WhisperModel

# 1s 440 Hz sine tone: no speech, but proves the pipeline loads and runs.
wav_path = sys.argv[1]
with wave.open(wav_path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)
    w.setframerate(16000)
    for i in range(16000):
        v = int(12000 * math.sin(2 * math.pi * 440 * i / 16000))
        w.writeframes(struct.pack("<h", v))

model = WhisperModel("small", device="cpu", compute_type="int8")
print("WHISPER MODEL READY")
segments, info = model.transcribe(wav_path, beam_size=1)
text = " ".join(s.text for s in segments).strip()
print("TRANSCRIBE OK, detected language:", info.language, "text:", repr(text))
'@ | Set-Content -Path $helper -Encoding utf8

    Write-Host "Downloading the Whisper small model and running a transcription smoke test (first run downloads ~470 MB)..." -ForegroundColor Cyan
    $out = & $py $helper $wavPath 2>&1 | Out-String
    if ($out -match "WHISPER MODEL READY" -and $out -match "TRANSCRIBE OK") {
        Add-Result "Whisper small + transcribe" "PASS" "model loaded, test audio transcribed"
    } else {
        Add-Result "Whisper small + transcribe" "FAIL" ("transcription test did not complete. Output: " + ($out -replace "`n", " " | Select-Object -First 1))
    }
}

# ---------- Step 7: test prompt to the instruct model ----------
$body = @{ model = $instructModel; prompt = "Reply with exactly these three words: LOCAL AI OK"; stream = $false } | ConvertTo-Json
try {
    $resp = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body $body -ContentType "application/json" -TimeoutSec 300
    if ($resp.response -match "LOCAL AI OK") {
        Add-Result "Test prompt ($instructModel)" "PASS" "model replied correctly"
    } else {
        Add-Result "Test prompt ($instructModel)" "FAIL" ("unexpected reply: " + $resp.response)
    }
} catch {
    Add-Result "Test prompt ($instructModel)" "FAIL" ("API call failed: " + $_.Exception.Message)
}

# ---------- Skills: install bundled skills into every detected AI setup ----------
if (Get-Command Invoke-SkillsStep -ErrorAction SilentlyContinue) {
    Invoke-SkillsStep -Interactive $interactive -SkillsAll $SkillsAll -SkillsSkip $SkillsSkip -SkillsCsv $Skills -SkillNamesCsv $SkillNames -IncludeClaudeMem $IncludeClaudeMem -IncludeSecurityAudit $IncludeSecurityAudit
} else {
    Add-Result "Skills" "SKIP" "skills-install.ps1 not found next to installer"
}

# ---------- Summary ----------
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
$results | Format-Table -AutoSize Step, Result, Detail
$failCount = ($results | Where-Object { $_.Result -eq "FAIL" }).Count
if ($failCount -eq 0) {
    Write-Host "ALL CHECKS PASSED. Local AI is ready." -ForegroundColor Green
    Write-Host ("Try it: ollama run {0}" -f $instructModel) -ForegroundColor Green
    exit 0
} else {
    Write-Host ("{0} check(s) FAILED. Fix the failures above and re-run the script (it skips what is already done)." -f $failCount) -ForegroundColor Red
    exit 1
}
