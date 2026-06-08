# DEPLOYMENT.md

CI/CD pipeline specification for **NotesApp**. This document is the single source of truth for any agent implementing the deployment workflow.

---

## Overview

```
deploy-test → local APK build → ADB install (if connected) → git push → GitHub Release → email testers
deploy-prod → warning + confirm → git push → GitHub Actions cloud build → Play Store (100%) → email testers
```

---

## Application Details

| Field | Value |
|---|---|
| App Name (device) | NotesApp |
| App Name (Play Store) | NotesApp - Chat-style notes |
| Production App ID | `com.azdhaar.notesapp` |
| RC App ID | `com.azdhaar.notesapp.rc` |
| RC Launcher Label | `NotesApp RC` |
| RC Icon | `launcher_release_candidate.png` (provided separately, distinct tint from production) |
| Compile SDK | 36 |
| Target SDK | 36 |
| Java Version | 17 |
| Gradle DSL | Kotlin DSL (`build.gradle.kts`) |
| Existing Flavors | None — must be created |
| Backend | None — fully offline app |

---

## Version Format

| Build Type | Version Name | Version Code | Example |
|---|---|---|---|
| Production | `x.y.z` | integer | `1.4.2+23` |
| RC (test) | `x.y.z-rc` | same integer | `1.4.2-rc+23` |

The `-rc` suffix is appended to `versionName` only. `versionCode` stays identical. RC builds never go to the Play Store so there is no conflict.

---

## Signing

### Local (existing setup — DO NOT MODIFY)

- `key.properties` file at project root references `upload-keystore.jks`
- `storeFile` path in `key.properties` is absolute, pointing to a location outside the project
- Current `build.gradle.kts` loads signing config from `key.properties` via `Properties()`

### CI (GitHub Actions — new)

- `upload-keystore.jks` is stored as a GitHub Secret (`KEYSTORE_BASE64`) encoded via:
  ```powershell
  [Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\upload-keystore.jks")) | Set-Clipboard
  ```
- During the workflow, the base64 secret is decoded back into a `.jks` file
- A `key.properties` file is reconstructed from individual secrets (`KEY_ALIAS`, `KEY_PASSWORD`, `STORE_PASSWORD`)
- The `build.gradle.kts` signing config must work for BOTH local and CI without breaking either:
  - If `key.properties` exists → use it (local)
  - If environment variables exist → use them (CI)
  - The existing local signing setup must remain completely untouched

---

## Product Flavors

Must be added to `build.gradle.kts`. Two flavors in a single dimension:

### `production`
- `applicationId`: `com.azdhaar.notesapp` (unchanged from current)
- `versionNameSuffix`: none
- App label: `NotesApp`
- Uses production launcher icon

### `rc` (release candidate)
- `applicationId`: `com.azdhaar.notesapp.rc`
- `versionNameSuffix`: `-rc`
- App label: `NotesApp RC`
- Uses RC launcher icon (`launcher_release_candidate.png`)
- Installs as a **separate app** alongside production on the same device
- Does NOT share data, login state, or anything with the production app

### Existing build types to preserve
- `debug` — has `applicationIdSuffix = ".debug"` and `versionNameSuffix = "-debug"` — DO NOT MODIFY
- `release` — has minify + shrink enabled — DO NOT MODIFY
- `profile` — DO NOT MODIFY

---

## Command: `deploy-test`

**Runs entirely on the developer's local machine. No cloud build.**

### Trigger
```powershell
deploy-test
```

### Steps (in order)

1. **Build APK locally**
   - Runs `flutter build apk --release --flavor rc`
   - Produces a signed APK with app ID `com.azdhaar.notesapp.rc` and version `x.y.z-rc+N`

2. **ADB install (conditional)**
   - Check if a device is connected via ADB
   - If YES → install the APK directly via `adb install` (silent, automatic)
   - If NO → skip silently, do not error

3. **Git push**
   - `git add .`
   - Prompt for commit message
   - `git commit -m "<message>"`
   - `git push origin main`

4. **Upload APK to GitHub Releases**
   - Create a GitHub Pre-Release tagged `test-<short-sha>`
   - Attach the built APK as a release asset
   - Include commit hash and branch in the release body

5. **Email all testers**
   - Send email to all addresses in the `TESTER_EMAILS` GitHub Secret
   - Email contains a download link to the GitHub Release
   - Email is sent regardless of whether ADB install succeeded

### Notes
- Steps 4 and 5 require GitHub API access from the local machine
- The APK is built and signed locally using the existing `key.properties` setup
- Flutter is installed and functional on the developer's machine (Windows)

---

## Command: `deploy-prod`

**Local push + cloud build via GitHub Actions.**

### Trigger
```powershell
deploy-prod
```

### Steps (in order)

1. **Display warning**
   - Show last commit hash (short) and commit message
   - Display prominent warning: `This will go LIVE for ALL users`
   - Require the developer to type `yes` to continue — any other input cancels

2. **Collect release notes**
   - Prompt for multi-line input (blank line to finish)
   - Release notes cannot be empty — cancel if they are
   - Release notes cannot exceed 500 characters — cancel if they do (Google Play limit)
   - Source: `markdowns/docs/release_notes.txt` WHAT'S NEW section; falls back to manual prompt if empty

3. **Git push**
   - `git push origin main`
   - If push fails, abort entirely

4. **Trigger GitHub Actions workflow** (`deploy_prod.yml`)
   - Pass `release_notes` as workflow input
   - Uses `workflow_dispatch` API

5. **GitHub Actions workflow does:**
   - Checkout code
   - Setup Java 17 + Flutter
   - Decode keystore from `KEYSTORE_BASE64` secret
   - Reconstruct `key.properties` from secrets
   - Run `flutter build appbundle --release --flavor production`
   - Write release notes to `distribution/whatsnew/whatsnew-en-US`
   - Upload AAB to Google Play Store → `production` track → 100% rollout
   - Send confirmation email to all testers

---

## GitHub Secrets Required

| Secret | Description | How to obtain |
|---|---|---|
| `KEYSTORE_BASE64` | Base64-encoded `upload-keystore.jks` | PowerShell: `[Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\path\to\upload-keystore.jks")) \| Set-Clipboard` |
| `KEY_ALIAS` | Keystore alias | From existing `key.properties` |
| `KEY_PASSWORD` | Key password | From existing `key.properties` |
| `STORE_PASSWORD` | Store password | From existing `key.properties` |
| `MAIL_USERNAME` | Gmail address used to send notifications | Developer's Gmail |
| `MAIL_APP_PASSWORD` | Gmail App Password (NOT real password) | [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords) → create one named "Flutter CI" |
| `NOTIFY_EMAIL` | Developer's own notification email | Can be same as `MAIL_USERNAME` |
| `TESTER_EMAILS` | Comma-separated list of all tester emails (including developer) | Manually maintained in GitHub Secrets |
| `PLAY_STORE_SERVICE_ACCOUNT` | Full JSON content of Google Play service account key | Google Play Console → Setup → API access → Service account → JSON key |

### Gmail App Password setup (one-time)

1. Enable 2-Step Verification on the Gmail account if not already enabled
2. Go to [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)
3. Create app password named "Flutter CI"
4. Copy the 16-character password → use as `MAIL_APP_PASSWORD`

### Google Play Service Account setup (one-time)

1. Google Play Console → Setup → API access
2. Link or create a Google Cloud project
3. Create new service account → name: `github-ci`
4. In Google Cloud Console → find service account → Manage keys → Add key → JSON → download
5. Back in Play Console → API access → find service account → Grant access
6. App permissions → select NotesApp → Release manager → Invite → Send
7. Paste entire JSON file content as `PLAY_STORE_SERVICE_ACCOUNT` secret

---

## Email Notifications

### Provider
- Gmail via SMTP (`smtp.gmail.com:587`)
- Uses App Password authentication (not OAuth)

### `deploy-test` email
- **Subject:** `✅ Test Build Ready — <commit-sha>`
- **Body:** Commit hash, branch, download button linking to GitHub Release
- **Recipients:** All addresses in `TESTER_EMAILS`
- **Sent from:** Local machine (as part of the PowerShell script, or via a lightweight GitHub Actions workflow triggered after upload)

### `deploy-prod` email
- **Subject:** `🚀 Live on Play Store — <commit-sha>`
- **Body:** Commit hash, release notes
- **Recipients:** All addresses in `TESTER_EMAILS`
- **Sent from:** GitHub Actions workflow

### Tester install flow (no extra apps)
1. Tester receives email on phone
2. Taps download button → opens GitHub Release in Chrome
3. Downloads APK → taps downloaded file
4. Android prompts install → one tap to confirm
5. **One-time setup:** tester must allow Chrome to install unknown apps (Settings → Install unknown apps → Chrome → Allow)

---

## Shell Environment

### Platform
- Windows + PowerShell
- Script file: `flutter_ci.ps1` (location TBD by developer)
- Sourced from `$PROFILE`

### Commands registered
| Command | Action |
|---|---|
| `deploy-test` | Local APK build → ADB install → git push → GitHub Release → email |
| `deploy-prod` | Warning → confirm → git push → GitHub Actions → Play Store → email |

### Requirements on developer machine
- Flutter SDK installed and on PATH
- Git installed and configured
- ADB installed and on PATH
- PowerShell 5.1+ or PowerShell 7+
- GitHub Personal Access Token with `repo` and `workflow` scopes

---

## Files to Create

| File | Purpose |
|---|---|
| `.github/workflows/deploy_prod.yml` | GitHub Actions workflow for production release |
| `flutter_ci.ps1` | PowerShell script with `deploy-test` and `deploy-prod` functions |

## Files to Modify

| File | Change |
|---|---|
| `android/app/build.gradle.kts` | Add product flavors (`production`, `rc`), dual signing support (local + CI) |
| `android/app/src/rc/res/` | RC-specific launcher icon and app label |

## Files NOT to Touch

| File | Reason |
|---|---|
| `key.properties` | Existing local signing — must remain untouched |
| `upload-keystore.jks` | Existing keystore — must remain untouched |
| Existing build types (`debug`, `release`, `profile`) | Already configured — must remain untouched |

---

## Deferred Items

| Item | Status |
|---|---|
| `ReleaseNotes.txt` file integration | Deferred — currently release notes are typed at `deploy-prod` prompt time |
| RC icon tint color | Icon file provided (`launcher_release_candidate.png`), tint to be specified by developer |

---

## Constraints

- The repo is **public** (read-only license, not open source) — no sensitive data in committed files
- Tester emails are stored in GitHub Secrets for privacy
- RC builds never go to the Play Store
- Production builds always go to 100% rollout (no staged rollout)
- `deploy-test` email notification is sent to ALL testers regardless of ADB status
- The existing `build.gradle.kts` signing config must continue working locally without any changes to the developer's current workflow