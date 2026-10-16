# Old name of install-kit.ps1 (kit < 3.8.0). Kept because the kit-update skill installed
# from those versions calls it by this name. Forwards to install-kit.ps1.
[CmdletBinding()]
param([switch] $Pull)
& (Join-Path $PSScriptRoot 'install-kit.ps1') -Pull:$Pull
