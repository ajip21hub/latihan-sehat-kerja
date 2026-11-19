# Panduan Implementasi CI/CD - SehatKerja (Android)

Dokumen ini menjelaskan alur kerja (*pipeline*) Continuous Integration (CI) dan Continuous Deployment (CD) Android yang diimplementasikan dengan **GitHub Actions**.

> **Catatan repositori:** folder ini adalah subtree dari repo pelatihan. GitHub hanya membaca `.github/workflows/` di root repositori, sehingga workflow ini berjalan di repo `latihan-sehat-kerja`, bukan di repo induk. Kirim perubahan dengan:
>
> ```bash
> git subtree push --prefix latihan-sehat-kerja repo-latihan-sehat-kerja master
> ```

---

## 1. Arsitektur Workflow

| Workflow File | Trigger | Tugas Utama |
| :--- | :--- | :--- |
| **`ci.yml`** | Push dan PR ke `main`, `master`, `develop`; juga dipanggil oleh `cd-android.yml` | Tiga job berjalan paralel:<br>**test:** `pub get --enforce-lockfile` (lockfile wajib cocok dengan `pubspec.yaml`), format (`dart format`), analisis ketat (`flutter analyze --fatal-infos --fatal-warnings`), backend self-check, validasi codegen drift (`build_runner` + `git diff`), test dengan coverage minimum `MIN_COVERAGE` (default 50%, tanpa file generated; angka tampil di ringkasan run).<br>**build-android:** build APK debug dengan config Firebase placeholder untuk memastikan proyek Android masih bisa di-compile. APK di-upload sebagai artifact `debug-apk` (7 hari) agar reviewer bisa mencoba. Job ini dilewati saat dipanggil dari `cd-android.yml`.<br>**security:** secret scan (gitleaks), audit dependensi (OSV, `pubspec.lock`), larangan file rahasia ter-commit, cek manifest release HTTPS-only dan tidak `debuggable`. |
| **`cd-android.yml`** | Tag `v*` (contoh: `v1.0.0`) atau manual (*workflow_dispatch*) | Menjalankan `ci.yml` sebagai gerbang, lalu: injeksi Firebase config dan keystore, generate `config/prod.json` (wajib HTTPS), build APK (`--split-per-abi`) dan AAB dengan `--obfuscate`, verifikasi tanda tangan (APK dan AAB tidak boleh debug key), upload artifact dan debug symbols, publikasi ke GitHub Release (khusus tag). |

---

## 2. Secrets dan Variables

Masuk ke **Settings** repositori > **Secrets and variables** > **Actions**.

### Secrets (tab *Secrets*), semuanya wajib

Jika salah satu kosong, `cd-android.yml` langsung gagal. Tidak ada fallback ke debug keystore di CI.

| Nama | Isi |
| :--- | :--- |
| `ANDROID_KEYSTORE_BASE64` | Base64 dari file keystore release (`.jks`). |
| `KEYSTORE_PASSWORD` | Password keystore. |
| `KEY_ALIAS` | Alias kunci di dalam keystore. |
| `KEY_PASSWORD` | Password alias kunci. |
| `GOOGLE_SERVICES_JSON_BASE64` | Base64 dari `android/app/google-services.json` produksi. |
| `FIREBASE_OPTIONS_DART_BASE64` | Base64 dari `lib/firebase_options.dart` produksi (hasil `flutterfire configure`). |

### Variables (tab *Variables*)

| Nama | Wajib | Isi |
| :--- | :--- | :--- |
| `API_BASE_URL` | Ya | Alamat API produksi. Harus diawali `https://`; selain itu build gagal. |
| `CERT_SHA256_PINS` | Tidak | Pin SHA-256 sertifikat server untuk certificate pinning. Kosongkan jika belum dipakai. |

---

## 3. Membuat Keystore dan Mengisi Secret

### Langkah 1: Buat keystore baru
```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias sehat-kerja-key
```
Catat password dan alias yang dimasukkan. Simpan keystore di luar repositori; kehilangan keystore berarti tidak bisa memperbarui aplikasi di Play Store.

### Langkah 2: Encode file ke Base64
Lakukan untuk `upload-keystore.jks`, `google-services.json`, dan `firebase_options.dart`.

- **macOS:**
  ```bash
  base64 -i upload-keystore.jks | pbcopy
  ```
- **Linux:**
  ```bash
  base64 -w 0 upload-keystore.jks
  ```
- **Windows (PowerShell):**
  ```powershell
  [Convert]::ToBase64String([IO.File]::ReadAllBytes("upload-keystore.jks")) | Set-Clipboard
  ```

Tempel hasilnya ke secret yang sesuai.

---

## 4. Menjalankan Pipeline

### A. CI (otomatis)
Buat branch baru, commit, lalu buka **Pull Request** ke `master`. CI berjalan otomatis.

Verifikasi lokal sebelum push (urutan sama dengan CI):
```bash
flutter pub get --enforce-lockfile
dart format --output=none --set-exit-if-changed lib test backend
flutter analyze --fatal-infos --fatal-warnings
dart run backend/server.dart --self-check
dart run build_runner build --delete-conflicting-outputs
git diff --exit-code lib/   # hasil codegen harus sudah ter-commit
flutter test --coverage
flutter build apk --debug --dart-define-from-file=config/android.json
```

Batas coverage diatur lewat `MIN_COVERAGE` di bagian `env` pada `ci.yml`. Naikkan bertahap seiring bertambahnya test; jangan turunkan untuk meloloskan PR.

### B. CD (rilis versi baru)

#### Cara 1: Git tag (direkomendasikan)
```bash
git tag v1.0.0
git push repo-latihan-sehat-kerja v1.0.0
```
`cd-android.yml` menjalankan CI, membuild APK dan AAB, lalu membuat rilis di tab **Releases** lengkap dengan file APK dan AAB.

#### Cara 2: Manual (*workflow_dispatch*)
1. Buka tab **Actions**.
2. Pilih **CD Android (Release Build)**.
3. Klik **Run workflow**, pilih target (`apk`, `appbundle`, atau `both`), lalu **Run workflow**.

Hasil manual hanya tersedia sebagai artifact; GitHub Release hanya dibuat dari tag.

### C. Debug symbols
Build memakai `--obfuscate`, sehingga stack trace crash tidak terbaca tanpa symbols. Unduh artifact `debug-symbols` (disimpan 90 hari) dan jalankan:
```bash
flutter symbolize -i stack_trace.txt -d debug-symbols/app.android-arm64.symbols
```

---

## 5. Konfigurasi Signing di Proyek Lokal

`android/app/build.gradle.kts`:
1. Membaca `android/key.properties` jika tersedia.
2. Jika file tersebut atau keystore tidak ada, build release lokal tetap jalan dengan kunci *debug* dan Gradle mencetak **PERINGATAN**. Hasil build seperti ini hanya untuk latihan, tidak boleh dirilis.
3. Di CI, fallback ini tidak pernah terpakai: workflow gagal jika secret keystore kosong, dan langkah verifikasi menolak APK/AAB bertanda tangan debug.
4. `key.properties`, `*.jks`, `google-services.json`, dan `firebase_options.dart` ada di `.gitignore`. Job security di CI juga gagal jika file tersebut ter-commit.

Contoh `android/key.properties`:
```properties
storePassword=...
keyPassword=...
keyAlias=sehat-kerja-key
storeFile=upload-keystore.jks
```
`storeFile` relatif terhadap folder `android/app/`.
