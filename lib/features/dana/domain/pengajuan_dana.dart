import '../../layanan/domain/pengajuan_layanan.dart';

enum JenisAmbil { seluruhnya, sebagian10 }

class PengajuanDana {
  const PengajuanDana({
    required this.id,
    required this.nomorPeserta,
    required this.jenis,
    required this.nominal,
    required this.alasan,
    required this.status,
    required this.perkiraanHariKerja,
  });

  final String id;
  final String nomorPeserta;
  final JenisAmbil jenis;
  final int nominal;
  final String alasan;
  final StatusPengajuan status;
  final int perkiraanHariKerja;

  bool get masihBerjalan =>
      status == StatusPengajuan.diajukan || status == StatusPengajuan.diproses;

  String get jenisLabel => switch (jenis) {
    JenisAmbil.seluruhnya => 'Seluruh saldo',
    JenisAmbil.sebagian10 => 'Sebagian 10%',
  };

  factory PengajuanDana.fromJson(
    Map<String, dynamic> json, {
    required String nomor,
  }) {
    return PengajuanDana(
      id: '${json['id']}',
      nomorPeserta: '${json['nomorPeserta'] ?? nomor}',
      jenis: JenisAmbil.values.byName('${json['jenis']}'),
      nominal: (json['nominal'] as num).toInt(),
      alasan: '${json['alasan']}',
      status: StatusPengajuan.values.byName('${json['status']}'),
      perkiraanHariKerja: (json['perkiraanHariKerja'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nomorPeserta': nomorPeserta,
    'jenis': jenis.name,
    'nominal': nominal,
    'alasan': alasan,
    'status': status.name,
    'perkiraanHariKerja': perkiraanHariKerja,
  };
}
