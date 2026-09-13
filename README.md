# Quran App – Spotify-like Quran Murattal Player

Aplikasi Flutter untuk mendengarkan murattal Quran dengan backsound alam (hujan, burung, angin, dll) seperti Spotify.

## Fitur

- Pilih Qari (pembaca Quran) dari API MP3Quran
- Daftar 114 surah dengan info lengkap
- Backsound alam (rain, ocean, wind, birds, night, fireplace) – bisa dikombinasikan
- Player screen dengan kontrol play/pause, seek, forward/backward
- Dark theme Spotify-style
- Multi-tab interface (Surah, Qari, Backsound)
- Background audio playback dengan just_audio
- Online audio streaming

## Teknologi

- Flutter 3.x
- Dart
- Provider (state management)
- just_audio (audio playback)
- http (API client)
- Material Design 3

## API yang Digunakan

- Surah data: https://api.alquran.cloud/v1
- Qari list: https://mp3quran.net/api/v3/reciters
- Audio files: server MP3Quran
- Backsound audio: SoundJay (public domain)

## Build APK

### Dengan Flutter CLI

```bash
flutter build apk --release
```

### Dengan Codemagic CI/CD

Repo ini sudah include `codemagic.yaml` untuk build otomatis di Codemagic.

## Screenshots

![Home Screen](screenshots/home.png)
![Player Screen](screenshots/player.png)

## Instalasi

1. Clone repo:
   ```bash
   git clone https://github.com/ululazq/quran-app.git
   cd quran-app
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Run di emulator/device:
   ```bash
   flutter run
   ```

4. Build APK:
   ```bash
   flutter build apk --release
   ```

## Kontribusi

Pull request welcome. Pastikan format code mengikuti pedoman Flutter.

## Lisensi

MIT