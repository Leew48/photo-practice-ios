# Windows To TestFlight Checklist

This project is ready for a no-Mac workflow, but iPhone installation still needs Apple signing.

## One-Time Accounts

1. Create or use a GitHub account.
2. Create or use a Codemagic account.
3. Join the Apple Developer Program for stable TestFlight installation.
4. Create an App Store Connect app record for the same bundle identifier you will use in Codemagic.

## Prepare This Repository

The offline iOS app lives in:

```text
ios-app/
```

Codemagic configuration lives at the repository root:

```text
codemagic.yaml
```

Before uploading to GitHub:

1. Keep `.gitattributes` so image files use Git LFS.
2. Make sure Git LFS is installed and enabled locally.
3. Do not upload `tailscale-setup-*.msi` or `tailscale-install.log`; `.gitignore` excludes them.
4. Make sure your GitHub repository has enough LFS quota for about 1.3GB of photos.

Recommended local commands before the first push:

```powershell
git lfs install
.\ios-app\scripts\validate-ios-offline.ps1
git add .
git commit -m "Add offline iOS app and Codemagic pipeline"
git remote add origin <your-github-repo-url>
git push -u origin main
```

## Codemagic Compile Check

1. In Codemagic, choose **Add application**.
2. Connect the GitHub repository.
3. Let Codemagic scan the root `codemagic.yaml`.
4. Run workflow:

```text
ios-offline-dev
```

This confirms the SwiftUI app compiles in the cloud without signing.

## TestFlight Setup

After the compile check passes:

1. Choose a real bundle identifier, for example:

```text
com.yourname.photopractice
```

2. Update it in the root `codemagic.yaml` in both places under `ios-testflight`:

```text
bundle_identifier: com.yourname.photopractice
BUNDLE_ID: "com.yourname.photopractice"
```

3. In App Store Connect, create an app record using the same bundle identifier.
4. In Codemagic, connect App Store Connect with an API key/integration.
5. Configure iOS App Store code signing for the same bundle identifier.
6. Run workflow:

```text
ios-testflight
```

7. When the build finishes, the signed `.ipa` appears in Codemagic artifacts and the build is submitted to TestFlight.
8. Install the app from TestFlight on your iPhone.

## Iteration Loop

After the first iPhone install:

1. Use the app normally.
2. Tell Codex the problem or improvement.
3. Codex edits `ios-app/PhotoPractice`.
4. Push the updated repository.
5. Codemagic builds a new TestFlight version.
