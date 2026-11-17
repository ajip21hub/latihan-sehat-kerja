# Rencana latihan: layanan kesehatan dan dana hari tua

Aplikasi ini latihan, bukan BPJS dan tidak terhubung ke sistem pemerintah. Angka, kelas, dan lama proses adalah contoh supaya alurnya bisa dipelajari.

Dua program resmi yang sering tertukar:

| Program | Yang dilihat peserta | Di aplikasi ini |
|---|---|---|
| BPJS Kesehatan (JKN) | Data peserta, kelas rawat 1/2/3, faskes, pelayanan | Profil, golongan layanan, pengajuan layanan |
| BPJS Ketenagakerjaan | Saldo JHT, lalu klaim bila syaratnya terpenuhi | Halaman Dana dan pengajuan ambil |

JHT (Jaminan Hari Tua) bukan dana pensiun bulanan. Jaminan Pensiun (JP) itu manfaat bulanan dan tidak dibuat di versi ini. Saldo yang ditampilkan adalah tabungan JHT: iuran peserta + iuran pemberi kerja + pengembangan.

Dari kanal publik (bukan salinan peraturan): pengambilan sebagian 10% untuk peserta yang masih aktif umumnya mensyaratkan kepesertaan minimal 10 tahun. Ada juga jalur 30% untuk kepemilikan rumah. Pencairan seluruh saldo punya syarat sendiri, misalnya usia 56, berhenti, atau PHK, plus dokumen. Perkiraan 1 hari kerja di bawah Rp10 juta dan 5 hari kerja di atasnya hanya label belajar.

## Versi simple ini memakai Hari 1–2

| Materi | Dipakai di |
|---|---|
| Feature-first (Hari 1) | `features/peserta`, `features/layanan`, `features/dana` |
| Use case murni (Hari 1) | `AjukanPencairan` di `features/dana/domain/ajukan_pencairan.dart` |
| Status tertutup, `switch` (Hari 1) | `StatusPengajuan`, `HasilAjuan` |
| `Notifier` (Hari 1) | `SesiController`, `LayananController`, `DanaController` |
| go_router + guard (Hari 2) | `lib/router/auth_redirect.dart`, splash, `?from=`, bottom nav |
| Sesi tidak memanggil `context.go` (Hari 2) | Login hanya mengisi `sesiProvider`. Router yang pindah halaman |
| Dio + refresh antrean (Hari 2) | `lib/core/network/auth_interceptor.dart`, `POST /auth/refresh` |
| Sesi dari cache (Hari 2) | `SehatRepository.pulihkan`, banner di Beranda dan Profil |
| `SessionExpired` (Hari 2) | core membunyikan bel, `SesiController` yang logout |
| dart-define (Hari 2) | `config/dev.json`, `config/android.json`, `Env` |
| Pinning (Hari 2) | stub/io, sengaja mati karena backend HTTP |
| Log tanpa token (Hari 2) | `redactSecrets` |
| Debounce cari (Hari 2) | `saringanLayananProvider`, filter lokal |

## Akun latihan

| Nomor | Sandi | Kelas | Kepesertaan | Saldo JHT |
|---|---|---|---|---|
| 0001 | belajar | Kelas 2, Klinik Melati | 11 tahun | Rp12.500.000 |
| 0002 | belajar | Kelas 3, Puskesmas Dahlia | 4 tahun | Rp3.200.000 |

`0001` boleh ajukan 10%. `0002` ditolak karena belum 10 tahun.

## Alur

1. Masuk.
2. Beranda menampilkan kelas rawat dan saldo.
3. Layanan: lihat riwayat, ajukan rawat jalan atau rawat inap. Status awal `Diajukan`.
4. Dana: lihat pecahan saldo, ajukan 10% atau seluruhnya. Use case yang memutuskan, bukan halaman.
5. Profil: NIK disamarkan. Keluar.

## Siap untuk Hari 3

Yang sudah ada, supaya besok tinggal menyambung:

- `GET /v1/snapshot` dan `POST /v1/outbox` dipanggil saat online.
- JSON snapshot di secure storage (`cached_snapshot`). Besok diganti tabel drift, UI tidak perlu tahu.
- `saldo_berubah` dan `nominal_berubah` melempar gagal lalu mencoba muat ulang. Tidak ada baris yang ditandai synced.
- `clientId` ikut di setiap operasi. Server menolak dobel dengan `alreadyApplied`.
- Kalau kirim gagal karena jaringan, UI menampilkan `Hari3.belumTerkirim` di `lib/core/sync/hari3.dart`. Antrean belum disimpan.
- WebSocket `GET /v1/stream` sudah ada di backend. Klien belum menyambung.
- workmanager belum dipasang.

## Sengaja belum dibuat

- Menyimpan pengajuan saat offline dan menyinkronkan nanti (Hari 3, lihat di atas).
- Status pengajuan yang berubah dari server lewat WebSocket (Hari 3).
- Unggah KTP, swafoto, dan verifikasi wajah.
- Kelas rawat yang naik-turun, iuran, dan rujukan faskes.
- Jaminan Pensiun bulanan, JKK, dan JKM.
- Rekening tujuan dan pencairan sungguhan.

## Tes

```bash
cd latihan-sehat-kerja
flutter test
```

`test/ajukan_pencairan_test.dart` mengunci aturan 10 tahun, nominal 10%, dan perkiraan hari kerja.
