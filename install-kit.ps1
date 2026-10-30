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

  With -Project <path> it copies them into that project's .claude\ instead, to be committed
  with it: a Claude Code cloud session only loads what is in the repo, never ~\.claude\.
  No web-agent-kit.json there: the project's .kit-version says which version its copy is.

  In both cases the kit's reference\ goes to <target>\kit-reference\: the skills cite it.

  At the end it writes ~\.claude\web-agent-kit.json with this clone's path and the installed
  version: the kit-update skill reads it to compare with the kit's published version.

  Afterwards: open a new Claude Code session. Skills and agents load at startup; a session
  already open keeps the old ones ("Agent type not found").

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\agents\web-agent-kit\install-kit.ps1"

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\agents\web-agent-kit\install-kit.ps1" -Pull

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File "...\web-agent-kit\install-kit.ps1" -Project C:\path\my-project
#>
[CmdletBinding()]
param([switch] $Pull, [string] $Project)

$ErrorActionPreference = 'Stop'
$kit = $PSScriptRoot
$target = Join-Path $HOME '.claude'
if ($Project) {
  if (-not (Test-Path (Join-Path $Project 'package.json'))) { throw "There is no package.json in $Project" }
  $target = Join-Path (Resolve-Path $Project).Path '.claude'
}

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

# The skills cite "the kit's reference/..."; without a copy next to them a project (or a
# worker in a pool slot) could not open it and guessed (melao: models picked by eye because
# TOKEN-ECONOMY.md was unreachable).
$ref = Join-Path $target 'kit-reference'
if (Test-Path $ref) { Remove-Item $ref -Recurse -Force }
Copy-Item (Join-Path $kit 'reference') $ref -Recurse
Write-Host "  + kit-reference (the kit's reference/)"

if ($Project) {
  Write-Host ''
  Write-Host "Done. Commit $target\skills, $target\agents and $target\kit-reference with the project." -ForegroundColor Green
  return
}

# For kit-update: where the clone is and which skills version got installed.
# WriteAllText: UTF-8 without BOM also on Windows PowerShell 5.1 (with a BOM, JSON.parse fails).
$json = [ordered]@{ path = $kit; version = $version; installed = (Get-Date -Format 'yyyy-MM-dd') } | ConvertTo-Json
[IO.File]::WriteAllText((Join-Path $target 'web-agent-kit.json'), $json + "`n")
Write-Host "  + web-agent-kit.json (path and version, for kit-update)"

Write-Host ''
Write-Host 'Done. Open a new Claude Code session and check with /skills and /agents.' -ForegroundColor Green
