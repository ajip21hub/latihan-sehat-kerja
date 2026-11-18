# Latihan SehatKerja

Aplikasi belajar Hari 1–3: data peserta, kelas layanan, pengajuan layanan kesehatan, saldo JHT, dan pengajuan pengambilan dana. Jaringan memakai backend lokal (Dio, refresh token, sesi dari cache). Pengajuan offline masuk antrean drift, dikirim lagi saat aplikasi terbuka, dan di Android juga lewat WorkManager. Status pengajuan mengikuti WebSocket backend.

Bukan aplikasi BPJS. Rencana dan batasannya ada di [RENCANA.md](RENCANA.md).

Jalankan backend dulu, lalu aplikasi. Proses yang sudah jalan sebelum perubahan ini perlu di-restart.

```bash
cd latihan-sehat-kerja
dart run backend/server.dart --self-check
dart run backend/server.dart
```

```bash
flutter pub get
flutter test
flutter run --dart-define-from-file=config/dev.json
```

Emulator Android memakai `config/android.json` (`http://10.0.2.2:8787`). Desktop, Chrome, dan simulator iOS memakai `http://127.0.0.1:8787`.

Chrome memakai `web/sqlite3.wasm` dan `web/drift_worker.js` (drift 2.35.4). Tanpa keduanya database lokal tidak terbuka dan tombol masuk tetap di "Memeriksa...". Setelah mengubah kode ini, tekan `R` di terminal `flutter run`.

Masuk dengan `0001` / `belajar` atau `0002` / `belajar`.
