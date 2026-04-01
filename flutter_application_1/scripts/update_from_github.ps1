param(
  [Parameter(Mandatory = $true)]
  [string]$RepoOwner,
  [Parameter(Mandatory = $true)]
  [string]$RepoName,
  [Parameter(Mandatory = $true)]
  [string]$AssetName,
  [Parameter(Mandatory = $true)]
  [string]$AppDir,
  [Parameter(Mandatory = $true)]
  [string]$ExeName,
  [string]$CurrentVersion = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Write-Log {
  param([string]$Message)
  Write-Host "[updater] $Message"
}

function Get-NormalizedVersion {
  param([string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) { return '' }
  if ($Value.StartsWith('v') -or $Value.StartsWith('V')) {
    return $Value.Substring(1)
  }
  return $Value
}

$latestApi = "https://api.github.com/repos/$RepoOwner/$RepoName/releases/latest"
$release = Invoke-RestMethod -Uri $latestApi -Headers @{ 'Accept' = 'application/vnd.github+json' }
$latestVersion = Get-NormalizedVersion $release.tag_name

if ($CurrentVersion -and (Get-NormalizedVersion $CurrentVersion) -eq $latestVersion) {
  Write-Log "Already at latest version $latestVersion"
  exit 0
}

$asset = $release.assets | Where-Object { $_.name -eq $AssetName } | Select-Object -First 1
if (-not $asset) {
  throw "Release asset not found: $AssetName"
}

$tempRoot = Join-Path $env:TEMP "DDLreminder-updater"
$downloadDir = Join-Path $tempRoot "download"
$extractDir = Join-Path $tempRoot "extract"
$backupDir = Join-Path $tempRoot "backup"
$zipPath = Join-Path $downloadDir $AssetName

New-Item -ItemType Directory -Force -Path $downloadDir | Out-Null
Remove-Item -Recurse -Force $extractDir -ErrorAction SilentlyContinue
Remove-Item -Recurse -Force $backupDir -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $extractDir | Out-Null
New-Item -ItemType Directory -Force -Path $backupDir | Out-Null

Write-Log "Downloading $AssetName"
Invoke-WebRequest -Uri $asset.browser_download_url -OutFile $zipPath

Write-Log "Extracting package"
Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force

$processName = [System.IO.Path]::GetFileNameWithoutExtension($ExeName)
Get-Process -Name $processName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupTarget = Join-Path $backupDir "app-$timestamp"
New-Item -ItemType Directory -Force -Path $backupTarget | Out-Null

Write-Log "Backing up current files"
Get-ChildItem -LiteralPath $AppDir -Force |
  Where-Object { $_.Name -ne 'scripts' } |
  ForEach-Object {
    Move-Item -LiteralPath $_.FullName -Destination $backupTarget -Force
  }

Write-Log "Installing new files"
Get-ChildItem -LiteralPath $extractDir -Force | ForEach-Object {
  Copy-Item -LiteralPath $_.FullName -Destination $AppDir -Recurse -Force
}

$newExe = Join-Path $AppDir $ExeName
if (-not (Test-Path -LiteralPath $newExe)) {
  throw "Updated executable not found: $newExe"
}

Write-Log "Restarting application"
Start-Process -FilePath $newExe -WorkingDirectory $AppDir | Out-Null
exit 0
