Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$flutter = 'E:\flutter\bin\flutter.bat'
$releaseDir = Join-Path $projectRoot 'build\windows\x64\runner\Release'
$distDir = Join-Path $projectRoot 'dist'
$releaseZip = Join-Path $distDir 'DDLReminder-windows-release.zip'
$updaterScriptSource = Join-Path $projectRoot 'scripts\update_from_github.ps1'
$updaterScriptTargetDir = Join-Path $releaseDir 'scripts'

Write-Host '[build] flutter build windows --release'
& $flutter build windows --release

New-Item -ItemType Directory -Force -Path $updaterScriptTargetDir | Out-Null
Copy-Item -LiteralPath $updaterScriptSource -Destination (Join-Path $updaterScriptTargetDir 'update_from_github.ps1') -Force

New-Item -ItemType Directory -Force -Path $distDir | Out-Null
Remove-Item -LiteralPath $releaseZip -Force -ErrorAction SilentlyContinue

Write-Host '[build] creating release zip'
Compress-Archive -Path (Join-Path $releaseDir '*') -DestinationPath $releaseZip -CompressionLevel Optimal

$versionLine = Get-Content -Path (Join-Path $projectRoot 'pubspec.yaml') | Where-Object { $_ -match '^version:' } | Select-Object -First 1
Write-Host "[build] done $versionLine"
Write-Host "[build] zip => $releaseZip"
