#!/usr/bin/env bash
set -euo pipefail

IOS_ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export IOS_ROOT

python3 <<'PY'
import os
import pathlib
import struct

root = pathlib.Path(os.environ["IOS_ROOT"])
project_file = root / "project.yml"
info_plist = root / "PhotoPractice" / "Info.plist"
app_icon_json = root / "PhotoPractice" / "Assets.xcassets" / "AppIcon.appiconset" / "Contents.json"
zip_reader = root / "PhotoPractice" / "Services" / "ZipArchiveReader.swift"


def require(path, label):
    if not path.exists():
        raise SystemExit(f"Missing {label}: {path}")


for path, label in [
    (project_file, "XcodeGen project file"),
    (info_plist, "Info.plist"),
    (app_icon_json, "AppIcon catalog"),
    (zip_reader, "ZIP archive reader"),
]:
    require(path, label)

project_yaml = project_file.read_text(encoding="utf-8")
for token in [
    "PhotoPractice/App",
    "PhotoPractice/Models",
    "PhotoPractice/Services",
    "PhotoPractice/Views",
    "PhotoPractice/Assets.xcassets",
    "ZIPFoundation",
]:
    if token not in project_yaml:
        raise SystemExit(f"project.yml does not include {token}")

if "PhotoPractice/Resources/PhotoLibrary" in project_yaml:
    raise SystemExit("project.yml should not bundle the full photo library in reader mode")

info_plist_text = info_plist.read_text(encoding="utf-8")
for token in [
    "CFBundleIdentifier",
    "PRODUCT_BUNDLE_IDENTIFIER",
    "CFBundleExecutable",
    "EXECUTABLE_NAME",
    "CFBundleVersion",
    "CURRENT_PROJECT_VERSION",
]:
    if token not in info_plist_text:
        raise SystemExit(f"Info.plist does not include {token}")


def png_size(path):
    with path.open("rb") as fh:
        if fh.read(8) != b"\x89PNG\r\n\x1a\n":
            raise SystemExit(f"{path.name} is not a PNG file")
        length, chunk_type = struct.unpack(">I4s", fh.read(8))
        if chunk_type != b"IHDR" or length < 8:
            raise SystemExit(f"{path.name} is missing a valid IHDR chunk")
        width, height = struct.unpack(">II", fh.read(8))
        return width, height

required_icons = {
    "icon-180.png": 180,
    "icon-1024.png": 1024,
}

icon_root = root / "PhotoPractice" / "Assets.xcassets" / "AppIcon.appiconset"
for filename, expected in required_icons.items():
    icon_path = icon_root / filename
    require(icon_path, f"AppIcon image {filename}")
    width, height = png_size(icon_path)
    if width != expected or height != expected:
        raise SystemExit(f"{filename} should be {expected}x{expected}, got {width}x{height}")

swift_files = list((root / "PhotoPractice").rglob("*.swift"))
if len(swift_files) < 10:
    raise SystemExit(f"Expected Swift source files under {root / 'PhotoPractice'}")

print("OK: PhotoPractice reader-mode iOS source check passed.")
print(f"Swift files: {len(swift_files)}")
print("Note: image ZIP packs are imported in the app from the iOS Files picker.")
print("Note: run xcodegen + xcodebuild on macOS or Codemagic for the real iOS compile check.")
PY

