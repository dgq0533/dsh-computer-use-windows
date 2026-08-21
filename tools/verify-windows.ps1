param(
  [string]$ProfileRoot = "$HOME\.dsh\profiles\web",
  [string]$PluginRoot = (Split-Path -Parent $PSScriptRoot)
)
$ErrorActionPreference = 'Stop'
$env:DSH_PROFILE_ROOT = $ProfileRoot
node (Join-Path $PluginRoot 'tools\verify-host-modules.mjs')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
& cua-driver status --json
if ($LASTEXITCODE -ne 0) {
  throw 'cua-driver daemon is not running; start it with cua-driver serve'
}
& cua-driver call health_report '{}'
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
