#requires -Version 7
<#
.SYNOPSIS
  Capture a Serialized baseline from a clean source host into this repo.

.DESCRIPTION
  Authenticates to a running source DW host, runs the serializer in Deploy and/or
  Seed mode, then stages the host's SerializeRoot/{deploy,seed} trees and the
  active config under packages/<Product>/<Version>/.

  This is the capture step of the authoring loop. Stand the source host up and
  clean its database FIRST (see docs/host-setup.md); verify the captured package
  with tools/e2e/full-clean-roundtrip.ps1 AFTER (see docs/authoring-a-baseline.md).

.EXAMPLE
  pwsh tools/capture/new-baseline.ps1 -Product swift -Version 2.2 `
    -SourceHostUrl https://localhost:54035 `
    -SourceFilesRoot 'C:\Projects\Solutions\swift.test.forsync\Swift2.2\Dynamicweb.Host.Suite\wwwroot\Files' `
    -Mode all
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)] [string]$Product,
    [Parameter(Mandatory)] [string]$Version,
    [Parameter(Mandatory)] [string]$SourceHostUrl,
    # Path to the source host's Files folder (contains System\Serializer\SerializeRoot)
    [Parameter(Mandatory)] [string]$SourceFilesRoot,
    [ValidateSet('deploy','seed','all')] [string]$Mode = 'all',
    [string]$AdminUser = 'Administrator',
    [string]$AdminPassword = $env:DW_ADMIN_PASSWORD
)

$ErrorActionPreference = 'Stop'
$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..' '..')
$pkgDir   = Join-Path $repoRoot "packages\$Product\$Version"
$serRoot  = Join-Path $SourceFilesRoot 'System\Serializer\SerializeRoot'
$cfgSrc   = Join-Path $SourceFilesRoot 'System\Serializer\Serializer.config.json'

if (-not (Test-Path $serRoot)) { throw "SerializeRoot not found at $serRoot" }

function Get-DwToken {
    $body = @{ Username = $AdminUser; Password = $AdminPassword } | ConvertTo-Json
    $resp = Invoke-WebRequest -Uri "$SourceHostUrl/Admin/TokenAuthentication/authenticate" `
        -Method POST -ContentType 'application/json' -Body $body -SkipCertificateCheck
    $token = ($resp.Content | ConvertFrom-Json).Token
    if (-not $token) { throw "Token auth against $SourceHostUrl returned no Token" }
    return $token
}

function Invoke-Serialize([string]$m) {
    $token = Get-DwToken
    Write-Host "  serialize?mode=$m ..."
    $resp = Invoke-WebRequest -Uri "$SourceHostUrl/Admin/Api/SerializerSerialize?mode=$m" `
        -Method POST -Headers @{ Authorization = "Bearer $token" } `
        -SkipCertificateCheck -TimeoutSec 600
    if ([int]$resp.StatusCode -ne 200) { throw "serialize?mode=$m returned HTTP $($resp.StatusCode)" }
    if ($resp.Content -match 'escalated|CumulativeStrictModeException') {
        throw "serialize?mode=$m emitted strict-mode escalations:`n$($resp.Content)"
    }
}

function Stage([string]$m) {
    $from = Join-Path $serRoot $m
    $to   = Join-Path $pkgDir $m
    if (-not (Test-Path $from)) { throw "Expected serialize output at $from" }
    New-Item -ItemType Directory -Force -Path $to | Out-Null
    Get-ChildItem $to -Exclude 'README.md' | Remove-Item -Recurse -Force
    Copy-Item "$from\*" $to -Recurse -Force
    $n = (Get-ChildItem $to -Recurse -File).Count
    Write-Host "  staged $n files -> packages\$Product\$Version\$m"
}

$modes = if ($Mode -eq 'all') { @('deploy','seed') } else { @($Mode) }
foreach ($m in $modes) { Invoke-Serialize $m }
foreach ($m in $modes) { Stage $m }

# Stage the active config
New-Item -ItemType Directory -Force -Path (Join-Path $pkgDir 'config') | Out-Null
if (Test-Path $cfgSrc) {
    Copy-Item $cfgSrc (Join-Path $pkgDir "config\$Product-$Version.json") -Force
    Write-Host "  staged config -> config\$Product-$Version.json"
}

Write-Host ''
Write-Host "Captured $Product/$Version ($($modes -join ', '))." -ForegroundColor Green
Write-Host "Next: verify with tools/e2e/full-clean-roundtrip.ps1, then update BASELINE.md / CHANGELOG.md." -ForegroundColor Green
