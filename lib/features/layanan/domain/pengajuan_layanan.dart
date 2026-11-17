enum JenisLayanan { rawatJalan, rawatInap }

enum StatusPengajuan {
  diajukan('Diajukan'),
  diproses('Diproses'),
  disetujui('Disetujui'),
  ditolak('Ditolak');

  const StatusPengajuan(this.label);
  final String label;
}

class PengajuanLayanan {
  const PengajuanLayanan({
    required this.id,
    required this.nomorPeserta,
    required this.jenis,
    required this.faskes,
    required this.tanggal,
    required this.keluhan,
    required this.status,
  });

  final String id;
  final String nomorPeserta;
  final JenisLayanan jenis;
  final String faskes;
  final DateTime tanggal;
  final String keluhan;
  final StatusPengajuan status;

  String get jenisLabel => switch (jenis) {
    JenisLayanan.rawatJalan => 'Rawat jalan',
    JenisLayanan.rawatInap => 'Rawat inap',
  };

  String get statusLabel => status.label;

  factory PengajuanLayanan.fromJson(
    Map<String, dynamic> json, {
    required String nomor,
  }) {
    return PengajuanLayanan(
      id: '${json['id']}',
      nomorPeserta: '${json['nomorPeserta'] ?? nomor}',
      jenis: JenisLayanan.values.byName('${json['jenis']}'),
      faskes: '${json['faskes']}',
      tanggal: DateTime.parse('${json['tanggal']}'),
      keluhan: '${json['keluhan']}',
      status: StatusPengajuan.values.byName('${json['status']}'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'nomorPeserta': nomorPeserta,
    'jenis': jenis.name,
    'faskes': faskes,
    'tanggal': tanggal.toUtc().toIso8601String(),
    'keluhan': keluhan,
    'status': status.name,
  };
}
