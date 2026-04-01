param(
  [switch]$SkipBuild,
  [switch]$AllowDirty,
  [string]$ReleaseNotes = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$distZip = Join-Path $projectRoot 'dist\DDLreminder-windows-release.zip'
$buildScript = Join-Path $projectRoot 'scripts\build_release.ps1'
$pubspecPath = Join-Path $projectRoot 'pubspec.yaml'
$repoRoot = Split-Path -Parent $projectRoot
$git = 'git'
$repoOwner = 'usgnay'
$repoName = 'DDLreminder'

function Write-Log {
  param([string]$Message)
  Write-Host "[publish] $Message"
}

function Get-VersionFromPubspec {
  param([string]$Path)
  $line = Get-Content -Path $Path | Where-Object { $_ -match '^version:' } | Select-Object -First 1
  if (-not $line) {
    throw 'Missing version in pubspec.yaml'
  }
  return ($line -replace '^version:\s*', '').Trim()
}

function Get-RemoteUrl {
  param([string]$Root)
  $remote = & $git -C $Root remote get-url origin
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($remote)) {
    throw 'Git remote origin not found.'
  }
  return $remote.Trim()
}

function Ensure-CleanWorktree {
  param([string]$Root, [bool]$AllowDirtyWorktree)
  if ($AllowDirtyWorktree) {
    return
  }
  $status = & $git -C $Root status --porcelain
  if ($LASTEXITCODE -ne 0) {
    throw 'Failed to read git status.'
  }
  if (-not [string]::IsNullOrWhiteSpace(($status | Out-String))) {
    throw 'Worktree is dirty. Commit or stash changes first, or rerun with -AllowDirty.'
  }
}

function Ensure-TagPushed {
  param([string]$Root, [string]$Tag)
  & $git -C $Root rev-parse -q --verify "refs/tags/$Tag" | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Write-Log "Creating tag $Tag"
    & $git -C $Root tag $Tag
    if ($LASTEXITCODE -ne 0) {
      throw "Failed to create tag $Tag"
    }
  }

  Write-Log 'Pushing current branch'
  & $git -C $Root push origin HEAD
  if ($LASTEXITCODE -ne 0) {
    throw 'Failed to push current branch.'
  }

  Write-Log "Pushing tag $Tag"
  & $git -C $Root push origin $Tag
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to push tag $Tag"
  }
}

function Get-ReleaseBody {
  param([string]$Version, [string]$Notes)
  if (-not [string]::IsNullOrWhiteSpace($Notes)) {
    return $Notes
  }
  return "Release $Version"
}

function Use-GitHubCli {
  $gh = Get-Command gh -ErrorAction SilentlyContinue
  return $null -ne $gh
}

function Publish-WithGh {
  param(
    [string]$Root,
    [string]$Tag,
    [string]$ZipPath,
    [string]$Body
  )

  Write-Log 'Publishing with GitHub CLI'
  & gh release view $Tag --repo "$repoOwner/$repoName" | Out-Null
  if ($LASTEXITCODE -eq 0) {
    & gh release upload $Tag $ZipPath --repo "$repoOwner/$repoName" --clobber
    if ($LASTEXITCODE -ne 0) {
      throw 'Failed to upload release asset with gh.'
    }
    return
  }

  & gh release create $Tag $ZipPath --repo "$repoOwner/$repoName" --title $Tag --notes $Body
  if ($LASTEXITCODE -ne 0) {
    throw 'Failed to create release with gh.'
  }
}

function Get-Token {
  if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
    return $env:GITHUB_TOKEN
  }
  if (-not [string]::IsNullOrWhiteSpace($env:GH_TOKEN)) {
    return $env:GH_TOKEN
  }
  throw 'Missing GitHub credential. Install gh or set GITHUB_TOKEN / GH_TOKEN.'
}

function Invoke-GitHubApi {
  param(
    [string]$Method,
    [string]$Uri,
    [object]$Body = $null,
    [string]$ContentType = 'application/json; charset=utf-8'
  )

  $token = Get-Token
  $headers = @{
    Authorization = "Bearer $token"
    Accept = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
  }

  if ($null -eq $Body) {
    return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers
  }

  return Invoke-RestMethod -Method $Method -Uri $Uri -Headers $headers -Body $Body -ContentType $ContentType
}

function Find-ReleaseByTag {
  param([string]$Tag)
  $token = Get-Token
  $headers = @{
    Authorization = "Bearer $token"
    Accept = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
  }
  try {
    return Invoke-RestMethod -Method Get -Uri "https://api.github.com/repos/$repoOwner/$repoName/releases/tags/$Tag" -Headers $headers
  } catch {
    return $null
  }
}

function Publish-WithApi {
  param(
    [string]$Tag,
    [string]$ZipPath,
    [string]$Body
  )

  Write-Log 'Publishing with GitHub API'
  $release = Find-ReleaseByTag -Tag $Tag
  if ($null -eq $release) {
    $payload = @{
      tag_name = $Tag
      target_commitish = 'main'
      name = $Tag
      body = $Body
      draft = $false
      prerelease = $false
    } | ConvertTo-Json

    $release = Invoke-GitHubApi -Method Post -Uri "https://api.github.com/repos/$repoOwner/$repoName/releases" -Body $payload
  }

  $assetName = Split-Path -Leaf $ZipPath
  foreach ($asset in @($release.assets)) {
    if ($asset.name -eq $assetName) {
      Write-Log "Deleting existing asset $assetName"
      Invoke-GitHubApi -Method Delete -Uri "https://api.github.com/repos/$repoOwner/$repoName/releases/assets/$($asset.id)"
    }
  }

  $uploadUrl = ($release.upload_url -replace '\{\?name,label\}', '') + "?name=$assetName"
  $token = Get-Token
  $headers = @{
    Authorization = "Bearer $token"
    Accept = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
    'Content-Type' = 'application/zip'
  }

  Write-Log "Uploading $assetName"
  Invoke-RestMethod -Method Post -Uri $uploadUrl -Headers $headers -InFile $ZipPath -ContentType 'application/zip' | Out-Null
}

$version = Get-VersionFromPubspec -Path $pubspecPath
$tag = "v$version"

Write-Log "Version $version"
Write-Log "Repository $(Get-RemoteUrl -Root $repoRoot)"

Ensure-CleanWorktree -Root $repoRoot -AllowDirtyWorktree:$AllowDirty

if (-not $SkipBuild) {
  Write-Log 'Running release build script'
  powershell -ExecutionPolicy Bypass -File $buildScript
}

if (-not (Test-Path -LiteralPath $distZip)) {
  throw "Release zip not found: $distZip"
}

Ensure-TagPushed -Root $repoRoot -Tag $tag

$body = Get-ReleaseBody -Version $version -Notes $ReleaseNotes
if (Use-GitHubCli) {
  Publish-WithGh -Root $repoRoot -Tag $tag -ZipPath $distZip -Body $body
} else {
  Publish-WithApi -Tag $tag -ZipPath $distZip -Body $body
}

Write-Log "Release published: $tag"
