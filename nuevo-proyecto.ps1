# Old name of new-project.ps1 (kit < 3.8.0), with its old parameter names. Forwards to
# new-project.ps1 (-Ruta -> -Path, -Existente -> -Existing, -SinVersion -> -NoVersion).
param(
  [Parameter(Mandatory)] [string] $Ruta,
  [switch] $Existente,
  [switch] $SinVersion
)
& (Join-Path $PSScriptRoot 'new-project.ps1') -Path $Ruta -Existing:$Existente -NoVersion:$SinVersion
