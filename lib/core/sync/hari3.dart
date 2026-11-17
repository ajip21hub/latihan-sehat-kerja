/// Sambungan untuk besok. Hari ini antrean belum disimpan.
///
/// Besok (Hari 3) yang dikerjakan di sini:
/// 1. Ganti JSON `cached_snapshot` dengan tabel drift (network-first).
/// 2. Saat kirim gagal karena jaringan, simpan `{op, clientId, ...}`
///    dengan `synced = false`. Jangan diam-diam menandai sukses.
/// 3. Kirim batch ke `POST /v1/outbox`.
/// 4. `saldo_berubah` dan `nominal_berubah`: jangan tandai synced, muat ulang.
/// 5. `ditolak`: selesai, jangan diulang terus.
/// 6. `clientId` yang sama bersifat idempoten (`alreadyApplied`).
/// 7. workmanager mengirim antrean saat aplikasi tertutup.
/// 8. WebSocket `ws://<host>:8787/v1/stream?token=` memperbarui status.
abstract final class Hari3 {
  static const belumTerkirim =
      'Belum terkirim. Antrean offline (outbox) dikerjakan besok di Hari 3.';
}
