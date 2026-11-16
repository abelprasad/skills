# install.ps1 — copy-install the vendored skills from this repo into every
# detected agent harness (Windows).
#
#   .\scripts\install.ps1 -All
#   .\scripts\install.ps1 -Skills local-ponytail,summary
#   .\scripts\install.ps1 -List
#
# No flags: lists skills + harnesses, then asks once.
# A harness is detected when its skills folder exists; nothing is ever
# created for a harness that isn't there. Install = copy the whole skill
# folder into <harness-skills>\<skill-name>\, replacing any older copy.
param(
  [switch]$All,
  [switch]$List,
  [string]$Skills = ""
)

$RepoRoot = Split-Path $PSScriptRoot -Parent

function Get-RepoSkills {
  $names = @()
  foreach ($dir in @("$RepoRoot\skills\made", "$RepoRoot\skills\liked")) {
    if (Test-Path $dir) {
      Get-ChildItem $dir -Directory | Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } | ForEach-Object { $names += $_.Name }
    }
  }
  return ($names | Sort-Object -Unique)
}

function Get-SkillSource($Name) {
  $made = Join-Path $RepoRoot "skills\made\$Name"
  if (Test-Path $made) { return $made }
  $liked = Join-Path $RepoRoot "skills\liked\$Name"
  if (Test-Path $liked) { return $liked }
  return $null
}

$Harnesses = @(
  "$env:USERPROFILE\.claude\skills",
  "$env:USERPROFILE\.cursor\skills",
  "$env:USERPROFILE\.copilot\skills",
  "$env:USERPROFILE\.agents\skills",
  "$env:USERPROFILE\.gemini\skills",
  "$env:USERPROFILE\.config\opencode\skills"
)

function Show-List {
  Write-Host "Skills in this repo:"
  Get-RepoSkills | ForEach-Object { Write-Host "  $_" }
  Write-Host "Detected harnesses:"
  foreach ($h in $Harnesses) { if (Test-Path $h) { Write-Host "  $h" } }
}

function Install-Skills($Wanted) {
  $n = 0
  foreach ($h in $Harnesses) {
    if (-not (Test-Path $h)) { continue }
    foreach ($s in (Get-RepoSkills)) {
      if ($Wanted -and ($Wanted -notcontains $s)) { continue }
      $src = Get-SkillSource $s
      if (-not $src) { continue }
      $dst = Join-Path $h $s
      if (Test-Path $dst) { Remove-Item $dst -Recurse -Force }
      Copy-Item $src -Destination $dst -Recurse
      Write-Host "[PASS] $s -> $h"
      $n++
    }
  }
  if ($n -eq 0) { Write-Host "[SKIP] no detected harnesses, nothing installed" }
  Write-Host "Installed $n skill folder(s)."
}

if ($List) { Show-List; exit 0 }
if ($All) { Install-Skills $null; exit 0 }
if ($Skills) { Install-Skills ($Skills -split "," | ForEach-Object { $_.Trim() }); exit 0 }

Show-List
$ans = Read-Host "Install all skills into all detected harnesses? [y/N]"
if ($ans -match '^(y|Y|yes|YES)$') { Install-Skills $null } else { Write-Host "Nothing installed." }
