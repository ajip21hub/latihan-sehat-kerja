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
| **`cd-android.yml`** | Tag `v*` (contoh: `v1.0.0`) atau manual (*workflow_dispatch*) | Menjalankan `ci.yml` sebagai gerbang, lalu: injeksi Firebase config dan keystore, generate `config/prod.json` (wajib HTTPS), build APK (`--split-per-abi`) dan AAB dengan `--obfuscate`, verifikasi tanda tangan (APK dan AAB tidak boleh debug key), upload artifact, debug symbols, dan mapping R8, publikasi ke GitHub Release (khusus tag).<br>**publish-play:** upload AAB ke track Google Play (internal/alpha/beta/production). Hanya berjalan jika track dipilih; lihat bagian 5. |

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
3. Klik **Run workflow**, pilih target (`apk`, `appbundle`, atau `both`), track Play (`none` = tidak publish), dan status rilis, lalu **Run workflow**.

Hasil manual tersedia sebagai artifact (dan di Play jika track dipilih); GitHub Release hanya dibuat dari tag.

Versi aplikasi diatur otomatis:
- `versionName`: dari tag (`v1.2.3` menjadi `1.2.3`). Tag yang bukan semver ditolak. Run manual memakai versi di `pubspec.yaml`.
- `versionCode`: nomor run workflow `cd-android` (`github.run_number`) ditambah `vars.VERSION_CODE_OFFSET`. Angka ini selalu naik, sesuai syarat Play. Angka `+N` di `pubspec.yaml` tidak dipakai untuk build rilis.

### C. Debug symbols
Build memakai `--obfuscate`, sehingga stack trace crash tidak terbaca tanpa symbols. Unduh artifact `debug-symbols` (disimpan 90 hari) dan jalankan:
```bash
flutter symbolize -i stack_trace.txt -d debug-symbols/app.android-arm64.symbols
```

---

## 5. Publish ke Google Play

Job `publish-play` meng-upload AAB lewat Google Play Developer API (action `r0adkll/upload-google-play`).

### Persiapan sekali saja
1. **Buat aplikasi di Play Console** dengan package `id.pelatihan.belajar.sehat_kerja`.
2. **Upload AAB pertama secara manual** lewat Play Console (misalnya ke track Internal testing). API tidak bisa membuat rilis pertama. Ambil AAB dari artifact `release-appbundle` hasil run manual. Saat itu aktifkan **Play App Signing**; keystore di secret menjadi *upload key*.
3. **Buat service account:**
   - Google Cloud Console > proyek yang terhubung ke Play Console > aktifkan **Google Play Android Developer API**.
   - IAM > Service Accounts > buat akun baru > Keys > **Add key** > JSON. Simpan file JSON-nya.
   - Play Console > **Users and permissions** > **Invite new users** > masukkan email service account > beri akses ke aplikasi ini dengan izin *Release apps to testing tracks* (tambah *Release to production* jika perlu).
4. **Isi secret** `PLAY_SERVICE_ACCOUNT_JSON` dengan isi file JSON tadi (teks apa adanya, bukan Base64). Setelah itu hapus file JSON dari laptop.

### Variables tambahan

| Nama | Wajib | Isi |
| :--- | :--- | :--- |
| `PLAY_TRACK` | Tidak | Track tujuan saat push tag: `internal`, `alpha`, `beta`, atau `production`. Kosong atau `none` = tag tidak publish ke Play. |
| `PLAY_RELEASE_STATUS` | Tidak | `completed` (default) atau `draft`. Pakai `draft` selama aplikasi masih berstatus draft di Play Console, karena API menolak status lain pada aplikasi draft. |
| `VERSION_CODE_OFFSET` | Tidak | Ditambahkan ke `versionCode`. Isi jika pernah upload manual dengan `versionCode` lebih besar dari nomor run (misalnya `100`). |

### Pengaman rilis produksi
Job publish memakai environment `play-<track>` (contoh: `play-internal`, `play-production`), yang dibuat otomatis saat pertama dipakai. Buka **Settings > Environments > play-production**, tambahkan **Required reviewers**, sehingga rilis ke produksi harus disetujui dulu sebelum di-upload.

### Catatan rilis (opsional)
Buat folder `distribution/whatsnew/` berisi file per bahasa, misalnya `whatsnew-id-ID` dan `whatsnew-en-US` (maksimal 500 karakter). Jika folder ada, isinya dikirim sebagai catatan rilis di Play.

### Alur yang disarankan
1. Set `PLAY_TRACK=internal`. Setiap tag `v*` otomatis masuk Internal testing.
2. Setelah diuji, promosikan rilis ke produksi dari Play Console, atau jalankan workflow manual dengan `play_track=production` (perlu persetujuan reviewer).

---

## 6. Konfigurasi Signing di Proyek Lokal

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
