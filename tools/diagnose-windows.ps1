[CmdletBinding()]
param(
  [string]$ProfileRoot = (Join-Path $HOME '.dsh\profiles\web'),
  [string]$PluginRoot = (Split-Path -Parent $PSScriptRoot),
  [switch]$RequireDriver
)
$ErrorActionPreference = 'Stop'
$checks = [ordered]@{}
$checks.profileRoot = (Test-Path -LiteralPath $ProfileRoot)
$checks.pluginRoot = (Test-Path -LiteralPath $PluginRoot)
$checks.driverCommand = [bool](Get-Command cua-driver -ErrorAction SilentlyContinue)
$checks.hostModules = $false
$checks.driverRunning = $false
$checks.health = $null

if ($checks.profileRoot -and $checks.pluginRoot) {
  $env:DSH_PROFILE_ROOT = $ProfileRoot
  $verify = & node (Join-Path $PluginRoot 'tools\verify-host-modules.mjs') 2>&1
  $checks.hostModules = ($LASTEXITCODE -eq 0)
  if (-not $checks.hostModules) { $checks.hostModulesError = ($verify -join "`n") }
}
if ($checks.driverCommand) {
  $statusText = & cua-driver status --json 2>&1
  $checks.driverRunning = ($LASTEXITCODE -eq 0)
  if ($checks.driverRunning) {
    try { $checks.driver = ($statusText -join "`n") | ConvertFrom-Json } catch { $checks.driver = ($statusText -join "`n") }
  } else { $checks.driverError = ($statusText -join "`n") }
  $healthText = & cua-driver call health_report '{}' 2>&1
  if ($LASTEXITCODE -eq 0) { try { $checks.health = ($healthText -join "`n") | ConvertFrom-Json } catch { $checks.health = ($healthText -join "`n") } }
}
$ok = $checks.profileRoot -and $checks.pluginRoot -and $checks.hostModules -and $checks.driverCommand -and $checks.driverRunning
$result = [ordered]@{ ok = $ok; checks = $checks; next = if (-not $checks.driverRunning) { 'Start cua-driver with: cua-driver serve --socket \\.\pipe\cua-driver' } elseif (-not $checks.hostModules) { 'Fix the profile dependency so plugin and host resolve the same dsh-tools package.' } else { 'Windows computer-use prerequisites are ready.' } }
$result | ConvertTo-Json -Depth 8
if ($RequireDriver -and -not $ok) { exit 1 }
