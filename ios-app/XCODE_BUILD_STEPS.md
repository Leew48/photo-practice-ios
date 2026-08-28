# Xcode Build Steps

This folder contains the first offline iOS version of "看图计划".

## What You Need

- A Mac with Xcode installed.
- Your iPhone connected by cable or on the same Apple Developer account.
- An Apple ID. A paid Apple Developer Program account is recommended for TestFlight or stable long-term installation.

## Prepare The Project On Mac

1. Copy the whole repository folder to the Mac.
2. Open Terminal in `ios-app`.
3. Install XcodeGen if needed:

```sh
brew install xcodegen
```

4. Generate the Xcode project:

```sh
xcodegen generate
```

5. Open:

```text
PhotoPractice.xcodeproj
```

## Sign And Install

1. In Xcode, select the `PhotoPractice` target.
2. Open `Signing & Capabilities`.
3. Choose your Apple development team.
4. Change `Bundle Identifier` if Xcode says it is already taken.
5. Select your iPhone as the run destination.
6. Press Run.

## Important Notes

- The app is offline. The 6078 photos are bundled under `PhotoPractice/Resources/PhotoLibrary`.
- The first app build may be slow because the bundled photos are about 1.3GB.
- Progress is saved with `UserDefaults` under `photo-practice-ios-progress-v1`.
- The current source is a first usable iOS build, meant for fast iteration after real iPhone testing.
