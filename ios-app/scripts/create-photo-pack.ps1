param(
  [string]$IOSRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path,
  [string]$OutputPath = (Join-Path (Resolve-Path (Join-Path $PSScriptRoot "..")).Path "PhotoLibrary.zip")
)

$ErrorActionPreference = "Stop"

$libraryRoot = Join-Path $IOSRoot "PhotoPractice\Resources\PhotoLibrary"
if (-not (Test-Path -LiteralPath $libraryRoot)) {
  throw "Photo library folder not found: $libraryRoot"
}

if (Test-Path -LiteralPath $OutputPath) {
  Remove-Item -LiteralPath $OutputPath -Force
}

$parent = Split-Path -Parent $libraryRoot
$name = Split-Path -Leaf $libraryRoot
Push-Location $parent
try {
  Compress-Archive -LiteralPath $name -DestinationPath $OutputPath -CompressionLevel Optimal
} finally {
  Pop-Location
}

$photoCount = Get-ChildItem -LiteralPath $libraryRoot -Recurse -File -Include *.jpg,*.jpeg,*.png,*.heic,*.heif,*.webp | Measure-Object | Select-Object -ExpandProperty Count
$zip = Get-Item -LiteralPath $OutputPath
Write-Host "OK: Created $OutputPath"
Write-Host "Photos: $photoCount"
Write-Host ("Size: {0:N1} MB" -f ($zip.Length / 1MB))
Write-Host "Copy this ZIP to iCloud Drive, On My iPhone, or any Files location, then import it in PhotoPractice Settings."
