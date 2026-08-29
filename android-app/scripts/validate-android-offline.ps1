param(
  [string]$AndroidRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

function Assert-Exists {
  param([string]$Path, [string]$Label)
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Missing $Label at $Path"
  }
}

$appRoot = Join-Path $AndroidRoot "app"
$sourceRoot = Join-Path $appRoot "src\main"
$javaRoot = Join-Path $sourceRoot "java\com\local\photopractice"
$metadataPath = Join-Path $sourceRoot "assets\PhotoMetadata\ippawards-metadata.json"

Assert-Exists (Join-Path $AndroidRoot "settings.gradle") "Gradle settings"
Assert-Exists (Join-Path $AndroidRoot "build.gradle") "root Gradle file"
Assert-Exists (Join-Path $appRoot "build.gradle") "app Gradle file"
Assert-Exists (Join-Path $sourceRoot "AndroidManifest.xml") "Android manifest"
Assert-Exists (Join-Path $javaRoot "MainActivity.java") "MainActivity"
Assert-Exists (Join-Path $javaRoot "Photo.java") "Photo model"
Assert-Exists (Join-Path $javaRoot "Record.java") "Record model"
Assert-Exists (Join-Path $javaRoot "ZoomImageView.java") "zoom image view"
Assert-Exists $metadataPath "photo metadata manifest"

$manifest = Get-Content -Raw -LiteralPath (Join-Path $sourceRoot "AndroidManifest.xml")
@('.MainActivity', 'android.intent.action.MAIN') | ForEach-Object {
  if (-not $manifest.Contains($_)) { throw "AndroidManifest.xml does not include $_" }
}

$gradle = Get-Content -Raw -LiteralPath (Join-Path $appRoot "build.gradle")
@('com.android.application', 'com.local.photopractice', 'minSdk', 'targetSdk') | ForEach-Object {
  if (-not $gradle.Contains($_)) { throw "app/build.gradle does not include $_" }
}

$metadataRaw = Get-Content -Raw -LiteralPath $metadataPath
$metadataCount = ([regex]::Matches($metadataRaw, '"filename"')).Count
if ($metadataCount -lt 6000) {
  throw "Expected at least 6000 metadata records, got $metadataCount"
}

$javaFiles = Get-ChildItem -LiteralPath $javaRoot -Filter *.java
if ($javaFiles.Count -lt 4) {
  throw "Expected Android Java source files under $javaRoot"
}

Write-Host "OK: PhotoPractice Android source check passed."
Write-Host "Java files: $($javaFiles.Count)"
Write-Host "Metadata photos: $metadataCount"
Write-Host "Note: build APK with Codemagic workflow 'PhotoPractice Android Debug APK'."
