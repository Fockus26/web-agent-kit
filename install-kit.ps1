<#
.SYNOPSIS
  Installs (or reinstalls) the kit's skills and agents in ~\.claude\, where Claude Code loads
  them in any project.

.DESCRIPTION
  Copies each folder of .claude\skills\ and each file of .claude\agents\ from the kit over
  the installed one. Before copying a skill it deletes its installed folder: that way a file
  the kit no longer ships does not linger. It does not touch skills or agents that are not
  the kit's.

  With -Pull it runs `git pull` in the kit first.

  At the end it writes ~\.claude\web-agent-kit.json with this clone's path and the installed
  version: the kit-update skill reads it to compare with the kit's published version.

  Afterwards: open a new Claude Code session. Skills and agents load at startup; a session
  already open keeps the old ones ("Agent type not found").

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\agents\web-agent-kit\install-kit.ps1"

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\agents\web-agent-kit\install-kit.ps1" -Pull
#>
[CmdletBinding()]
param([switch] $Pull)

$ErrorActionPreference = 'Stop'
$kit = $PSScriptRoot
$target = Join-Path $env:USERPROFILE '.claude'

if ($Pull) {
  Write-Host "... git pull in $kit"
  git -C $kit pull --ff-only
  if ($LASTEXITCODE -ne 0) { throw 'git pull failed: fix it in the kit and run the script again.' }
}

$version = (Get-Content (Join-Path $kit 'VERSION') -Raw).Trim()
Write-Host "Kit $version -> $target"

New-Item -ItemType Directory -Force (Join-Path $target 'skills'), (Join-Path $target 'agents') | Out-Null

foreach ($skill in Get-ChildItem (Join-Path $kit '.claude\skills') -Directory) {
  $path = Join-Path $target "skills\$($skill.Name)"
  if (Test-Path $path) { Remove-Item $path -Recurse -Force }
  Copy-Item $skill.FullName $path -Recurse
  Write-Host "  + skill  $($skill.Name)"
}

foreach ($agent in Get-ChildItem (Join-Path $kit '.claude\agents') -Filter '*.md' -File) {
  Copy-Item $agent.FullName (Join-Path $target "agents\$($agent.Name)") -Force
  Write-Host "  + agent  $($agent.BaseName)"
}

# For kit-update: where the clone is and which skills version got installed.
# WriteAllText: UTF-8 without BOM also on Windows PowerShell 5.1 (with a BOM, JSON.parse fails).
$json = [ordered]@{ path = $kit; version = $version; installed = (Get-Date -Format 'yyyy-MM-dd') } | ConvertTo-Json
[IO.File]::WriteAllText((Join-Path $target 'web-agent-kit.json'), $json + "`n")
Write-Host "  + web-agent-kit.json (path and version, for kit-update)"

Write-Host ''
Write-Host 'Done. Open a new Claude Code session and check with /skills and /agents.' -ForegroundColor Green
