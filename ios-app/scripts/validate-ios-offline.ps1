param(
  [string]$IOSRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
)

$ErrorActionPreference = "Stop"

function Assert-Exists {
  param([string]$Path, [string]$Label)
  if (-not (Test-Path -LiteralPath $Path)) {
    throw "Missing $Label at $Path"
  }
}

$projectFile = Join-Path $IOSRoot "project.yml"
$sourceRoot = Join-Path $IOSRoot "PhotoPractice"
$appIconPath = Join-Path $sourceRoot "Assets.xcassets\AppIcon.appiconset\Contents.json"

Assert-Exists $projectFile "XcodeGen project file"
Assert-Exists $appIconPath "AppIcon catalog"
Assert-Exists (Join-Path $sourceRoot "Services\ZipArchiveReader.swift") "ZIP archive reader"

$projectYaml = Get-Content -Raw -LiteralPath $projectFile
@("PhotoPractice/App", "PhotoPractice/Models", "PhotoPractice/Services", "PhotoPractice/Views", "PhotoPractice/Assets.xcassets") | ForEach-Object {
  if (-not $projectYaml.Contains($_)) {
    throw "project.yml does not include $_"
  }
}

if ($projectYaml.Contains("PhotoPractice/Resources/PhotoLibrary")) {
  throw "project.yml should not bundle the full photo library in reader mode"
}

Add-Type -AssemblyName System.Drawing
$requiredIcons = @{
  "icon-180.png" = 180
  "icon-1024.png" = 1024
}

foreach ($entry in $requiredIcons.GetEnumerator()) {
  $iconPath = Join-Path $sourceRoot "Assets.xcassets\AppIcon.appiconset\$($entry.Key)"
  Assert-Exists $iconPath "AppIcon image $($entry.Key)"
  $image = [System.Drawing.Image]::FromFile($iconPath)
  try {
    if ($image.Width -ne $entry.Value -or $image.Height -ne $entry.Value) {
      throw "$($entry.Key) should be $($entry.Value)x$($entry.Value), got $($image.Width)x$($image.Height)"
    }
  } finally {
    $image.Dispose()
  }
}

$swiftFiles = Get-ChildItem -LiteralPath $sourceRoot -Recurse -Filter *.swift
if ($swiftFiles.Count -lt 10) {
  throw "Expected Swift source files under $sourceRoot"
}

Write-Host "OK: PhotoPractice reader-mode iOS source check passed."
Write-Host "Swift files: $($swiftFiles.Count)"
Write-Host "Note: image ZIP packs are imported in the app from the iOS Files picker."
Write-Host "Note: run xcodegen + xcodebuild on macOS or Codemagic for the real iOS compile check."
