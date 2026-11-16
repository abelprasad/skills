# CodeGraph + RTK setup — Windows (PowerShell)
# Interactive installer: run with no flags and pick what to install from a
# menu, like the Claude Code installer. One command, then choose.
#
#   .\install.ps1
#
# Automation (no prompts):
#   .\install.ps1 -All                    # both, no prompt
#   .\install.ps1 -CodeGraphOnly          # CodeGraph only
#   .\install.ps1 -RTKOnly                # RTK only
#   .\install.ps1 -All -Yes               # both, skip the download confirm
#   .\install.ps1 -All -Repos "C:\github\dogsrun,https://github.com/you/repo"
#   .\install.ps1 -All -ScanRepos "C:\github"
#   .\install.ps1 -All -ReInit            # re-init repos already indexed
#   .\install.ps1 -All -SkipRepos         # skip the repo step entirely
#   .\install.ps1 -All -SkillsAll        # also install all bundled skills into every detected AI setup
#   .\install.ps1 -All -SkillsSkip        # skip the Skills step entirely
#   .\install.ps1 -All -Skills "claude,cursor"  # skills into those setups only
#   .\install.ps1 -All -SkillsAll -IncludeClaudeMem -IncludeSecurityAudit  # + opt-in external installs
#
# Work laptop = work only, no personal repos on it: the repo step is optional
# and skipped by default (press Enter at the prompt). On a work laptop, run
# `codegraph init` yourself in the repo you are working in. When you do opt
# in, the full picker is available: folder scan, individual paths, and
# GitHub clone URLs.
#
# What it installs:
#   CodeGraph — pre-indexed local code knowledge graph (100% local)
#   RTK       — compresses shell output before it reaches agent context
# Wiring: CodeGraph as an MCP server, RTK as a PreToolUse hook on Bash.
# RTK never blocks a command and never hides output (see `rtk bypass`).
# No repo paths, company names, or secrets are hardcoded here.
# Personal GitHub repos only: the repo picker never asks for, clones, or
# initializes company code. Company code stays out.
# If Windows blocks the script, run this first (current user only):
#   Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy Bypass -Force
param(
    [switch]$All,
    [switch]$CodeGraphOnly,
    [switch]$RTKOnly,
    [switch]$Yes,
    [string]$Repos,
    [string]$ScanRepos,
    [switch]$ReInit,
    [switch]$SkipRepos,
    [switch]$SkillsAll,
    [switch]$SkillsSkip,
    [string]$Skills,
    [switch]$IncludeClaudeMem,
    [switch]$IncludeSecurityAudit
)

$ErrorActionPreference = "Stop"
$results = New-Object System.Collections.Generic.List[object]

# Shared Skills step (skills-install.ps1 next to this file). Dot-sourced so
# Invoke-SkillsStep can append to $results. If the file is missing, the
# step reports SKIP instead of failing the install.
$skillsScript = Join-Path $PSScriptRoot "skills-install.ps1"
if (Test-Path $skillsScript) { . $skillsScript }

function Say($msg) { Write-Host ""; Write-Host "==> $msg" -ForegroundColor Cyan }

function Add-Result {
    param([string]$Status, [string]$Step, [string]$Detail)
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
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")
}

function Show-Menu {
    Write-Host ""
    Write-Host "=== CodeGraph + RTK setup ===" -ForegroundColor Cyan
    Write-Host "100% local tools. CodeGraph indexes your code on this machine;"
    Write-Host "RTK only compresses command output. Nothing leaves the machine."
    Write-Host ""
    Write-Host "  [1] CodeGraph only   - code knowledge graph for your agents"
    Write-Host "  [2] RTK only         - compress shell output before agent context"
    Write-Host "  [3] Both (default)   - CodeGraph + RTK"
    Write-Host "  [4] Quit"
    Write-Host ""
    $choice = Read-Host "Pick one [1-4, default 3]"
    switch ($choice) {
        "1" { return "codegraph" }
        "2" { return "rtk" }
        "4" { Write-Host "Cancelled. Nothing installed."; exit 0 }
        default { return "both" }
    }
}

function Install-CodeGraph {
    Say "Installing CodeGraph..."
    if (Test-Command "codegraph") {
        Add-Result "SKIP" "CodeGraph installed" ("codegraph already on PATH (" + (codegraph --version 2>$null) + ")")
        return
    }
    irm https://raw.githubusercontent.com/colbymchenry/codegraph/main/install.ps1 | iex
    Refresh-Path
    if (Test-Command "codegraph") {
        Add-Result "PASS" "CodeGraph installed" (codegraph --version 2>$null)
    } else {
        Add-Result "FAIL" "CodeGraph installed" "codegraph not on PATH after install; open a new terminal and re-run"
    }
}

function Install-RTK {
    Say "Installing RTK..."
    if (Test-Command "rtk") {
        Add-Result "SKIP" "RTK installed" ("rtk already on PATH (" + (rtk --version 2>$null) + ")")
        return
    }
    winget install rtk-ai.rtk --accept-source-agreements --accept-package-agreements
    Refresh-Path
    if (Test-Command "rtk") {
        Add-Result "PASS" "RTK installed" (rtk --version 2>$null)
    } else {
        Add-Result "FAIL" "RTK installed" "rtk not on PATH after install; open a new terminal and re-run"
    }
}

function Wire-CodeGraph {
    Say "Wiring CodeGraph into Claude Code (and any other detected agents)..."
    codegraph install --yes
    Add-Result "PASS" "CodeGraph wired" "MCP server added to your agents"
}

function Wire-RTK {
    # `rtk init -g` asks to patch %USERPROFILE%\.claude\settings.json. In a
    # non-interactive run it defaults to No, so merge the hook ourselves.
    Say "Wiring RTK into Claude Code..."
    rtk init -g
    try {
        $settingsPath = Join-Path $env:USERPROFILE ".claude\settings.json"
        $settings = @{}
        if (Test-Path $settingsPath) {
            $settings = Get-Content $settingsPath -Raw | ConvertFrom-Json -AsHashtable
        }
        if (-not $settings.ContainsKey("hooks")) { $settings["hooks"] = @{} }
        if (-not $settings["hooks"].ContainsKey("PreToolUse")) { $settings["hooks"]["PreToolUse"] = @() }
        $existing = $settings["hooks"]["PreToolUse"] | Where-Object {
            $_.matcher -eq "Bash" -and ($_.hooks | Where-Object { $_.command -eq "rtk hook claude" })
        }
        if (-not $existing) {
            $entry = @{ matcher = "Bash"; hooks = @(@{ type = "command"; command = "rtk hook claude" }) }
            $settings["hooks"]["PreToolUse"] += $entry
            $settings | ConvertTo-Json -Depth 10 | Set-Content $settingsPath -Encoding UTF8
            Add-Result "PASS" "RTK wired" ("hook merged into " + $settingsPath)
        } else {
            Add-Result "SKIP" "RTK wired" "hook already present"
        }
    } catch {
        Write-Host "Could not merge the RTK hook automatically. Add it manually to %USERPROFILE%\.claude\settings.json:"
        Write-Host '  { "hooks": { "PreToolUse": [{ "matcher": "Bash", "hooks": [{ "type": "command", "command": "rtk hook claude" }] }] } }'
        Add-Result "SKIP" "RTK wired" "automatic merge failed, manual step printed above"
    }
}

# --- Repo picker (CodeGraph only) ---------------------------------------------
# Personal GitHub repos only. Never prompt for, clone, or init company code.
function Get-GitRepos {
    param([string]$Parent)
    if (-not (Test-Path $Parent)) { return @() }
    Get-ChildItem -Path $Parent -Directory -Filter ".git" -Recurse -Depth 3 -ErrorAction SilentlyContinue |
        ForEach-Object { $_.Parent.FullName }
}

function Get-RepoNameFromUrl {
    param([string]$Url)
    $base = ($Url.TrimEnd("/").Split("/") | Select-Object -Last 1)
    return $base -replace "\.git$", ""
}

function Initialize-Repo {
    param([string]$RepoPath)
    $name = Split-Path $RepoPath -Leaf
    if ((Test-Path (Join-Path $RepoPath ".codegraph")) -and -not $ReInit) {
        Add-Result "SKIP" ("codegraph init: " + $name) "already initialized (use -ReInit to rebuild)"
        return
    }
    Push-Location $RepoPath
    try {
        codegraph init 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) {
            Add-Result "FAIL" ("codegraph init: " + $name) "codegraph init failed"
            return
        }
        $status = codegraph status 2>$null | Out-String
        $counts = ""
        foreach ($pat in @("([0-9,]+ files)", "([0-9,]+ nodes)")) {
            $m = [regex]::Match($status, $pat)
            if ($m.Success) { $counts += $m.Groups[1].Value + " " }
        }
        if (-not $counts) { $counts = "index built" }
        Add-Result "PASS" ("codegraph init: " + $name) $counts.Trim()
    } finally {
        Pop-Location
    }
}

function Invoke-RepoPicker {
    param([bool]$Interactive)
    # Work laptop = work only, no personal repos on it: this step is optional
    # and skipped by default. Personal repos only on personal machines; on a
    # work laptop, run `codegraph init` yourself in the repo you are working
    # in — do not paste repo names or paths here.
    if ($SkipRepos) {
        Write-Host "Repo step skipped (-SkipRepos). Run codegraph init later in any repo yourself."
        return
    }
    if ($Interactive) {
        Write-Host "Point CodeGraph at repos? (optional, press Enter to skip. On a work laptop, skip this. You can run codegraph init later in any repo yourself.)"
        Write-Host "Personal repos only on personal machines; on a work laptop, run codegraph init yourself in the repo you are working in, do not paste repo names or paths here."
        $optin = Read-Host "Point CodeGraph at repos? [y/N, Enter skips]"
        if ($optin -notmatch "^[yY]") {
            Write-Host "Skipped. Run codegraph init later in any repo yourself."
            return
        }
    } elseif (-not $Repos -and -not $ScanRepos) {
        Write-Host "No repos given. Repo step skipped — run codegraph init later in any repo yourself."
        return
    }
    Say "Point CodeGraph at your repos (personal GitHub repos only - company code stays out)."
    $selected = New-Object System.Collections.Generic.List[string]
    $cloneBase = Join-Path $env:USERPROFILE "github"

    # (a) Parent folder scan
    $scanTarget = $ScanRepos
    if (-not $scanTarget -and $Interactive) {
        $doScan = Read-Host "Scan a parent folder for repos? (e.g. $cloneBase) [y/N]"
        if ($doScan -match "^[yY]") {
            $scanTarget = Read-Host ("Parent folder to scan [default " + $cloneBase + "]")
            if (-not $scanTarget) { $scanTarget = $cloneBase }
        }
    }
    if ($scanTarget) {
        $found = @(Get-GitRepos -Parent $scanTarget)
        if ($found.Count -eq 0) {
            Write-Host ("No git repos found under " + $scanTarget)
        } else {
            Write-Host ("Found " + $found.Count + " repos under " + $scanTarget + ":")
            for ($i = 0; $i -lt $found.Count; $i++) {
                Write-Host ("  [" + ($i + 1) + "] " + $found[$i])
            }
            if ($Interactive) {
                $pick = Read-Host "Pick all (a), numbers separated by spaces (e.g. 1 3), or none (n) [default a]"
                switch -Regex ($pick) {
                    "^[nN]" { }
                    "^[aA]|^$" { foreach ($r in $found) { $selected.Add($r) } }
                    default {
                        foreach ($n in ($pick -split "[\s,]+")) {
                            if ($n -match "^\d+$" -and [int]$n -ge 1 -and [int]$n -le $found.Count) {
                                $selected.Add($found[[int]$n - 1])
                            }
                        }
                    }
                }
            } else {
                foreach ($r in $found) { $selected.Add($r) }
            }
        }
    }

    # (b) Individual paths / URLs, one per line, blank to finish
    if ($Repos) {
        foreach ($e in ($Repos -split ",")) {
            $e = $e.Trim()
            if ($e) { $selected.Add($e) }
        }
    } elseif ($Interactive) {
        Write-Host "Add repos one by one - a local path or a GitHub clone URL. Blank line to finish."
        while ($true) {
            $entry = Read-Host "Repo path or URL (blank to finish)"
            if (-not $entry) { break }
            $selected.Add($entry)
        }
    }

    # Clone URLs, then init each selected repo
    foreach ($entry in $selected) {
        $path = $entry
        if ($entry -match "://") {
            $rname = Get-RepoNameFromUrl -Url $entry
            $dest = Join-Path $cloneBase $rname
            if ($Interactive) {
                $answer = Read-Host ("Clone " + $entry + " into [" + $dest + "] (Enter to accept, or type another folder)")
                if ($answer) { $dest = $answer }
            }
            if (Test-Path (Join-Path $dest ".git")) {
                Write-Host ("Already cloned at " + $dest)
            } else {
                New-Item -ItemType Directory -Force -Path (Split-Path $dest -Parent) | Out-Null
                git clone $entry $dest
                if ($LASTEXITCODE -ne 0) {
                    Add-Result "FAIL" ("clone: " + $rname) ("git clone failed for " + $entry)
                    continue
                }
            }
            $path = $dest
        }
        if (Test-Path (Join-Path $path ".git")) {
            Initialize-Repo -RepoPath $path
        } else {
            Add-Result "SKIP" ("codegraph init: " + $entry) "not a git repo, skipped"
        }
    }
    if ($selected.Count -eq 0) {
        Write-Host "No repos selected. You can index a project any time with: cd <your-project>; codegraph init"
    }
}

function Main {
    # --- Pick what to install --------------------------------------------------
    $mode = $null
    $interactive = $false
    if ($All) { $mode = "both" }
    elseif ($CodeGraphOnly) { $mode = "codegraph" }
    elseif ($RTKOnly) { $mode = "rtk" }
    if (-not $mode) {
        $interactive = $true
        $mode = Show-Menu
    }

    # --- Confirm before downloading (interactive mode only) --------------------
    if ($interactive -and -not $Yes) {
        switch ($mode) {
            "codegraph" { Write-Host "This will install: CodeGraph" }
            "rtk" { Write-Host "This will install: RTK" }
            "both" { Write-Host "This will install: CodeGraph + RTK" }
        }
        $ans = Read-Host "Continue? [Y/n]"
        if ($ans -match "^[nN]") { Write-Host "Cancelled. Nothing installed."; return }
    }

    Refresh-Path
    switch ($mode) {
        "codegraph" {
            Install-CodeGraph
            Wire-CodeGraph
            Invoke-RepoPicker -Interactive $interactive
        }
        "rtk" {
            Install-RTK
            Wire-RTK
        }
        "both" {
            Install-CodeGraph
            Install-RTK
            Wire-CodeGraph
            Wire-RTK
            Invoke-RepoPicker -Interactive $interactive
        }
    }

    # --- Skills: install bundled skills into every detected AI setup -----------
    if (Get-Command Invoke-SkillsStep -ErrorAction SilentlyContinue) {
        Invoke-SkillsStep -Interactive $interactive -SkillsAll $SkillsAll -SkillsSkip $SkillsSkip -SkillsCsv $Skills -IncludeClaudeMem $IncludeClaudeMem -IncludeSecurityAudit $IncludeSecurityAudit
    } else {
        Add-Result "SKIP" "Skills" "skills-install.ps1 not found next to installer"
    }

    # --- Verify -----------------------------------------------------------------
    Say "Verifying..."
    if ($mode -ne "rtk") { codegraph --version }
    if ($mode -ne "codegraph") {
        rtk --version
        rtk gain
    }

    Write-Host ""
    Write-Host "=== Summary ===" -ForegroundColor Cyan
    $results | Format-Table -AutoSize Step, Result, Detail
    $failCount = ($results | Where-Object { $_.Result -eq "FAIL" }).Count
    if ($failCount -eq 0) {
        Say "Done. Restart your agent, then explore a project:"
        Write-Host "  codegraph explore <what you want to understand>"
        Write-Host "  rtk gain              # shows tokens saved so far"
    } else {
        Write-Host ("{0} check(s) FAILED. Fix the failures above and re-run (it skips what is already done)." -f $failCount) -ForegroundColor Red
    }
}

# Only run Main when executed as a script (not when dot-sourced for testing).
if ($MyInvocation.InvocationName -ne ".") {
    Main
}
