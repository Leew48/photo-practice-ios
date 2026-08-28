# Next iOS Development Plan

Goal: move the offline iPhone app from source-complete beta to a signed TestFlight build.

## Completed In This Iteration

1. Added year, category, award, and favorite filters in Library.
2. Added month summary and daily progress calendar in Review.
3. Added export and import for progress backup.
4. Added lightweight image cache in the viewer and library thumbnails.
5. Added first-launch onboarding explaining offline size and signing status.
6. Added a Windows-side offline validation script.

## Next Build Steps

1. Push the repository to GitHub with the full `ios-app/PhotoPractice/Resources/PhotoLibrary` folder or attach resources during the cloud build.
2. Run the `ios-offline-dev` Codemagic workflow for an unsigned simulator compile check.
3. Fix any Xcode-only compile warnings or resource copy issues from the cloud build log.
4. Configure Apple Developer signing in Codemagic.
5. Run the `ios-testflight` workflow and install the first build on iPhone.
6. Test real-device performance with the 1.3GB bundled photo library.

## Product Follow-Ups After First Device Test

1. Add generated thumbnails if full-size image decoding makes Library scrolling heavy.
2. Add per-category study goals if the basic daily target feels too coarse.
3. Add iCloud Drive backup only if local JSON export is not enough.
4. Tune typography and spacing after seeing the app on the target iPhone model.

## Install Boundary

The app can be developed without a paid Apple Developer account, but stable installation on an iPhone still requires Apple signing. Keep TestFlight disabled until the account is ready.
