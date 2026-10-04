[CmdletBinding()]
param([Parameter(Mandatory)][string]$TargetPath)
$ErrorActionPreference = 'Stop'
$source = Split-Path -Parent $PSScriptRoot
$target = (Resolve-Path -LiteralPath $TargetPath).Path
function Copy-Safe([string]$relative) {
  $from = Join-Path $source $relative; $to = Join-Path $target $relative
  $parent = Split-Path -Parent $to; New-Item -ItemType Directory -Force -Path $parent | Out-Null
  if (Test-Path -LiteralPath $to) { Copy-Item -LiteralPath $from -Destination ($to + '.new') -Force; Write-Host "kept existing: $relative (wrote $relative.new)" }
  else { Copy-Item -LiteralPath $from -Destination $to -Force; Write-Host "installed: $relative" }
}
@('.orca\front-desk.md','.orca\coordinator.md','scripts\Orca-Harness.ps1','templates\AGENTS.md') | ForEach-Object { Copy-Safe $_ }
if (-not (Test-Path (Join-Path $target 'AGENTS.md'))) { Copy-Item (Join-Path $source 'templates\AGENTS.md') (Join-Path $target 'AGENTS.md') }
Write-Host "Orca harness installed. Review AGENTS.md and .orca-handoff before starting a task."

