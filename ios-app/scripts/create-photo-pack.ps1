param(
  [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
  [string]$OutputPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "PhotoLibrary.zip")
)

$ErrorActionPreference = "Stop"

$sourceDirs = Get-ChildItem -LiteralPath $ProjectRoot -Directory -Filter "ippawards-*" |
  Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "photos") } |
  Sort-Object Name

if (-not $sourceDirs -or $sourceDirs.Count -eq 0) {
  throw "No ippawards photo folders found under $ProjectRoot"
}

if (Test-Path -LiteralPath $OutputPath) {
  Remove-Item -LiteralPath $OutputPath -Force
}

$photoCount = 0
$totalBytes = 0
foreach ($dir in $sourceDirs) {
  Get-ChildItem -LiteralPath $dir.FullName -Recurse -File -Include *.jpg,*.jpeg,*.png,*.heic,*.heif,*.webp | ForEach-Object {
    if ((Get-Content -LiteralPath $_.FullName -TotalCount 1 -ErrorAction SilentlyContinue) -like "version https://git-lfs.github.com/spec/v1*") {
      throw "Found a Git LFS pointer instead of a real image: $($_.FullName)"
    }
    $photoCount += 1
    $totalBytes += $_.Length
  }
}

if ($photoCount -eq 0) {
  throw "No images found in ippawards folders under $ProjectRoot"
}

$literalPaths = $sourceDirs | ForEach-Object { $_.FullName }
Compress-Archive -LiteralPath $literalPaths -DestinationPath $OutputPath -CompressionLevel Optimal

$zip = Get-Item -LiteralPath $OutputPath
Write-Host "OK: Created $OutputPath"
Write-Host "Source folders: $($sourceDirs.Count)"
Write-Host "Photos: $photoCount"
Write-Host ("Original size: {0:N1} MB" -f ($totalBytes / 1MB))
Write-Host ("ZIP size: {0:N1} MB" -f ($zip.Length / 1MB))
Write-Host "Copy this ZIP to iCloud Drive, On My iPhone, or any Files location, then import it in PhotoPractice Settings."
