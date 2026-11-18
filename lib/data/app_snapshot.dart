import '../features/dana/domain/pengajuan_dana.dart';
import '../features/dana/domain/saldo_jht.dart';
import '../features/layanan/domain/pengajuan_layanan.dart';
import '../features/peserta/domain/peserta.dart';

/// Isi `GET /v1/snapshot`. Disimpan di drift sebagai JSON.
class AppSnapshot {
  const AppSnapshot({
    required this.peserta,
    required this.saldo,
    required this.layanan,
    required this.dana,
    this.fromCache = false,
  });

  final Peserta peserta;
  final SaldoJht saldo;
  final List<PengajuanLayanan> layanan;
  final List<PengajuanDana> dana;
  final bool fromCache;

  AppSnapshot copyWith({
    bool? fromCache,
    SaldoJht? saldo,
    List<PengajuanLayanan>? layanan,
    List<PengajuanDana>? dana,
  }) => AppSnapshot(
    peserta: peserta,
    saldo: saldo ?? this.saldo,
    layanan: layanan ?? this.layanan,
    dana: dana ?? this.dana,
    fromCache: fromCache ?? this.fromCache,
  );

  factory AppSnapshot.kosong(Peserta peserta, {bool fromCache = false}) {
    return AppSnapshot(
      peserta: peserta,
      saldo: const SaldoJht(
        iuranPeserta: 0,
        iuranPemberiKerja: 0,
        pengembangan: 0,
      ),
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
    return AppSnapshot(
      peserta: peserta,
      saldo: SaldoJht.fromJson(_map(json['saldo'])),
      layanan: [
        for (final item in json['layanan'] as List? ?? const [])
          PengajuanLayanan.fromJson(_map(item), nomor: peserta.nomor),
      ],
      dana: [
        for (final item in json['dana'] as List? ?? const [])
          PengajuanDana.fromJson(_map(item), nomor: peserta.nomor),
      ],
      fromCache: fromCache,
    );
  }

  Map<String, dynamic> toJson() => {
    'peserta': peserta.toJson(),
    'saldo': saldo.toJson(),
    'layanan': [for (final item in layanan) item.toJson()],
    'dana': [for (final item in dana) item.toJson()],
  };
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return value.cast<String, dynamic>();
  throw const FormatException('Objek JSON tidak lengkap.');
}
