import '../features/dana/domain/pengajuan_dana.dart';
import '../features/dana/domain/saldo_jht.dart';
import '../features/iuran/domain/iuran.dart';
import '../features/layanan/domain/pengajuan_layanan.dart';
import '../features/peserta/domain/peserta.dart';

const _saldoNol = SaldoJht(
  iuranPeserta: 0,
  iuranPemberiKerja: 0,
  pengembangan: 0,
);

/// Isi `GET /v1/snapshot`. Disimpan di drift sebagai JSON.
///
/// Backend hanya mengirim bagian yang sesuai role. Peserta tanpa role
/// perusahaan tidak menerima `saldo`, `dana`, dan `iuranPerusahaan`.
/// Peserta tanpa role mandiri tidak menerima `tagihan`. Field yang tidak
/// dikirim dibaca sebagai kosong.
class AppSnapshot {
  const AppSnapshot({
    required this.peserta,
    required this.saldo,
    required this.layanan,
    required this.dana,
    this.iuranPerusahaan = const [],
    this.tagihan = const [],
    this.fromCache = false,
  });

  final Peserta peserta;
  final SaldoJht saldo;
  final List<PengajuanLayanan> layanan;
  final List<PengajuanDana> dana;
  final List<IuranPerusahaan> iuranPerusahaan;
  final List<TagihanIuran> tagihan;
  final bool fromCache;

  AppSnapshot copyWith({
    bool? fromCache,
    Peserta? peserta,
    SaldoJht? saldo,
    List<PengajuanLayanan>? layanan,
    List<PengajuanDana>? dana,
    List<TagihanIuran>? tagihan,
  }) => AppSnapshot(
    peserta: peserta ?? this.peserta,
    saldo: saldo ?? this.saldo,
    layanan: layanan ?? this.layanan,
    dana: dana ?? this.dana,
    iuranPerusahaan: iuranPerusahaan,
    tagihan: tagihan ?? this.tagihan,
    fromCache: fromCache ?? this.fromCache,
  );

  factory AppSnapshot.kosong(Peserta peserta, {bool fromCache = false}) {
    return AppSnapshot(
      peserta: peserta,
      saldo: _saldoNol,
      layanan: const [],
      dana: const [],
      fromCache: fromCache,
    );
  }

  factory AppSnapshot.fromJson(
    Map<String, dynamic> json, {
    bool fromCache = false,
  }) {
    final peserta = Peserta.fromJson(_map(json['peserta']));
    final saldo = json['saldo'];
    return AppSnapshot(
      peserta: peserta,
      saldo: saldo == null ? _saldoNol : SaldoJht.fromJson(_map(saldo)),
      layanan: [
        for (final item in json['layanan'] as List? ?? const [])
          PengajuanLayanan.fromJson(_map(item), nomor: peserta.nomor),
      ],
      dana: [
        for (final item in json['dana'] as List? ?? const [])
          PengajuanDana.fromJson(_map(item), nomor: peserta.nomor),
      ],
      iuranPerusahaan: [
        for (final item in json['iuranPerusahaan'] as List? ?? const [])
          IuranPerusahaan.fromJson(_map(item)),
      ],
      tagihan: [
        for (final item in json['tagihan'] as List? ?? const [])
          TagihanIuran.fromJson(_map(item)),
      ],
      fromCache: fromCache,
    );
  }

  Map<String, dynamic> toJson() => {
    'peserta': peserta.toJson(),
    'saldo': saldo.toJson(),
    'layanan': [for (final item in layanan) item.toJson()],
    'dana': [for (final item in dana) item.toJson()],
    'iuranPerusahaan': [for (final item in iuranPerusahaan) item.toJson()],
    'tagihan': [for (final item in tagihan) item.toJson()],
  };
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  throw const FormatException('Objek JSON tidak lengkap.');
}
