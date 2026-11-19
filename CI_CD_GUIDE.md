# Panduan Implementasi CI/CD - SehatKerja

Dokumen ini menjelaskan alur kerja (*pipeline*) Continuous Integration (CI) dan Continuous Deployment (CD) yang telah diimplementasikan menggunakan **GitHub Actions**.

---

## 1. Arsitektur Workflow

Terdapat 3 workflow yang telah dikonfigurasi di dalam direktori `.github/workflows/`:

| Workflow File | Trigger | Tugas Utama |
| :--- | :--- | :--- |
| **`ci.yml`** | Push & PR ke branch `main`, `master`, `develop` | • Format check (`dart format`)<br>• Linter (`flutter analyze`)<br>• Backend self-check (`dart run backend/server.dart --self-check`)<br>• Validasi drift codegen (`build_runner`)<br>• Unit & Widget Tests (`flutter test --coverage`) |
| **`cd-android.yml`** | Tag `v*` (contoh: `v1.0.0`) atau Manual (*workflow_dispatch*) | • Injeksi keystore & `key.properties`<br>• Generate Drift code<br>• Build APK Release (`--split-per-abi`) & App Bundle (AAB)<br>• Publikasi ke GitHub Release & Upload Artifacts |
| **`cd-web.yml`** | Tag `v*` atau Manual (*workflow_dispatch*) | • Build Flutter Web release (termasuk `sqlite3.wasm` & `drift_worker.js`)<br>• Deploy otomatis ke GitHub Pages |

---

## 2. Persiapan GitHub Secrets (Android Release Signing)

Agar rilis Android ditandatangani (*signed*) menggunakan kunci rilis resmi Anda, tambahkan rahasia berikut di repositori GitHub Anda:

> Masuk ke: **Settings** repositori GitHub > **Secrets and variables** > **Actions** > **New repository secret**.

### Daftar Secrets:

1. **`ANDROID_KEYSTORE_BASE64`**
   - String Base64 dari file keystore (`.jks` / `.keystore`).
2. **`KEYSTORE_PASSWORD`**
   - Password untuk file keystore.
3. **`KEY_ALIAS`**
   - Nama alias kunci di dalam keystore.
4. **`KEY_PASSWORD`**
   - Password untuk alias kunci.
5. **`GOOGLE_SERVICES_JSON_BASE64`** *(Opsional)*
   - Isi file `android/app/google-services.json` yang di-encode ke Base64 (jika Firebase produksi digunakan).

> **Catatan:** Jika secret di atas belum diatur, pipeline `cd-android.yml` secara otomatis tetap berjalan menggunakan *debug keystore* sebagai fallback yang aman sehingga build tidak gagal.

---

## 3. Cara Membuat Keystore & Menyiapkan Secret

Jika Anda belum memiliki keystore rilis, jalankan langkah berikut di terminal lokal Anda:

### Langkah 1: Buat Keystore Baru
```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias sehat-kerja-key
```
*(Ingat password dan alias yang Anda masukkan).*

### Langkah 2: Encode Keystore ke Base64
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

Paste hasil tersebut ke dalam secret **`ANDROID_KEYSTORE_BASE64`**.

---

## 4. Cara Menjalankan Pipeline

### A. Menjalankan CI (Otomatis)
Cukup buat branch baru, lakukan commit, dan buka **Pull Request (PR)** ke branch `main`. GitHub Actions akan otomatis menjalankan pengujian.

Untuk memastikan CI lolos sebelum push, jalankan verifikasi lokal:
```bash
# 1. Format kode
dart format --set-exit-if-changed .

# 2. Analisis linting
flutter analyze

# 3. Generate drift & database
dart run build_runner build --delete-conflicting-outputs

# 4. Jalankan test
flutter test
```

### B. Menjalankan CD (Rilis Versi Baru)
Terdapat dua cara untuk memicu build release:

#### Cara 1: Menggunakan Git Tag (Direkomendasikan)
```bash
git tag v1.0.0
git push origin v1.0.0
```
Actions akan memicu `cd-android.yml` dan `cd-web.yml`, melakukan build, dan membuat rilis baru di tab **Releases** GitHub lengkap dengan file APK dan AAB siap download.

#### Cara 2: Manual Trigger (Workflow Dispatch)
1. Buka tab **Actions** di repositori GitHub.
2. Pilih workflow **CD Android (Release Build)** atau **CD Web (Build & Deploy)** di menu sebelah kiri.
3. Klik tombol **Run workflow**, pilih target build (`apk`, `appbundle`, atau `both`), lalu klik **Run workflow**.

---

## 5. Konfigurasi Signing di Proyek Lokal

File [build.gradle.kts](file:///Users/yuma/orca/projects/flutter-pelatihan-lanjutan/latihan-sehat-kerja/android/app/build.gradle.kts) sudah disesuaikan agar:
1. Membaca file `android/key.properties` jika tersedia.
2. Jika file tersebut tidak ditemukan atau file `.jks` belum ada, proses build otomatis beralih ke kunci *debug* (`signingConfigs.debug`).
3. File `key.properties` dan `*.jks` sudah dimasukkan ke [.gitignore](file:///Users/yuma/orca/projects/flutter-pelatihan-lanjutan/latihan-sehat-kerja/.gitignore) sehingga aman dan tidak akan ter-commit secara tidak sengaja ke git publik.
