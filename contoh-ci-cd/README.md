# Contoh CI/CD sampai Google Play

`playstore.yml` adalah contoh ringkas pipeline dari tag Git sampai aplikasi terunggah ke Google Play. File ini sengaja **tidak** diletakkan di `.github/workflows/`, sehingga tidak berjalan otomatis.

Versi lengkap yang dipakai proyek ini ada di `.github/workflows/cd-android.yml`. Di sana ada tambahan pengaman: verifikasi tanda tangan, pemeriksaan HTTPS, pilihan track lewat run manual, dan GitHub Release. Penjelasannya ada di `CI_CD_GUIDE.md`.

## Alur

```
git push tag v1.2.3
  -> job test   : pub get, analyze, test
  -> job deploy : pulihkan keystore + Firebase dari Secrets
                  -> build AAB (versionName 1.2.3, versionCode = nomor run)
                  -> upload ke Google Play, track Internal testing
```

## Persiapan sekali saja

1. **Keystore upload.** Buat dengan `keytool`, lalu encode ke Base64 (lihat `CI_CD_GUIDE.md` bagian 3).
2. **Aplikasi di Play Console.** Buat aplikasi dengan package `id.pelatihan.belajar.sehat_kerja`, lalu unggah AAB pertama **secara manual**. Google Play API tidak bisa membuat rilis pertama.
3. **Service account.** Aktifkan *Google Play Android Developer API* di Google Cloud, buat service account beserta key JSON, lalu undang email-nya di Play Console (*Users and permissions*) dengan izin merilis ke track testing.
4. **Secrets dan Variables.** Isi di *Settings > Secrets and variables > Actions*:

| Nama | Jenis | Isi |
| :--- | :--- | :--- |
| `ANDROID_KEYSTORE_BASE64` | Secret | Base64 dari `upload-keystore.jks` |
| `KEYSTORE_PASSWORD` | Secret | Password keystore |
| `KEY_ALIAS` | Secret | Alias kunci |
| `KEY_PASSWORD` | Secret | Password alias |
| `GOOGLE_SERVICES_JSON_BASE64` | Secret | Base64 dari `android/app/google-services.json` |
| `FIREBASE_OPTIONS_DART_BASE64` | Secret | Base64 dari `lib/firebase_options.dart` |
| `PLAY_SERVICE_ACCOUNT_JSON` | Secret | Isi file JSON service account (teks apa adanya) |
| `API_BASE_URL` | Variable | Alamat API produksi, diawali `https://` |

## Mengaktifkan

```bash
cp contoh-ci-cd/playstore.yml .github/workflows/playstore.yml
git add .github/workflows/playstore.yml
git commit -m "ci: deploy ke Play Store dari tag"
git push

git tag v1.0.0
git push origin v1.0.0
```

Pantau prosesnya di tab **Actions**. Setelah selesai, build muncul di Play Console > *Testing > Internal testing*.

## Hal yang sering membuat gagal

| Pesan error | Penyebab | Solusi |
| :--- | :--- | :--- |
| `Package not found` | Rilis pertama belum diunggah manual, atau service account belum diundang | Lakukan persiapan nomor 2 dan 3 |
| `Only releases with status draft may be created on draft app` | Aplikasi masih berstatus draft di Play Console | Ubah `status: completed` menjadi `status: draft` |
| `Version code N has already been used` | versionCode sama dengan rilis sebelumnya | Naikkan dengan `--build-number="$((GITHUB_RUN_NUMBER + 100))"` |
| `The Android App Bundle was signed with the wrong key` | Keystore di secret berbeda dengan *upload key* yang terdaftar | Pakai keystore yang sama dengan upload pertama |

## Catatan

Jangan aktifkan `playstore.yml` bersamaan dengan `cd-android.yml` yang track Play-nya sudah diisi. Keduanya terpicu oleh tag yang sama dan akan mencoba mengunggah dua kali.
