/// Siapa yang membayar iuran. Ini "role" yang dikirim backend.
///
/// Role bertambah, tidak saling mengganti. Peserta yang dulu dibayar
/// perusahaan lalu berhenti kerja dan mendaftar mandiri memegang dua role:
/// riwayat perusahaan tetap bisa dibuka.
enum JenisKepesertaan {
  /// Role A. Iuran dipotong dari gaji dan ditambah porsi pemberi kerja.
  perusahaan('Dibayar perusahaan'),

  /// Role B. Iuran dibayar sendiri tiap bulan.
  mandiri('Mandiri');

  const JenisKepesertaan(this.label);
  final String label;
}

enum StatusKepesertaan {
  aktif('Aktif'),
  berhenti('Berhenti');

  const StatusKepesertaan(this.label);
  final String label;
}

/// Satu segmen kepesertaan. Satu peserta bisa punya beberapa segmen.
class Kepesertaan {
  const Kepesertaan({
    required this.jenis,
    required this.status,
    required this.mulai,
    this.selesai,
    this.pemberiKerja,
  });

  final JenisKepesertaan jenis;
  final StatusKepesertaan status;
  final DateTime mulai;
  final DateTime? selesai;
  final String? pemberiKerja;

  bool get aktif => status == StatusKepesertaan.aktif;

  /// `null` kalau jenisnya belum dikenal aplikasi versi ini.
  /// Backend boleh menambah role baru tanpa membuat aplikasi lama crash.
  static Kepesertaan? tryParse(Map<String, dynamic> json) {
    final jenis = JenisKepesertaan.values.asNameMap()['${json['jenis']}'];
    final status = StatusKepesertaan.values.asNameMap()['${json['status']}'];
    final mulai = DateTime.tryParse('${json['mulai']}');
    if (jenis == null || status == null || mulai == null) return null;
    final selesai = json['selesai'];
    final pemberiKerja = json['pemberiKerja'];
    return Kepesertaan(
      jenis: jenis,
      status: status,
      mulai: mulai,
      selesai: selesai == null ? null : DateTime.tryParse('$selesai'),
      pemberiKerja: pemberiKerja?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'jenis': jenis.name,
    'status': status.name,
    'mulai': _tanggal(mulai),
    if (selesai != null) 'selesai': _tanggal(selesai!),
    if (pemberiKerja != null) 'pemberiKerja': pemberiKerja,
  };
}

String _tanggal(DateTime t) {
  final m = t.month.toString().padLeft(2, '0');
  final d = t.day.toString().padLeft(2, '0');
  return '${t.year}-$m-$d';
}
