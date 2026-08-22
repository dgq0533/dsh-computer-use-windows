[CmdletBinding()]
param(
  [string]$ProfileRoot = (Join-Path $HOME '.dsh\profiles\web'),
  [string]$DshRoot,
  [switch]$SkipRestartNotice
)

$ErrorActionPreference = 'Stop'
$PluginRoot = (Resolve-Path (Split-Path -Parent $PSScriptRoot)).Path
$ProfileRoot = (Resolve-Path $ProfileRoot).Path

if (-not $DshRoot) {
  $DshRoot = Join-Path ((& npm root -g).Trim()) '@deepseek-ai\dsh'
}
$DshRoot = (Resolve-Path $DshRoot).Path
$HostTools = Join-Path $DshRoot 'node_modules\@deepseek-ai\dsh-tools'
$Schema = Join-Path $ProfileRoot 'node_modules\@deepseek-ai\schemastery'
foreach ($required in @($HostTools, $Schema)) {
  if (-not (Test-Path -LiteralPath $required)) {
    throw "Required dependency was not found: $required"
  }
}

function Set-Junction([string]$Path, [string]$Target) {
  New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Path) | Out-Null
  if (Test-Path -LiteralPath $Path) { Remove-Item -LiteralPath $Path -Force }
  New-Item -ItemType Junction -Path $Path -Target $Target | Out-Null
}

Set-Junction (Join-Path $ProfileRoot 'node_modules\dsh-computer-use') $PluginRoot
Set-Junction (Join-Path $PluginRoot 'node_modules\@deepseek-ai\dsh-tools') $HostTools
Set-Junction (Join-Path $PluginRoot 'node_modules\@deepseek-ai\schemastery') $Schema

$PackagePath = Join-Path $ProfileRoot 'package.json'
$Profile = Get-Content -Raw $PackagePath | ConvertFrom-Json
if (-not $Profile.dependencies) { $Profile | Add-Member -NotePropertyName dependencies -NotePropertyValue ([pscustomobject]@{}) }
$LinkValue = 'link:' + ($PluginRoot -replace '\', '/')
$Profile.dependencies | Add-Member -Force -NotePropertyName 'dsh-computer-use' -NotePropertyValue $LinkValue
if (-not $Profile.dsh) { $Profile | Add-Member -NotePropertyName dsh -NotePropertyValue ([pscustomobject]@{}) }
if (-not $Profile.dsh.profile) { $Profile.dsh | Add-Member -NotePropertyName profile -NotePropertyValue ([pscustomobject]@{}) }
$Bundles = @($Profile.dsh.profile.bundles)
if ($Bundles -notcontains 'dsh-computer-use') { $Profile.dsh.profile | Add-Member -Force -NotePropertyName bundles -NotePropertyValue @($Bundles + 'dsh-computer-use') }
$Profile | ConvertTo-Json -Depth 16 | Set-Content -Encoding utf8 $PackagePath

$env:DSH_PROFILE_ROOT = $ProfileRoot
& node (Join-Path $PluginRoot 'tools\verify-host-modules.mjs')
if ($LASTEXITCODE -ne 0) { throw 'DSH host module verification failed.' }
Write-Host 'Installed dsh-computer-use into the Windows Web profile.' -ForegroundColor Green
if (-not $SkipRestartNotice) { Write-Host 'Restart the existing dsh web host to load the plugin.' -ForegroundColor Yellow }
