/// Aturan antrean offline yang dipakai repository.
///
/// Pengajuan disimpan dulu dengan `synced = false`. Sukses jaringan
/// baru menandai synced, dan hanya kalau sidik payload belum berubah.
/// `saldo_berubah` serta `nominal_berubah` tetap antre. `ditolak` dan
/// `jenis` selesai, tidak diulang.
abstract final class Hari3 {
  static const menunggu =
      'Pengajuan tersimpan di perangkat. Akan dikirim saat server terjangkau.';
}
