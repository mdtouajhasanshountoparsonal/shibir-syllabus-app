# Shibir Syllabus Tracker — Flutter starter

Offline-first starter scaffold. Content is intentionally sample/placeholder data, **not an official or verified syllabus**.

## Features in this scaffold
- Worker / Sathi / Member stage cards
- Offline starter content in `assets/content/`
- Optional GitHub-hosted JSON content refresh
- Reading checklist progress saved locally with SharedPreferences
- Book/reading detail view
- No login, admin panel, or server required

## Run on Kali Linux
```bash
cd shibir_syllabus_tracker
flutter pub get
flutter doctor
flutter run
```

Build APK:
```bash
flutter build apk --release
```
APK output:
`build/app/outputs/flutter-apk/app-release.apk`

## Add content through GitHub
1. Create a public GitHub repository, e.g. `shibir-syllabus-data`.
2. Upload `manifest.json` and `stages.json` from `assets/content/`.
3. In `lib/services/content_service.dart`, replace `githubManifestUrl` with the **raw.githubusercontent.com** URL to your manifest.
4. Keep the JSON structure valid. Commit changes to GitHub; the app can refresh content from the manifest when online.
5. Bundled asset content is used when offline or if the remote fetch fails.

Recommended repository layout:
```
shibir-syllabus-data/
  manifest.json
  stages.json
  books/
    example-book.json
  pdf/
    (optional PDFs you have permission to distribute)
  audio/
    (optional audio you have permission to distribute)
```

### Manifest format
```json
{
  "schemaVersion": 1,
  "contentVersion": "1.0.1",
  "stagesUrl": "https://raw.githubusercontent.com/USERNAME/REPO/main/stages.json",
  "updatedAt": "2026-10-13"
}
```
The `stagesUrl` must be a raw GitHub URL. Keep the same schema unless you also update the Dart model.

## Current content schema
- `stages[]`: `id`, `title`, `subtitle`, `description`, `items[]`
- Each item: `id`, `title`, `type`, `description`, `author`, `url`, `estimatedMinutes`
- `type`: `book`, `memorization`, `quran`, `hadith`, `video`, `audio`, `pdf`, `task`

## Important
- Replace sample data with a syllabus verified from an official publication/source.
- Only upload books, PDFs, translations, audio, or other files you have permission to distribute. For copyrighted books, store metadata and link to a lawful source rather than re-uploading the full book.
- This starter saves checklist completion on the current device. GitHub is a **public content source**, not private user-progress storage. Do not upload personal notes or private progress to a public repository.
