param(
  [Parameter(Mandatory = $true)]
  [string]$RepositoryUrl,
  [string]$Branch = "main"
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw "Git is not installed or not available in PATH."
}

$null = git lfs version
if ($LASTEXITCODE -ne 0) {
  throw "Git LFS is not installed or not available through git lfs."
}

if ($RepositoryUrl -notmatch '^https://github\.com/.+/.+(\.git)?$') {
  throw "RepositoryUrl should look like https://github.com/<user>/<repo>.git"
}

git lfs install

$currentBranch = git branch --show-current
if (-not $currentBranch) {
  throw "Could not determine current Git branch."
}

if ($currentBranch -ne $Branch) {
  git branch -M $Branch
}

$existingOrigin = git remote get-url origin 2>$null
if ($LASTEXITCODE -eq 0 -and $existingOrigin) {
  git remote set-url origin $RepositoryUrl
} else {
  git remote add origin $RepositoryUrl
}

Write-Host "Pushing Git commit to $RepositoryUrl on branch $Branch..."
git push -u origin $Branch

Write-Host "Pushing Git LFS objects. This can take a while for the 1.3GB offline photo library..."
git lfs push origin $Branch --all

Write-Host "Done. Now open Codemagic, connect this GitHub repository, and run ios-offline-dev."