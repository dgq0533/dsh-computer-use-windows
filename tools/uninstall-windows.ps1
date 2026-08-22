[CmdletBinding()]
param([string]$ProfileRoot = (Join-Path $HOME '.dsh\profiles\web'))

$ErrorActionPreference = 'Stop'
$ProfileRoot = (Resolve-Path $ProfileRoot).Path
$PackagePath = Join-Path $ProfileRoot 'package.json'
$Profile = Get-Content -Raw $PackagePath | ConvertFrom-Json
if ($Profile.dependencies) { $Profile.dependencies.PSObject.Properties.Remove('dsh-computer-use') }
if ($Profile.dsh -and $Profile.dsh.profile -and $Profile.dsh.profile.bundles) {
  $Profile.dsh.profile.bundles = @($Profile.dsh.profile.bundles | Where-Object { $_ -ne 'dsh-computer-use' })
}
$Profile | ConvertTo-Json -Depth 16 | Set-Content -Encoding utf8 $PackagePath
$Link = Join-Path $ProfileRoot 'node_modules\dsh-computer-use'
if (Test-Path -LiteralPath $Link) { Remove-Item -LiteralPath $Link -Force }
Write-Host 'Removed dsh-computer-use from the Windows Web profile. Restart dsh web.' -ForegroundColor Green
