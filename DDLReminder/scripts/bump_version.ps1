param(
  [ValidateSet('build', 'patch', 'minor', 'major')]
  [string]$Part = 'build',
  [string]$SetVersion = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$pubspecPath = Join-Path $projectRoot 'pubspec.yaml'

function Write-Log {
  param([string]$Message)
  Write-Host "[version] $Message"
}

function Get-VersionLine {
  param([string]$Path)
  $line = Get-Content -Path $Path | Where-Object { $_ -match '^version:\s*' } | Select-Object -First 1
  if (-not $line) {
    throw 'Missing version in pubspec.yaml'
  }
  return $line
}

function Parse-Version {
  param([string]$Value)
  if ($Value -notmatch '^(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)\+(?<build>\d+)$') {
    throw "Invalid version format: $Value. Expected major.minor.patch+build"
  }

  return @{
    Major = [int]$matches['major']
    Minor = [int]$matches['minor']
    Patch = [int]$matches['patch']
    Build = [int]$matches['build']
  }
}

function Format-Version {
  param([hashtable]$Parts)
  return "$($Parts.Major).$($Parts.Minor).$($Parts.Patch)+$($Parts.Build)"
}

function Get-NextVersion {
  param(
    [hashtable]$Parts,
    [string]$PartName
  )

  $next = @{
    Major = $Parts.Major
    Minor = $Parts.Minor
    Patch = $Parts.Patch
    Build = $Parts.Build
  }

  switch ($PartName) {
    'build' {
      $next.Build += 1
    }
    'patch' {
      $next.Patch += 1
      $next.Build = 1
    }
    'minor' {
      $next.Minor += 1
      $next.Patch = 0
      $next.Build = 1
    }
    'major' {
      $next.Major += 1
      $next.Minor = 0
      $next.Patch = 0
      $next.Build = 1
    }
    default {
      throw "Unsupported version part: $PartName"
    }
  }

  return $next
}

$versionLine = Get-VersionLine -Path $pubspecPath
$currentVersion = ($versionLine -replace '^version:\s*', '').Trim()
[void](Parse-Version -Value $currentVersion)

if (-not [string]::IsNullOrWhiteSpace($SetVersion)) {
  [void](Parse-Version -Value $SetVersion)
  $nextVersion = $SetVersion.Trim()
} else {
  $parts = Parse-Version -Value $currentVersion
  $nextVersion = Format-Version -Parts (Get-NextVersion -Parts $parts -PartName $Part)
}

$content = Get-Content -Path $pubspecPath
$updated = $content | ForEach-Object {
  if ($_ -match '^version:\s*') {
    "version: $nextVersion"
  } else {
    $_
  }
}
Set-Content -Path $pubspecPath -Value $updated

Write-Log "Old version: $currentVersion"
Write-Log "New version: $nextVersion"
Write-Log "Suggested tag: v$nextVersion"
