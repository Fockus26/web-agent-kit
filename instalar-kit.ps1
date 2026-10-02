<#
.SYNOPSIS
  Instala (o reinstala) las skills y los agentes del kit en ~\.claude\, donde Claude Code los
  carga en cualquier proyecto.

.DESCRIPTION
  Copia cada carpeta de .claude\skills\ y cada archivo de .claude\agents\ del kit encima de la
  instalada. Antes de copiar una skill borra su carpeta instalada: así un archivo que el kit
  ya no trae no se queda colgado. No toca skills ni agentes que no sean del kit.

  Con -Pull hace antes `git pull` en el kit.

  Después: abre una sesión nueva de Claude Code. Las skills y los agentes se cargan al
  arrancar; una sesión ya abierta sigue con los de antes ("Agent type not found").

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\agents\web-agent-kit\instalar-kit.ps1"

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File "$env:USERPROFILE\Desktop\agents\web-agent-kit\instalar-kit.ps1" -Pull
#>
[CmdletBinding()]
param([switch] $Pull)

$ErrorActionPreference = 'Stop'
$kit = $PSScriptRoot
$destino = Join-Path $env:USERPROFILE '.claude'

if ($Pull) {
  Write-Host "… git pull en $kit"
  git -C $kit pull --ff-only
  if ($LASTEXITCODE -ne 0) { throw 'git pull falló: resuélvelo en el kit y vuelve a correr el script.' }
}

$version = (Get-Content (Join-Path $kit 'VERSION') -Raw).Trim()
Write-Host "Kit $version → $destino"

New-Item -ItemType Directory -Force (Join-Path $destino 'skills'), (Join-Path $destino 'agents') | Out-Null

foreach ($skill in Get-ChildItem (Join-Path $kit '.claude\skills') -Directory) {
  $ruta = Join-Path $destino "skills\$($skill.Name)"
  if (Test-Path $ruta) { Remove-Item $ruta -Recurse -Force }
  Copy-Item $skill.FullName $ruta -Recurse
  Write-Host "  + skill  $($skill.Name)"
}

foreach ($agente in Get-ChildItem (Join-Path $kit '.claude\agents') -Filter '*.md' -File) {
  Copy-Item $agente.FullName (Join-Path $destino "agents\$($agente.Name)") -Force
  Write-Host "  + agente $($agente.BaseName)"
}

Write-Host ''
Write-Host 'Listo. Abre una sesión nueva de Claude Code y comprueba con /skills y /agents.' -ForegroundColor Green
