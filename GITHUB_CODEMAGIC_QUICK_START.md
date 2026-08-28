# GitHub And Codemagic Quick Start

This repository is now set up for a lightweight iOS reader app. The app imports a separate ZIP image pack on the iPhone, so GitHub and Codemagic do not need to upload or bundle the full photo library.

## What Is Already Done

- iOS SwiftUI reader source is in `ios-app/PhotoPractice`.
- The app can import a ZIP image pack from Settings.
- Folders inside the ZIP become app categories automatically.
- Codemagic configuration is at the repository root: `codemagic.yaml`.
- Windows reader-mode validation passes with `ios-app/scripts/validate-ios-offline.ps1`.

## What You Need To Do In GitHub

1. Open https://github.com/new
2. Repository name: `photo-practice-ios`
3. Choose `Private` unless you intentionally want the project public.
4. Do not add README, .gitignore, or license on GitHub.
5. Click `Create repository`.
6. Copy the HTTPS URL. It should look like:

```text
https://github.com/<your-name>/photo-practice-ios.git
```

## Push From This Computer

After creating the empty GitHub repository, run this from the project root:

```powershell
.\scripts\push-to-github.ps1 -RepositoryUrl "https://github.com/<your-name>/photo-practice-ios.git"
```

Reader mode should push much more easily because the IPA project no longer needs the full image library in Git LFS.

## What You Need To Do In Codemagic

1. Open https://codemagic.io/apps
2. Click `Add application`.
3. Connect GitHub and select `photo-practice-ios`.
4. Let Codemagic scan the root `codemagic.yaml`.
5. Run workflow `ios-reader-dev` first.
6. If that passes, configure Apple Developer signing.
7. Replace `com.yourname.photopractice` in `codemagic.yaml` with your real Apple bundle identifier.
8. Run workflow `ios-testflight`.

## Image Pack On iPhone

The Codemagic/TestFlight app does not include the large photo library. Put `PhotoLibrary.zip` in iCloud Drive, On My iPhone, Downloads, or another Files location, then open the app and go to Settings -> `导入图片压缩包`.

See `ios-app/PHOTO_PACK_GUIDE.md` for ZIP structure and Windows pack creation.

## Important Note

A signed iPhone install still requires an Apple Developer Program account. Codemagic can build the app without a Mac, but Apple still controls real-device signing and TestFlight.
