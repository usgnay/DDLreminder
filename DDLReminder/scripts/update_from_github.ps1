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

$tempRoot = Join-Path $env:TEMP 'DDLReminder-updater'
$downloadDir = Join-Path $tempRoot 'download'
$extractDir = Join-Path $tempRoot 'extract'
$stagingDir = Join-Path $tempRoot 'staging'
$backupDir = Join-Path $tempRoot 'backup'
$logPath = Join-Path $tempRoot 'update.log'
$zipPath = Join-Path $downloadDir $AssetName
$backupTarget = $null

New-Item -ItemType Directory -Force -Path $tempRoot | Out-Null

function Write-Log {
  param([string]$Message)
  $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
  $line = "[$timestamp] [updater] $Message"
  Write-Host $line
  Add-Content -Path $logPath -Value $line
}

function Get-NormalizedVersion {
  param([string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) { return '' }
  if ($Value.StartsWith('v') -or $Value.StartsWith('V')) {
    return $Value.Substring(1)
  }
  return $Value
}

function Get-RedirectLocation {
  param([string]$Uri)

  $request = [System.Net.HttpWebRequest]::Create($Uri)
  $request.Method = 'GET'
  $request.AllowAutoRedirect = $false
  $request.UserAgent = 'DDLreminder-Updater'

  try {
    $response = [System.Net.HttpWebResponse]$request.GetResponse()
    $location = $response.Headers['Location']
    $statusCode = [int]$response.StatusCode
    $response.Close()
    return @{
      StatusCode = $statusCode
      Location = $location
    }
  } catch [System.Net.WebException] {
    if ($_.Exception.Response -is [System.Net.HttpWebResponse]) {
      $response = [System.Net.HttpWebResponse]$_.Exception.Response
      $location = $response.Headers['Location']
      $statusCode = [int]$response.StatusCode
      $response.Close()
      return @{
        StatusCode = $statusCode
        Location = $location
      }
    }
    throw
  }
}

function Test-RedirectStatus {
  param([int]$StatusCode)
  return $StatusCode -in 301, 302, 303, 307, 308
}

function Reset-Directory {
  param([string]$Path)
  Remove-Item -Recurse -Force -LiteralPath $Path -ErrorAction SilentlyContinue
  New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Get-StagingRoot {
  param(
    [string]$ExpandedPath,
    [string]$ExecutableName
  )

  $topLevel = Get-ChildItem -LiteralPath $ExpandedPath -Force
  if ($topLevel.Count -eq 1 -and $topLevel[0].PSIsContainer) {
    $nestedExe = Join-Path $topLevel[0].FullName $ExecutableName
    if (Test-Path -LiteralPath $nestedExe) {
      return $topLevel[0].FullName
    }
  }

  return $ExpandedPath
}

function Test-PackageLayout {
  param(
    [string]$PackageRoot,
    [string]$ExecutableName
  )

  $exePath = Join-Path $PackageRoot $ExecutableName
  $dataDir = Join-Path $PackageRoot 'data'
  $flutterAssetsDir = Join-Path $dataDir 'flutter_assets'
  $scriptPath = Join-Path $PackageRoot 'scripts\update_from_github.ps1'

  if (-not (Test-Path -LiteralPath $exePath)) {
    throw "Updated executable not found in package: $exePath"
  }
  if (-not (Test-Path -LiteralPath $dataDir)) {
    throw "Updated package missing data directory: $dataDir"
  }
  if (-not (Test-Path -LiteralPath $flutterAssetsDir)) {
    throw "Updated package missing Flutter assets: $flutterAssetsDir"
  }
  if (-not (Test-Path -LiteralPath $scriptPath)) {
    throw "Updated package missing updater script: $scriptPath"
  }
}

function Restore-Backup {
  param(
    [string]$SourceDir,
    [string]$TargetDir
  )

  if (-not $SourceDir -or -not (Test-Path -LiteralPath $SourceDir)) {
    return
  }

  Write-Log 'Attempting rollback from backup'

  Get-ChildItem -LiteralPath $TargetDir -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne 'scripts' } |
    ForEach-Object {
      Remove-Item -LiteralPath $_.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }

  Get-ChildItem -LiteralPath $SourceDir -Force | ForEach-Object {
    Move-Item -LiteralPath $_.FullName -Destination $TargetDir -Force
  }

  Write-Log 'Rollback completed'
}

try {
  Reset-Directory -Path $downloadDir
  Reset-Directory -Path $extractDir
  Reset-Directory -Path $stagingDir
  Reset-Directory -Path $backupDir
  Set-Content -Path $logPath -Value ''

  Write-Log "Updater started for $RepoOwner/$RepoName"

  $latestReleaseUrl = "https://github.com/$RepoOwner/$RepoName/releases/latest"
  $latestReleaseResponse = Get-RedirectLocation -Uri $latestReleaseUrl
  if (-not (Test-RedirectStatus -StatusCode $latestReleaseResponse.StatusCode)) {
    throw "Latest release endpoint returned $($latestReleaseResponse.StatusCode)"
  }
  if ([string]::IsNullOrWhiteSpace($latestReleaseResponse.Location)) {
    throw 'Latest release endpoint did not provide a redirect location'
  }

  $latestReleaseUri = [System.Uri]::new([System.Uri]$latestReleaseUrl, $latestReleaseResponse.Location)
  $latestTag = [System.IO.Path]::GetFileName($latestReleaseUri.AbsolutePath)
  $latestVersion = Get-NormalizedVersion $latestTag

  if ($CurrentVersion -and (Get-NormalizedVersion $CurrentVersion) -eq $latestVersion) {
    Write-Log "Already at latest version $latestVersion"
    exit 0
  }

  $assetUrl = "https://github.com/$RepoOwner/$RepoName/releases/latest/download/$AssetName"
  $assetResponse = Get-RedirectLocation -Uri $assetUrl
  if (($assetResponse.StatusCode -lt 200 -or $assetResponse.StatusCode -ge 400) -and -not (Test-RedirectStatus -StatusCode $assetResponse.StatusCode)) {
    throw "Release asset not found or unavailable: $AssetName ($($assetResponse.StatusCode))"
  }

  Write-Log "Downloading $AssetName"
  Invoke-WebRequest -Uri $assetUrl -OutFile $zipPath

  Write-Log 'Extracting package'
  Expand-Archive -LiteralPath $zipPath -DestinationPath $extractDir -Force

  $packageRoot = Get-StagingRoot -ExpandedPath $extractDir -ExecutableName $ExeName
  Write-Log "Resolved package root: $packageRoot"
  Test-PackageLayout -PackageRoot $packageRoot -ExecutableName $ExeName

  Write-Log 'Copying package into staging area'
  Copy-Item -LiteralPath (Join-Path $packageRoot '*') -Destination $stagingDir -Recurse -Force
  Test-PackageLayout -PackageRoot $stagingDir -ExecutableName $ExeName

  $processName = [System.IO.Path]::GetFileNameWithoutExtension($ExeName)
  Write-Log "Stopping running process: $processName"
  Get-Process -Name $processName -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
  Start-Sleep -Seconds 2

  $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
  $backupTarget = Join-Path $backupDir "app-$timestamp"
  New-Item -ItemType Directory -Force -Path $backupTarget | Out-Null

  Write-Log 'Backing up current files'
  Get-ChildItem -LiteralPath $AppDir -Force |
    Where-Object { $_.Name -ne 'scripts' } |
    ForEach-Object {
      Move-Item -LiteralPath $_.FullName -Destination $backupTarget -Force
    }

  Write-Log 'Installing new files from staging'
  Get-ChildItem -LiteralPath $stagingDir -Force | ForEach-Object {
    Copy-Item -LiteralPath $_.FullName -Destination $AppDir -Recurse -Force
  }

  $newExe = Join-Path $AppDir $ExeName
  if (-not (Test-Path -LiteralPath $newExe)) {
    throw "Updated executable not found after install: $newExe"
  }

  Write-Log 'Restarting application'
  Start-Process -FilePath $newExe -WorkingDirectory $AppDir | Out-Null
  Write-Log 'Update completed successfully'
  exit 0
} catch {
  Write-Log "Update failed: $($_.Exception.Message)"
  Restore-Backup -SourceDir $backupTarget -TargetDir $AppDir
  throw
}
