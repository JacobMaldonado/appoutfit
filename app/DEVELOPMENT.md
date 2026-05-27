# Clo·set — Development Guide

This guide covers running the app on emulators/simulators and building signed release binaries for Android and iOS.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Running on Emulator / Simulator](#running-on-emulator--simulator)
   - [List available devices](#list-available-devices)
   - [Local environment (full mocks)](#local-environment-full-mocks)
   - [Dev environment (Firebase dev project)](#dev-environment-firebase-dev-project)
   - [Prod environment (Firebase prod project)](#prod-environment-firebase-prod-project)
3. [Building & Signing for Android](#building--signing-for-android)
   - [Create a signing keystore](#create-a-signing-keystore)
   - [Configure key.properties](#configure-keyproperties)
   - [Configure build.gradle.kts](#configure-buildgradlekts)
   - [Build release binaries](#build-release-binaries)
   - [Publish to Google Play](#publish-to-google-play)
4. [Building & Signing for iOS](#building--signing-for-ios)
   - [Apple Developer prerequisites](#apple-developer-prerequisites)
   - [Configure signing in Xcode](#configure-signing-in-xcode)
   - [Build & archive](#build--archive)
   - [Export IPA](#export-ipa)
   - [Publish to App Store](#publish-to-app-store)
5. [Firebase Setup (dev / prod)](#firebase-setup-dev--prod)

---

## Prerequisites

| Tool | Minimum version | Install |
|---|---|---|
| Flutter SDK | 3.22+ | https://docs.flutter.dev/get-started/install |
| Dart SDK | bundled with Flutter | — |
| Android Studio | Ladybug 2024.2+ | https://developer.android.com/studio |
| Xcode | 15+ (macOS only) | Mac App Store |
| CocoaPods | 1.14+ | `sudo gem install cocoapods` |
| Java (JDK) | 17+ | `brew install --cask temurin` |

Verify your Flutter installation:
```bash
flutter doctor -v
```
All items should show a green ✓ before running.

---

## Running on Emulator / Simulator

### List available devices

```bash
flutter devices
```

Example output:
```
sdk gphone64 x86 64 (mobile) • emulator-5554    • android-x64 • Android 14 (API 34)
iPhone 15 Pro (simulator)    • 00008130-000...  • ios         • iOS 17.5
```

To start an Android emulator from the command line:
```bash
# List available AVDs
emulator -list-avds

# Launch one
emulator -avd Pixel_8_API_34
```

To start an iOS Simulator:
```bash
open -a Simulator
# or pick a specific device:
xcrun simctl boot "iPhone 15 Pro"
```

---

### Local environment (full mocks)

**No Firebase, no network calls.** All data lives in memory. Best for fast UI iteration and testing on a fresh machine.

```bash
cd app

# Default device (first available)
flutter run -t lib/main_local.dart

# Specific device
flutter run -t lib/main_local.dart -d emulator-5554       # Android emulator
flutter run -t lib/main_local.dart -d "iPhone 15 Pro"     # iOS Simulator
```

A mock user (`demo@closetapp.com`) is signed in automatically — no login screen.

Hot-reload shortcut: press **r** in the terminal. Hot-restart: **R**.

---

### Dev environment (Firebase dev project)

Connects to your Firebase **dev** project. Requires `GoogleService-Info.plist` (iOS) and `google-services.json` (Android) from the dev project.

**Before first run:**
```bash
# Place Firebase config files:
cp ~/Downloads/google-services.json   app/android/app/google-services.json
cp ~/Downloads/GoogleService-Info.plist  app/ios/Runner/GoogleService-Info.plist

# Install iOS pods
cd app/ios && pod install && cd ..
```

```bash
cd app

flutter run -t lib/main_dev.dart

# Specific device
flutter run -t lib/main_dev.dart -d emulator-5554
flutter run -t lib/main_dev.dart -d "iPhone 15 Pro"
```

---

### Prod environment (Firebase prod project)

Same as dev but points to the **production** Firebase project. Use this only for final validation before release — avoid generating test data in prod.

```bash
# Swap in prod Firebase config files first (same paths as dev)
cd app

flutter run -t lib/main_prod.dart

flutter run -t lib/main_prod.dart -d emulator-5554
flutter run -t lib/main_prod.dart -d "iPhone 15 Pro"
```

> **Tip:** Run `flutter run --profile -t lib/main_prod.dart` to test prod-like performance (optimized build, DevTools profiling still available).

---

## Building & Signing for Android

### Create a signing keystore

Generate a keystore once and store it **outside the repository**:

```bash
keytool -genkey -v \
  -keystore ~/keys/closet-upload.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias upload
```

You will be prompted for:
- **keystore password** — remember this
- **key password** — can be the same as keystore password
- **DN fields** (name, org, country) — used in the certificate

---

### Configure key.properties

Copy the example and fill in your values:

```bash
cp app/android/key.properties.example app/android/key.properties
```

Edit `app/android/key.properties` (this file is gitignored):
```properties
storePassword=<your keystore password>
keyPassword=<your key password>
keyAlias=upload
storeFile=/Users/<you>/keys/closet-upload.jks
```

---

### Configure build.gradle.kts

`app/android/app/build.gradle.kts` must load `key.properties` and apply the signing config to the release build type. Add the following blocks if not already present:

```kotlin
import java.util.Properties

val keyProperties = Properties()
val keyPropertiesFile = rootProject.file("key.properties")
if (keyPropertiesFile.exists()) {
    keyPropertiesFile.inputStream().use { keyProperties.load(it) }
}

android {
    // ... existing config ...

    signingConfigs {
        create("release") {
            keyAlias     = keyProperties["keyAlias"] as String
            keyPassword  = keyProperties["keyPassword"] as String
            storeFile    = file(keyProperties["storeFile"] as String)
            storePassword = keyProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
```

---

### Build release binaries

```bash
cd app

# Release APK (direct install / side-loading)
flutter build apk --release -t lib/main_prod.dart

# Release App Bundle (required by Google Play)
flutter build appbundle --release -t lib/main_prod.dart
```

Output locations:
```
build/app/outputs/flutter-apk/app-release.apk
build/app/outputs/bundle/release/app-release.aab
```

Verify the APK is signed:
```bash
apksigner verify --verbose build/app/outputs/flutter-apk/app-release.apk
```

Test the release APK on a connected device before uploading:
```bash
flutter install --release    # installs app-release.apk on connected device
```

---

### Publish to Google Play

1. In [Google Play Console](https://play.google.com/console), create a new app.
2. Go to **Release → Production → Create new release**.
3. Upload `app-release.aab`.
4. Fill in release notes, review rollout percentage, and submit for review.

> Use **Internal testing** and **Closed testing** tracks first; promote to Production once validated.

---

## Building & Signing for iOS

### Apple Developer prerequisites

You need:
- **Apple Developer account** (paid, $99/year) — https://developer.apple.com
- An **App ID** registered at https://developer.apple.com/account/resources/identifiers
  - Bundle ID: `com.closetapp.closet`
  - Capabilities: Sign In with Apple, Push Notifications (if needed)
- **Distribution certificate** — "Apple Distribution" type, created in Keychain Access or Xcode
- **Provisioning profile** — "App Store Distribution" linked to your App ID and certificate

Xcode can manage all of this automatically if you enable **"Automatically manage signing"** (see below).

---

### Configure signing in Xcode

```bash
cd app
open ios/Runner.xcworkspace   # always open the .xcworkspace, not .xcodeproj
```

In Xcode:
1. Select the **Runner** target → **Signing & Capabilities** tab.
2. Set **Team** to your Apple Developer team.
3. Enable **Automatically manage signing** for the simplest workflow.
   - Xcode will create/refresh certificates and provisioning profiles on demand.
4. Verify **Bundle Identifier** is `com.closetapp.closet`.

For manual signing (CI / advanced):
- Import your `.p12` distribution certificate into the Keychain.
- Download the provisioning profile from Apple Developer Portal and double-click to install.
- In Xcode, disable "Automatically manage signing" and select the profile manually.
- Copy `ios/ExportOptions.plist.example` to `ios/ExportOptions.plist` and fill in your Team ID and profile name.

---

### Build & archive

```bash
cd app

# Build the iOS release archive
flutter build ipa --release -t lib/main_prod.dart
```

This runs `xcodebuild archive` internally and produces:
```
build/ios/archive/Runner.xcarchive
build/ios/ipa/Runner.ipa   # if export options are configured
```

For explicit export options (CI use):
```bash
flutter build ipa --release \
  -t lib/main_prod.dart \
  --export-options-plist ios/ExportOptions.plist
```

---

### Export IPA

If `flutter build ipa` did not export automatically, export from Xcode Organizer:

1. **Window → Organizer → Archives**.
2. Select the archive → **Distribute App**.
3. Choose **App Store Connect** → **Upload** (or **Export** for manual upload).
4. Follow the wizard; Xcode re-signs with the distribution profile.

---

### Publish to App Store

**Option A — Xcode Organizer (easiest):**
After the export wizard, choose **Upload** directly in the Organizer.

**Option B — Transporter:**
```bash
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/Runner.ipa \
  --apiKey <KEY_ID> \
  --apiIssuer <ISSUER_ID>
```

**Option C — App Store Connect web:**
1. Open https://appstoreconnect.apple.com
2. **Apps → + New App** (if not already created).
3. Under **TestFlight**, upload the IPA via drag-and-drop.
4. Once processed, promote to **App Store → Submit for Review**.

> **First submission checklist:** screenshots for all required device sizes, App Privacy details, age rating, and content description must be filled before submission.

---

## Firebase Setup (dev / prod)

Both `dev` and `prod` environments need their own Firebase project. Local (`main_local.dart`) does not require Firebase at all.

**One-time setup per environment:**

```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure (run once per project, generates lib/firebase_options.dart)
# Run this from the app/ directory
flutterfire configure \
  --project=closet-app-dev \      # or closet-app-prod
  --out=lib/firebase_options_dev.dart
```

> The generated `firebase_options.dart` is gitignored. Each developer or CI runner must run `flutterfire configure` or have the file provided as a secret.

**Required Firebase services per project:**

| Service | Enable in Console |
|---|---|
| Authentication | Email/Password · Google · Sign in with Apple |
| Firestore | Create database in production mode; deploy `firebase/firestore.rules` |
| Storage | Default bucket; deploy `firebase/storage.rules` |

Deploy rules:
```bash
# Install Firebase CLI if needed
npm install -g firebase-tools
firebase login

# Deploy Firestore + Storage rules
firebase deploy --only firestore:rules,storage --project closet-app-dev
firebase deploy --only firestore:rules,storage --project closet-app-prod
```
