# No-Mac iPhone Install Guide

You do not need to own a Mac to keep developing this project, but every iPhone app still needs Apple signing before it can be installed on a real iPhone.

## Practical Route

Use Codemagic cloud builds:

1. Put this whole repository in GitHub.
2. Keep the root `codemagic.yaml`; Codemagic expects that file at the repository root.
3. Connect the GitHub repository to Codemagic.
4. Run `ios-offline-dev` first. This performs an unsigned iOS simulator compile check.
5. When the compile check passes, configure Apple Developer signing in Codemagic.
6. Run `ios-testflight`.
7. Install the app on iPhone through TestFlight.

## Apple Account Requirement

For stable long-term iPhone installation, use a paid Apple Developer Program account. TestFlight and App Store Connect signing rely on Apple Developer Program distribution credentials.

Without a Mac and without Apple Developer signing, there is no clean long-term iPhone installation path. PC sideload tools usually expire quickly and are a poor fit for this project.

## Large Offline Bundle

The offline app currently bundles:

- 6078 photos
- about 1.3GB of image files
- `photo-manifest.json`

The repository is configured to track images with Git LFS. Make sure your GitHub account/repository has enough LFS storage and bandwidth for the first push and Codemagic builds. If Git LFS quota becomes the blocker, the fallback is to stop using LFS for these image files or host a resource zip elsewhere and let Codemagic download it during the build.

## Bundle Identifier

Before running the signed workflow, replace `com.yourname.photopractice` in the root `codemagic.yaml` with the real bundle identifier registered in your Apple Developer account.

The `ios-testflight` workflow injects that bundle identifier into `ios-app/project.yml` before generating the Xcode project.

## Suggested Iteration Flow

1. Develop source in this Windows workspace.
2. Push to GitHub.
3. Run `ios-offline-dev` in Codemagic.
4. Fix any compile issues shown in the Codemagic log.
5. Run `ios-testflight` after signing is configured.
6. Install/update from TestFlight on iPhone.
7. Use the app normally and report issues.
8. Keep improving the SwiftUI source in `ios-app/PhotoPractice`.
