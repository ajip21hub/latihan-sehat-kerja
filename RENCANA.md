# Rencana latihan: layanan kesehatan dan dana hari tua

Aplikasi ini latihan, bukan BPJS dan tidak terhubung ke sistem pemerintah. Angka, kelas, dan lama proses adalah contoh supaya alurnya bisa dipelajari.

Dua program resmi yang sering tertukar:

| Program | Yang dilihat peserta | Di aplikasi ini |
|---|---|---|
| BPJS Kesehatan (JKN) | Data peserta, kelas rawat 1/2/3, faskes, pelayanan | Profil, golongan layanan, pengajuan layanan |
| BPJS Ketenagakerjaan | Saldo JHT, lalu klaim bila syaratnya terpenuhi | Halaman Dana dan pengajuan ambil |

JHT (Jaminan Hari Tua) bukan dana pensiun bulanan. Jaminan Pensiun (JP) itu manfaat bulanan dan tidak dibuat di versi ini. Saldo yang ditampilkan adalah tabungan JHT: iuran peserta + iuran pemberi kerja + pengembangan.

Dari kanal publik (bukan salinan peraturan): pengambilan sebagian 10% untuk peserta yang masih aktif umumnya mensyaratkan kepesertaan minimal 10 tahun. Ada juga jalur 30% untuk kepemilikan rumah. Pencairan seluruh saldo punya syarat sendiri, misalnya usia 56, berhenti, atau PHK, plus dokumen. Perkiraan 1 hari kerja di bawah Rp10 juta dan 5 hari kerja di atasnya hanya label belajar.

## Versi simple ini memakai Hari 1–3

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
| drift, network-first (Hari 3) | `snapshot_cache`. Jaringan gagal memakai baris ini, lalu JSON lama di secure storage |
| Outbox (Hari 3) | `outbox_rows`. Kirim offline langsung tersimpan, `synced = false` |
| Sidik / race (Hari 3) | `tandaiSynced` hanya jika payload yang dikirim masih sama |
| Konflik saldo (Hari 3) | `saldo_berubah` dan `nominal_berubah` tidak di-synced. `expectedSaldoTotal` (dan nominal) ditulis ulang |
| Penolakan (Hari 3) | `ditolak` dan `jenis` ditandai `batal`, tidak diulang |
| Antrean saat aplikasi terbuka | Banner “Kirim sekarang”, plus kirim lagi setelah sesi pulih |
| Background sync (Hari 3) | workmanager Android, kira-kira tiap 15 menit, hanya kalau ada jaringan |
| WebSocket (Hari 3) | `ws://<host>:8787/v1/stream?token=`, jeda sambung 1–15 detik |

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

## Offline-first dan background sync

Pengajuan tidak menunggu jawaban server sebelum muncul di layar. Barisnya masuk `outbox_rows` dulu. Kalau `POST /v1/outbox` putus, baris tetap `synced = false` dan pita “Kirim sekarang” muncul di Beranda, Layanan, dan Dana.

Saat jaringan ada, semua baris yang belum selesai dikirim sekaligus. Sukses atau `alreadyApplied` menandai synced hanya kalau sidik payload belum berubah. `saldo_berubah` dan `nominal_berubah` tetap antre, saldo di layar dimuat ulang, lalu angka di payload disesuaikan. `ditolak` dan `jenis` selesai.

Snapshot tetap bentuk `AppSnapshot`. Sumbernya tabel `snapshot_cache` (skema versi 2; migrasi dari versi 1 menambah kolom `batal`). JSON `cached_snapshot` hanya dibaca kalau tabel masih kosong, supaya sesi lama tidak hilang.

WorkManager berjalan di isolate sendiri, hanya Android, minimal 15 menit, dan hanya saat jaringan tersambung. Chrome, desktop, dan iOS mengirim antrean selagi aplikasi terbuka: saat sesi dipulihkan, saat “Cek sesi lagi”, dan lewat tombol. WebSocket status memakai `web_socket_channel` supaya jalan di web maupun VM. Sambungan putus dicoba lagi dengan jeda 1, 2, 4, 8, lalu 15 detik.

Enkripsi file SQLite (sqlite3mc) tidak dipasang. `connectivity_plus` juga tidak, karena di tes widget plugin-nya sering tidak ada.

## Sengaja belum dibuat

- Enkripsi database dan background sync iOS.
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
