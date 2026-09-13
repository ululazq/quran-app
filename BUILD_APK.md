# Build APK for Quran App

## Prerequisites

1. Install Flutter SDK (https://flutter.dev/docs/get-started/install)
2. Install Android Studio + Android SDK (API level >= 21)
3. Set environment variables:
   - `ANDROID_HOME` pointing to Android SDK path
   - Add `flutter/bin` to PATH

## Steps

### 1. Generate platform files

If the `android/` directory is incomplete, run:

```bash
flutter create .
```

This will generate missing Android/iOS files while preserving your existing code.

### 2. Configure app

Edit `android/app/build.gradle`:

- Ensure `minSdkVersion` is at least 21.
- Set `targetSdkVersion` to latest (e.g., 34).
- Update `versionCode` and `versionName` as needed.

### 3. Build APK

```bash
flutter build apk --release
```

The APK will be at `build/app/outputs/flutter-apk/app-release.apk`.

### 4. For smaller APK (split per ABI)

```bash
flutter build apk --release --split-per-abi
```

Outputs:
- `app-armeabi-v7a-release.apk`
- `app-arm64-v8a-release.apk`
- `app-x86_64-release.apk`

### 5. Install on device

```bash
flutter install
```

Or use adb:

```bash
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Notes

- Backsound uses online URLs (SoundJay). Ensure internet permission is in `AndroidManifest.xml` (already added by Flutter).
- If you want offline backsound, place MP3 files in `assets/audio/backsounds/` and update `backsound_model.dart`.

## Troubleshooting

### Flutter doctor issues

Run `flutter doctor` and resolve all issues (Android licenses, missing tools).

### Build fails due to missing Android SDK

Install Android SDK Command-line Tools via Android Studio SDK Manager.

### APK size large

Enable ProGuard/R8 in `android/app/build.gradle`:

```gradle
buildTypes {
    release {
        minifyEnabled true
        shrinkResources true
        proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
    }
}
```

## Deploy to Google Play

Follow Flutter's deployment guide: https://flutter.dev/docs/deployment/android