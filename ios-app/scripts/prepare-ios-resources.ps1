param(
  [string]$SourceRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path,
  [string]$DestinationRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\PhotoPractice\Resources")).Path
)

$ErrorActionPreference = "Stop"

$photoLibrary = Join-Path $DestinationRoot "PhotoLibrary"
New-Item -ItemType Directory -Force -Path $photoLibrary | Out-Null

Copy-Item -LiteralPath (Join-Path $SourceRoot "ippawards-2012-2026-manifest.json") -Destination (Join-Path $photoLibrary "photo-manifest.json") -Force
Copy-Item -LiteralPath (Join-Path $SourceRoot "ippawards-2012-2026-summary.json") -Destination (Join-Path $photoLibrary "photo-summary.json") -Force

2012..2026 | ForEach-Object {
  $yearFolder = "ippawards-$_"
  $source = Join-Path $SourceRoot $yearFolder
  $destination = Join-Path $photoLibrary $yearFolder

  if (-not (Test-Path -LiteralPath $source)) {
    Write-Warning "Missing $source"
    return
  }

  Write-Host "Copying $yearFolder..."
  robocopy $source $destination /E /NFL /NDL /NJH /NJS /NC /NS | Out-Null
  if ($LASTEXITCODE -gt 7) {
    throw "robocopy failed for $yearFolder with exit code $LASTEXITCODE"
  }
}

Write-Host "Done. Resources are ready at $photoLibrary"
