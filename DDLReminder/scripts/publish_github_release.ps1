param(
  [switch]$SkipBuild,
  [switch]$AllowDirty,
  [switch]$AutoCommitDirty,
  [string]$CommitMessage = '',
  [string]$ReleaseNotes = '',
  [string]$Token = '',
  [ValidateSet('build', 'patch', 'minor', 'major')]
  [string]$Bump = '',
  [string]$SetVersion = '',
  [string]$TargetBranch = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$projectRoot = Split-Path -Parent $PSScriptRoot
$distZip = Join-Path $projectRoot 'dist\DDLReminder-windows-release.zip'
$buildScript = Join-Path $projectRoot 'scripts\build_release.ps1'
$bumpScript = Join-Path $projectRoot 'scripts\bump_version.ps1'
$pubspecPath = Join-Path $projectRoot 'pubspec.yaml'
$repoRoot = Split-Path -Parent $projectRoot
$git = 'git'
$repoOwner = 'usgnay'
$repoName = 'DDLreminder'

function Write-Log {
  param([string]$Message)
  Write-Host "[publish] $Message"
}

function Assert-VersionFormat {
  param([string]$Version)
  if ($Version -notmatch '^\d+\.\d+\.\d+\+\d+$') {
    throw "Invalid version format: $Version. Expected major.minor.patch+build"
  }
}

function Get-VersionFromPubspec {
  param([string]$Path)
  $line = Get-Content -Path $Path | Where-Object { $_ -match '^version:' } | Select-Object -First 1
  if (-not $line) {
    throw 'Missing version in pubspec.yaml'
  }
  $version = ($line -replace '^version:\s*', '').Trim()
  Assert-VersionFormat -Version $version
  return $version
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

function Save-DirtyWorktree {
  param(
    [string]$Root,
    [string]$Version,
    [string]$Message
  )

  $status = & $git -C $Root status --porcelain
  if ($LASTEXITCODE -ne 0) {
    throw 'Failed to read git status.'
  }
  if ([string]::IsNullOrWhiteSpace(($status | Out-String))) {
    return $false
  }

  $commitMessage = $Message
  if ([string]::IsNullOrWhiteSpace($commitMessage)) {
    $commitMessage = "chore: prepare release v$Version"
  }

  Write-Log 'Worktree is dirty, staging tracked changes'
  & $git -C $Root add -A
  if ($LASTEXITCODE -ne 0) {
    throw 'Failed to stage dirty worktree.'
  }

  Write-Log "Creating commit: $commitMessage"
  & $git -C $Root commit -m $commitMessage
  if ($LASTEXITCODE -ne 0) {
    throw 'Failed to commit dirty worktree.'
  }

  return $true
}

function Test-RemoteTagExists {
  param(
    [string]$Root,
    [string]$Tag
  )

  & $git -C $Root ls-remote --tags origin "refs/tags/$Tag" | Out-Null
  if ($LASTEXITCODE -ne 0) {
    throw "Failed to query remote tag $Tag"
  }

  $output = & $git -C $Root ls-remote --tags origin "refs/tags/$Tag"
  return -not [string]::IsNullOrWhiteSpace(($output | Out-String))
}

function Get-LocalTagSha {
  param(
    [string]$Root,
    [string]$Tag
  )

  $sha = & $git -C $Root rev-list -n 1 $Tag 2>$null
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($sha)) {
    return $null
  }
  return $sha.Trim()
}

function Get-RemoteTagSha {
  param(
    [string]$Root,
    [string]$Tag
  )

  $output = & $git -C $Root ls-remote --tags origin "refs/tags/$Tag"
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace(($output | Out-String))) {
    return $null
  }

  $line = ($output | Select-Object -First 1).Trim()
  if ([string]::IsNullOrWhiteSpace($line)) {
    return $null
  }

  return ($line -split '\s+')[0].Trim()
}

function Ensure-TagPushed {
  param(
    [string]$Root,
    [string]$Tag,
    [bool]$RemoteTagExists
  )

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

  if ($RemoteTagExists) {
    $localSha = Get-LocalTagSha -Root $Root -Tag $Tag
    $remoteSha = Get-RemoteTagSha -Root $Root -Tag $Tag
    if ($null -eq $localSha -or $null -eq $remoteSha) {
      throw "Unable to verify existing remote tag $Tag"
    }
    if ($localSha -ne $remoteSha) {
      throw "Remote tag $Tag already exists but points to a different commit."
    }
    Write-Log "Tag $Tag already exists on remote; reusing it"
    return
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
  if (-not [string]::IsNullOrWhiteSpace($env:DDLREMINDER_RELEASE_NOTES)) {
    return $env:DDLREMINDER_RELEASE_NOTES.Trim()
  }
  return "Release $Version"
}

function Use-GitHubCli {
  $gh = Get-Command gh -ErrorAction SilentlyContinue
  return $null -ne $gh
}

function Publish-WithGh {
  param(
    [string]$Tag,
    [string]$ZipPath,
    [string]$Body
  )

  Write-Log 'Publishing with GitHub CLI'
  & gh release view $Tag --repo "$repoOwner/$repoName" | Out-Null
  if ($LASTEXITCODE -eq 0) {
    & gh release edit $Tag --repo "$repoOwner/$repoName" --title $Tag --notes $Body
    if ($LASTEXITCODE -ne 0) {
      throw 'Failed to update release notes with gh.'
    }
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
  if (-not [string]::IsNullOrWhiteSpace($Token)) {
    return $Token
  }
  if (-not [string]::IsNullOrWhiteSpace($env:DDLREMINDER_GITHUB_TOKEN)) {
    return $env:DDLREMINDER_GITHUB_TOKEN
  }
  if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_TOKEN)) {
    return $env:GITHUB_TOKEN
  }
  if (-not [string]::IsNullOrWhiteSpace($env:GH_TOKEN)) {
    return $env:GH_TOKEN
  }
  $promptedToken = Read-Host 'Enter GitHub token (leave blank to cancel)'
  if (-not [string]::IsNullOrWhiteSpace($promptedToken)) {
    return $promptedToken.Trim()
  }
  throw 'Missing GitHub credential. Install gh or set GITHUB_TOKEN / GH_TOKEN, or provide -Token.'
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

function Resolve-TargetBranch {
  param([string]$Root, [string]$ExplicitBranch)
  if (-not [string]::IsNullOrWhiteSpace($ExplicitBranch)) {
    return $ExplicitBranch.Trim()
  }
  $branch = & $git -C $Root branch --show-current
  if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($branch)) {
    throw 'Unable to determine current branch. Use -TargetBranch explicitly.'
  }
  return $branch.Trim()
}

function Publish-WithApi {
  param(
    [string]$Tag,
    [string]$ZipPath,
    [string]$Body,
    [string]$TargetCommitish
  )

  Write-Log 'Publishing with GitHub API'
  $release = Find-ReleaseByTag -Tag $Tag
  if ($null -eq $release) {
    $payload = @{
      tag_name = $Tag
      target_commitish = $TargetCommitish
      name = $Tag
      body = $Body
      draft = $false
      prerelease = $false
    } | ConvertTo-Json

    $release = Invoke-GitHubApi -Method Post -Uri "https://api.github.com/repos/$repoOwner/$repoName/releases" -Body $payload
  } else {
    $payload = @{
      target_commitish = $TargetCommitish
      name = $Tag
      body = $Body
      draft = $false
      prerelease = $false
    } | ConvertTo-Json

    $release = Invoke-GitHubApi -Method Patch -Uri "https://api.github.com/repos/$repoOwner/$repoName/releases/$($release.id)" -Body $payload
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

if (-not [string]::IsNullOrWhiteSpace($SetVersion) -and -not [string]::IsNullOrWhiteSpace($Bump)) {
  throw 'Use either -Bump or -SetVersion, not both.'
}

if (-not [string]::IsNullOrWhiteSpace($Bump) -or -not [string]::IsNullOrWhiteSpace($SetVersion)) {
  if (-not (Test-Path -LiteralPath $bumpScript)) {
    throw "Version bump script not found: $bumpScript"
  }

  Write-Log 'Updating version before publish'
  if (-not [string]::IsNullOrWhiteSpace($SetVersion)) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $bumpScript -SetVersion $SetVersion
  } else {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $bumpScript -Part $Bump
  }
  if ($LASTEXITCODE -ne 0) {
    throw 'Version bump script failed.'
  }
}

$version = Get-VersionFromPubspec -Path $pubspecPath
$tag = "v$version"
$targetCommitish = Resolve-TargetBranch -Root $repoRoot -ExplicitBranch $TargetBranch
$remoteTagExists = Test-RemoteTagExists -Root $repoRoot -Tag $tag

Write-Log "Version $version"
Write-Log "Tag $tag"
Write-Log "Target branch $targetCommitish"
Write-Log "Repository $(Get-RemoteUrl -Root $repoRoot)"

if ($AutoCommitDirty) {
  Save-DirtyWorktree -Root $repoRoot -Version $version -Message $CommitMessage | Out-Null
} else {
  Ensure-CleanWorktree -Root $repoRoot -AllowDirtyWorktree:$AllowDirty
}

if ($remoteTagExists) {
  Write-Log "Remote tag already exists: $tag"
}

if (-not $SkipBuild) {
  Write-Log 'Running release build script'
  powershell -NoProfile -ExecutionPolicy Bypass -File $buildScript
}

if (-not (Test-Path -LiteralPath $distZip)) {
  throw "Release zip not found: $distZip"
}

Ensure-TagPushed -Root $repoRoot -Tag $tag -RemoteTagExists:$remoteTagExists

$body = Get-ReleaseBody -Version $version -Notes $ReleaseNotes
if (Use-GitHubCli) {
  Publish-WithGh -Tag $tag -ZipPath $distZip -Body $body
} else {
  Publish-WithApi -Tag $tag -ZipPath $distZip -Body $body -TargetCommitish $targetCommitish
}

Write-Log "Release published: $tag"
