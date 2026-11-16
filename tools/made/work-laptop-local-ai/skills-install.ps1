# skills-install.ps1 — shared Skills step for the setup packs.
# Dot-source this file from a host installer, then call Invoke-SkillsStep.
#   . "$PSScriptRoot\skills-install.ps1"
#   Invoke-SkillsStep -Interactive $true -SkillsAll $SkillsAll -SkillsSkip $SkillsSkip -SkillsCsv $Skills
# This file runs nothing on load except defining functions and the tables.
# Host contract: the host defines a $results list of objects with Step /
# Result / Detail properties (both pack installers do). This file appends to
# it via Add-SkillResult and prints the same [PASS]/[SKIP]/[FAIL] lines.
#
# Skills source: a "skills" folder next to this file (bundled in the pack),
# one subfolder per skill with SKILL.md inside. Offered skills are exactly
# the folders found there — a skill with no source file is never offered.
# Install = copy the whole skill folder into <harness-skills>/<skill-name>/.
# i-have-adhd only: if the bundled copy is missing, it falls back to the
# upstream download (upstream text, not Abel's adopted version — reported
# as such in the result detail).
#
# External installs (never in "All", opt-in only): claude-mem and
# security-audit. Both need Node.js. Their commands were verified from
# their READMEs Nov 16, 2026 (see below). Each asks for confirmation
# before running, and prints what it needs first.
#
# Detection only: a harness that is not detected is reported SKIP and no
# directory is ever created for it. A harness is detected when its config
# folder exists on this machine or its command is on PATH.
#
# Harness skill folders (verified Nov 16, 2026):
#   Claude Code    ~/.claude/skills            (Anthropic docs)
#   Cursor         ~/.cursor/skills            (Cursor 2.4+ docs; also reads ~/.agents/skills)
#   GitHub Copilot ~/.copilot/skills           (Copilot CLI / VS Code personal path)
#   Codex          ~/.agents/skills            (OpenAI docs, current; legacy ~/.codex/skills used only if it already exists)
#   Gemini CLI     ~/.gemini/skills            (Google docs)
#   OpenCode       ~/.config/opencode/skills   (skills registries; some docs show singular "skill/" — plural is what the registries use)
#   Local (shared) ~/.agents/skills           (vendor-neutral folder Codex, Cursor and Gemini also read; same folder as Codex, deduped)
# VS Code project skills live in .github/skills inside each repo and are not
# covered by this machine-wide install.

$SkillsSourceDir = Join-Path $PSScriptRoot "skills"
$IHaveAdhdUpstreamUrl = "https://raw.githubusercontent.com/ayghri/i-have-adhd/main/skills/i-have-adhd/SKILL.md"

# Curated order for the menu. Only folders that actually exist are offered.
$SkillOrder = @("i-have-adhd", "local-ponytail", "summary", "repo-packaging", "qa-agent", "local-ui-ux-pro-max")
$SkillDescriptions = @{
    "i-have-adhd"          = "ADHD output protocol: action first, numbered steps, no preamble"
    "local-ponytail"       = "Laziest working solution: YAGNI, stdlib first, one line before fifty"
    "summary"              = "/summary: six-section handoff of everything talked and done"
    "repo-packaging"       = "ADRs, CLI product, privacy rule, dev-copy rule, presence"
    "qa-agent"             = "Checklist QA with screenshots + HTML report"
    "local-ui-ux-pro-max"  = "Design bundle: shadcn + Tailwind, brand, banners, slides"
}

# Optional external installs. Commands verified from their READMEs Nov 16, 2026.
# Never included in "All". Each needs Node.js and an explicit pick + confirm.
$ExternalInstalls = @(
    [PSCustomObject]@{
        Key = "claude-mem"; Display = "claude-mem"
        Description = "Persistent memory across sessions"
        Command = "npx claude-mem install --setup defer"
        Notes = "Needs Node.js. Setup is deferred to your first session (no browser sign-in during install). The observer trial asks for a payment method; memory lives in ~/.claude-mem. Source: https://github.com/thedotmack/claude-mem (Apache-2.0)"
    },
    [PSCustomObject]@{
        Key = "security-audit"; Display = "security-audit"
        Description = "Multi-phase security audit skill"
        Command = "npx skills add https://github.com/cloudflare/security-audit-skill --skill security-audit --global"
        Notes = "Needs Node.js. Installs via the skills CLI into your agents. Source: https://github.com/cloudflare/security-audit-skill (MIT)"
    }
)

function Add-SkillResult {
    param([string]$Status, [string]$Step, [string]$Detail)
    if ($null -ne $results) {
        $results.Add([PSCustomObject]@{ Step = $Step; Result = $Status; Detail = $Detail }) | Out-Null
    }
    $color = "Green"
    if ($Status -eq "FAIL") { $color = "Red" }
    if ($Status -eq "SKIP") { $color = "Yellow" }
    Write-Host ("[{0}] {1} - {2}" -f $Status, $Step, $Detail) -ForegroundColor $color
}

function Get-SkillsHarnesses {
    $homeDir = $HOME
    $has = { param([string]$Path) return (Test-Path $Path) }
    $onPath = { param([string]$Name) return [bool](Get-Command $Name -ErrorAction SilentlyContinue) }
    $claudeDetected = (& $has (Join-Path $homeDir ".claude")) -or (& $onPath "claude")
    $cursorDetected = (& $has (Join-Path $homeDir ".cursor")) -or (& $onPath "cursor")
    $copilotDetected = (& $has (Join-Path $homeDir ".copilot")) -or (& $onPath "copilot")
    $codexDetected = (& $has (Join-Path $homeDir ".agents")) -or (& $has (Join-Path $homeDir ".codex")) -or (& $onPath "codex")
    $geminiDetected = (& $has (Join-Path $homeDir ".gemini")) -or (& $onPath "gemini")
    $opencodeDetected = (& $has (Join-Path $homeDir ".config/opencode")) -or (& $onPath "opencode")
    # Codex target: current docs use ~/.agents/skills; use legacy
    # ~/.codex/skills only when it already exists and ~/.agents/skills does not.
    $codexDir = Join-Path $homeDir ".agents/skills"
    if ((-not (Test-Path $codexDir)) -and (Test-Path (Join-Path $homeDir ".codex/skills"))) {
        $codexDir = Join-Path $homeDir ".codex/skills"
    }
    $sharedDir = Join-Path $homeDir ".agents/skills"
    $localDetected = (Test-Path $sharedDir) -or $codexDetected -or $cursorDetected -or $geminiDetected
    return @(
        [PSCustomObject]@{ Key = "claude";   Display = "Claude Code";     Dir = (Join-Path $homeDir ".claude/skills");          Detected = $claudeDetected;   Note = "checked ~/.claude and `claude` on PATH" }
        [PSCustomObject]@{ Key = "cursor";   Display = "Cursor";          Dir = (Join-Path $homeDir ".cursor/skills");          Detected = $cursorDetected;   Note = "checked ~/.cursor and `cursor` on PATH" }
        [PSCustomObject]@{ Key = "copilot";  Display = "GitHub Copilot";  Dir = (Join-Path $homeDir ".copilot/skills");         Detected = $copilotDetected;  Note = "checked ~/.copilot and `copilot` on PATH" }
        [PSCustomObject]@{ Key = "codex";    Display = "Codex";           Dir = $codexDir;                                       Detected = $codexDetected;    Note = "checked ~/.agents, ~/.codex and `codex` on PATH" }
        [PSCustomObject]@{ Key = "gemini";   Display = "Gemini CLI";      Dir = (Join-Path $homeDir ".gemini/skills");          Detected = $geminiDetected;   Note = "checked ~/.gemini and `gemini` on PATH" }
        [PSCustomObject]@{ Key = "opencode"; Display = "OpenCode";        Dir = (Join-Path $homeDir ".config/opencode/skills"); Detected = $opencodeDetected; Note = "checked ~/.config/opencode and `opencode` on PATH" }
        [PSCustomObject]@{ Key = "local";    Display = "Local (shared)";  Dir = $sharedDir;                                      Detected = $localDetected;    Note = "shared ~/.agents/skills, read by Codex, Cursor and Gemini" }
    )
}

function Get-BundledSkills {
    if (-not (Test-Path $SkillsSourceDir)) { return @() }
    $found = @()
    foreach ($name in $SkillOrder) {
        if (Test-Path (Join-Path $SkillsSourceDir (Join-Path $name "SKILL.md"))) {
            $found += $name
        }
    }
    return $found
}

function Get-SkillSource {
    param([string]$SkillName)
    # Returns @{ Path = <folder>; Origin = "bundled"|"upstream"|"missing" }.
    $bundled = Join-Path $SkillsSourceDir $SkillName
    if (Test-Path (Join-Path $bundled "SKILL.md")) {
        return @{ Path = $bundled; Origin = "bundled" }
    }
    if ($SkillName -eq "i-have-adhd") {
        $tmpDir = Join-Path ([System.IO.Path]::GetTempPath()) "i-have-adhd-skill"
        try {
            New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
            $tmpFile = Join-Path $tmpDir "SKILL.md"
            if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
                curl.exe -fsSL -o $tmpFile $IHaveAdhdUpstreamUrl
            } else {
                Invoke-WebRequest -Uri $IHaveAdhdUpstreamUrl -OutFile $tmpFile -UseBasicParsing
            }
            if (Test-Path $tmpFile) {
                return @{ Path = $tmpDir; Origin = "upstream" }
            }
        } catch { }
    }
    return @{ Path = $null; Origin = "missing" }
}

function Install-SkillIntoDir {
    param([string]$SkillName, [string]$SourceDir, [string]$Origin, [string]$TargetDir, [string]$HarnessKey)
    $destDir = Join-Path $TargetDir $SkillName
    try {
        New-Item -ItemType Directory -Force -Path $destDir | Out-Null
        Copy-Item -Path (Join-Path $SourceDir "*") -Destination $destDir -Recurse -Force
        if (Test-Path (Join-Path $destDir "SKILL.md")) {
            $detail = Join-Path $destDir "SKILL.md"
            if ($Origin -eq "upstream") { $detail += " (upstream text, not Abel's adopted version)" }
            Add-SkillResult "PASS" ("skill {0} -> {1}" -f $SkillName, $HarnessKey) $detail
        } else {
            Add-SkillResult "FAIL" ("skill {0} -> {1}" -f $SkillName, $HarnessKey) "SKILL.md did not land at $destDir"
        }
    } catch {
        Add-SkillResult "FAIL" ("skill {0} -> {1}" -f $SkillName, $HarnessKey) $_.Exception.Message
    }
}

function Invoke-ExternalInstall {
    param($External, [bool]$Interactive)
    Write-Host ""
    Write-Host ("Optional install: " + $External.Display + " - " + $External.Description) -ForegroundColor Cyan
    Write-Host ("  Command: " + $External.Command)
    Write-Host ("  " + $External.Notes)
    if (-not (Get-Command node -ErrorAction SilentlyContinue) -and -not (Get-Command npx -ErrorAction SilentlyContinue)) {
        Add-SkillResult "SKIP" ("external install: " + $External.Key) "Node.js not found on PATH; install Node.js first, then run the command above"
        return
    }
    if ($Interactive) {
        $ans = Read-Host ("Run this command now? [y/N]")
        if ($ans -notmatch "^[yY]") {
            Write-Host "Skipped. Run it yourself any time:"
            Write-Host ("  " + $External.Command)
            Add-SkillResult "SKIP" ("external install: " + $External.Key) "declined at prompt; command printed above"
            return
        }
    }
    try {
        $parts = $External.Command -split "\s+"
        $exe = $parts[0]
        $args = $parts[1..($parts.Count - 1)]
        & $exe @args
        if ($LASTEXITCODE -eq 0) {
            Add-SkillResult "PASS" ("external install: " + $External.Key) ("ran: " + $External.Command)
        } else {
            Add-SkillResult "FAIL" ("external install: " + $External.Key) ("exit code " + $LASTEXITCODE + " for: " + $External.Command)
        }
    } catch {
        Add-SkillResult "FAIL" ("external install: " + $External.Key) $_.Exception.Message
    }
}

function Invoke-SkillsStep {
    param(
        [bool]$Interactive = $false,
        [switch]$SkillsAll,
        [switch]$SkillsSkip,
        [string]$SkillsCsv = "",
        [string]$SkillNamesCsv = "",
        [switch]$IncludeClaudeMem,
        [switch]$IncludeSecurityAudit
    )
    Write-Host ""
    Write-Host "=== Skills ===" -ForegroundColor Cyan
    if ($SkillsSkip) {
        Write-Host "Skills step skipped (-SkillsSkip)."
        return
    }

    # --- Tools in this pack (status only; install them from the main menu) -------
    $cg = Get-Command codegraph -ErrorAction SilentlyContinue
    $rtk = Get-Command rtk -ErrorAction SilentlyContinue
    Write-Host "Tools in this pack:"
    Write-Host ("  CodeGraph - " + $(if ($cg) { "installed (" + (& codegraph --version 2>$null) + ")" } else { "not installed (install from the main menu)" }))
    Write-Host ("  RTK       - " + $(if ($rtk) { "installed (" + (& rtk --version 2>$null) + ")" } else { "not installed (install from the main menu)" }))

    $bundled = @(Get-BundledSkills)
    if ($bundled.Count -eq 0) {
        Add-SkillResult "SKIP" "Skills" "no skill folders found in $SkillsSourceDir"
        return
    }

    # --- Detect harnesses ------------------------------------------------------
    $harnesses = @(Get-SkillsHarnesses)
    Write-Host "AI setups found on this machine:"
    foreach ($h in $harnesses) {
        $state = if ($h.Detected) { "DETECTED" } else { "not found" }
        Write-Host ("  {0,-12} {1} - {2} ({3})" -f $h.Display, $state, $h.Dir, $h.Note)
    }
    $detected = @($harnesses | Where-Object { $_.Detected })
    if ($detected.Count -eq 0) {
        Add-SkillResult "SKIP" "Skills" "no AI setup detected on this machine (checked Claude Code, Cursor, Copilot, Codex, Gemini CLI, OpenCode)"
        return
    }

    # --- Pick harnesses ---------------------------------------------------------
    $pickedHarnesses = @()
    if ($SkillsAll) {
        $pickedHarnesses = $detected
    } elseif ($SkillsCsv) {
        $wanted = @($SkillsCsv -split "," | ForEach-Object { $_.Trim().ToLower() } | Where-Object { $_ })
        foreach ($w in $wanted) {
            $match = $harnesses | Where-Object { $_.Key -eq $w }
            if ($match -and $match.Detected) { $pickedHarnesses += $match }
            elseif ($match) { Add-SkillResult "SKIP" ("skill install -> " + $w) "harness not detected on this machine" }
            else { Add-SkillResult "SKIP" ("skill install -> " + $w) "unknown harness name (use: claude, cursor, copilot, codex, gemini, opencode, local)" }
        }
    } elseif (-not $Interactive) {
        Write-Host "Skills step skipped in non-interactive mode. Re-run with -SkillsAll to install into every detected setup, or -Skills `"claude,cursor`" to pick."
        return
    } else {
        Write-Host ""
        Write-Host "Install skills into:"
        Write-Host "  [1] All detected setups (default)"
        Write-Host "  [2] Pick setups by number"
        Write-Host "  [3] Skip skills"
        $choice = Read-Host "Pick one [1-3, default 1]"
        switch ($choice) {
            "3" { Write-Host "Skills step skipped."; return }
            "2" {
                for ($i = 0; $i -lt $detected.Count; $i++) {
                    Write-Host ("  [" + ($i + 1) + "] " + $detected[$i].Display + " - " + $detected[$i].Dir)
                }
                $nums = Read-Host "Setup numbers, separated by spaces [default: all]"
                if (-not $nums) { $pickedHarnesses = $detected }
                else {
                    foreach ($n in ($nums -split "[\s,]+")) {
                        if ($n -match "^\d+$" -and [int]$n -ge 1 -and [int]$n -le $detected.Count) {
                            $pickedHarnesses += $detected[[int]$n - 1]
                        }
                    }
                }
            }
            default { $pickedHarnesses = $detected }
        }
    }
    if ($pickedHarnesses.Count -eq 0) {
        Write-Host "No setups picked. Skills step skipped."
        return
    }

    # --- One Skills menu: bundled skills + optional external installs -----------
    $pickedSkills = @()
    $pickedExternals = @()
    $extBase = $bundled.Count
    if ($SkillNamesCsv) {
        foreach ($s in ($SkillNamesCsv -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
            if ($bundled -contains $s) { $pickedSkills += $s }
            else { Add-SkillResult "SKIP" ("skill " + $s) "not in this pack" }
        }
        if ($IncludeClaudeMem) { $pickedExternals += $ExternalInstalls[0] }
        if ($IncludeSecurityAudit) { $pickedExternals += $ExternalInstalls[1] }
    } elseif (-not $Interactive -or $SkillsAll -or $SkillsCsv) {
        $pickedSkills = $bundled
        if ($IncludeClaudeMem) { $pickedExternals += $ExternalInstalls[0] }
        if ($IncludeSecurityAudit) { $pickedExternals += $ExternalInstalls[1] }
    } else {
        Write-Host ""
        Write-Host "Which skills? (i-have-adhd first; the rest are Abel's own skills.)"
        for ($i = 0; $i -lt $bundled.Count; $i++) {
            Write-Host ("  [" + ($i + 1) + "] " + $bundled[$i] + " - " + $SkillDescriptions[$bundled[$i]])
        }
        Write-Host "  [a] All bundled skills (default)"
        Write-Host "  [s] Skip skills"
        Write-Host "Optional external installs (never in All — pick by number only):"
        for ($j = 0; $j -lt $ExternalInstalls.Count; $j++) {
            Write-Host ("  [" + ($extBase + $j + 1) + "] " + $ExternalInstalls[$j].Display + " - " + $ExternalInstalls[$j].Description + " (external, needs Node.js)")
        }
        $nums = Read-Host "Skill numbers, separated by spaces, 'a' for all bundled, 's' to skip [default a]"
        if ((-not $nums) -or ($nums -match "^[aA]$")) {
            $pickedSkills = $bundled
        } elseif ($nums -match "^[sS]$") {
            Write-Host "Skills step skipped."
            return
        } else {
            foreach ($n in ($nums -split "[\s,]+")) {
                if ($n -match "^\d+$") {
                    $num = [int]$n
                    if ($num -ge 1 -and $num -le $bundled.Count) {
                        $pickedSkills += $bundled[$num - 1]
                    } elseif ($num -gt $bundled.Count -and $num -le ($bundled.Count + $ExternalInstalls.Count)) {
                        $pickedExternals += $ExternalInstalls[$num - $bundled.Count - 1]
                    }
                }
            }
        }
    }
    if ($pickedSkills.Count -eq 0 -and $pickedExternals.Count -eq 0) {
        Write-Host "No skills picked. Skills step skipped."
        return
    }

    # --- Install bundled skills (deduped by target folder: Codex and Local share one) ---
    $doneDirs = @{}
    foreach ($h in $pickedHarnesses) {
        if ($doneDirs.ContainsKey($h.Dir)) {
            foreach ($s in $pickedSkills) {
                Add-SkillResult "SKIP" ("skill {0} -> {1}" -f $s, $h.Key) ("same folder as " + $doneDirs[$h.Dir] + ", already installed")
            }
            continue
        }
        $doneDirs[$h.Dir] = $h.Key
        foreach ($s in $pickedSkills) {
            $src = Get-SkillSource -SkillName $s
            if ($src.Origin -eq "missing") {
                Add-SkillResult "SKIP" ("skill {0} -> {1}" -f $s, $h.Key) "no source file in this pack and no upstream fallback"
                continue
            }
            Install-SkillIntoDir -SkillName $s -SourceDir $src.Path -Origin $src.Origin -TargetDir $h.Dir -HarnessKey $h.Key
        }
    }

    # --- Optional external installs (opt-in only, each confirms first) --------------
    foreach ($ext in $pickedExternals) {
        Invoke-ExternalInstall -External $ext -Interactive $Interactive
    }
    Write-Host "Skills done. Restart the agent to pick up the new skill."
}
