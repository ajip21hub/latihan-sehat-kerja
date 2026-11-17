/// Golongan layanan rawat inap. Di JKN ini disebut kelas rawat.
enum KelasRawat {
  satu('Kelas 1'),
  dua('Kelas 2'),
  tiga('Kelas 3');

  const KelasRawat(this.label);
  final String label;
}

class Peserta {
  const Peserta({
    required this.nomor,
    required this.nama,
    required this.nik,
    required this.kelas,
    required this.faskes,
    required this.tahunKepesertaan,
    required this.aktif,
  });

  final String nomor;
  final String nama;
  final String nik;
  final KelasRawat kelas;
  final String faskes;
  final int tahunKepesertaan;
  final bool aktif;

  String get nikDisamarkan {
    if (nik.length < 8) return nik;
    return '${nik.substring(0, 4)}••••${nik.substring(nik.length - 4)}';
  }

  factory Peserta.fromJson(Map<String, dynamic> json) {
    return Peserta(
      nomor: '${json['nomor']}',
      nama: '${json['nama']}',
      nik: '${json['nik']}',
      kelas: KelasRawat.values.byName('${json['kelas']}'),
      faskes: '${json['faskes']}',
      tahunKepesertaan: (json['tahunKepesertaan'] as num).toInt(),
      aktif: json['aktif'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
    'nomor': nomor,
    'nama': nama,
    'nik': nik,
    'kelas': kelas.name,
    'faskes': faskes,
    'tahunKepesertaan': tahunKepesertaan,
    'aktif': aktif,
  };
}
