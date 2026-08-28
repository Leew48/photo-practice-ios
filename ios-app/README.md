# Photo Practice iOS

This is the offline iPhone version of "看图计划".

The app now works as a lightweight SwiftUI reader: install the app first, then import a local ZIP image pack from the iOS Files picker. This keeps the IPA small and avoids pushing a 1GB+ photo library through GitHub LFS.

## Current Scope

- Import a ZIP image pack from Settings.
- Scan folders in the ZIP and turn them into photo categories automatically.
- Browse photos in Today, Viewer, Library, Review, and Settings tabs.
- Keep viewed, favorite, daily records, notes, and the current photo position in local app storage.
- Filter Library by search text, year, category, award, and favorites.
- Review monthly progress with a day-by-day calendar and daily records.
- Export and import progress backups as JSON files.
- Cache images in memory while reading from the imported local library.
- Remove an imported library without deleting viewing records.

## Image Pack Flow

Create or obtain a ZIP file whose folders represent categories:

```text
PhotoLibrary.zip
└── PhotoLibrary/
    ├── Portrait/
    │   ├── 001.jpg
    │   └── 002.jpg
    ├── Landscape/
    │   └── 001.jpg
    └── Architecture/
        └── 001.jpg
```

On Windows, if the local `PhotoPractice/Resources/PhotoLibrary` folder exists, create a ZIP pack with:

```powershell
.\scripts\create-photo-pack.ps1
```

Then copy `PhotoLibrary.zip` to iCloud Drive, On My iPhone, Downloads, or any location visible in the iOS Files app. In PhotoPractice, open Settings and choose `导入图片压缩包`.

See `PHOTO_PACK_GUIDE.md` for the full pack format and iPhone import steps.

## Windows Validation

On Windows, run this before pushing to GitHub or Codemagic:

```powershell
cd ios-app
.\scripts\validate-ios-offline.ps1
```

This checks the reader-mode source layout, ZIP import code, AppIcon image sizes, and XcodeGen configuration. It does not replace the real iOS compile check, which still needs macOS or Codemagic.

## No-Mac Handoff

If you do not own a Mac, use the root `../codemagic.yaml` for cloud builds. Codemagic builds the app only; the image ZIP pack is imported later on the iPhone. See `NO_MAC_BUILD_GUIDE.md` and `WINDOWS_TO_TESTFLIGHT.md`.

## Xcode Handoff

Preferred path: use `project.yml` with XcodeGen on a Mac.

```sh
cd ios-app
brew install xcodegen
xcodegen generate
open PhotoPractice.xcodeproj
```

Then add signing in Xcode and run on the iPhone.

Manual fallback: create a new iOS App project in Xcode named `PhotoPractice`, choose SwiftUI, then add these folders to the target:

- `PhotoPractice/App`
- `PhotoPractice/Models`
- `PhotoPractice/Services`
- `PhotoPractice/Views`
- `PhotoPractice/Assets.xcassets`

See `XCODE_BUILD_STEPS.md` for the full installation handoff.
