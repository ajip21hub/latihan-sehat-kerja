import 'kepesertaan.dart';

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
    this.kepesertaan = const [],
  });

  final String nomor;
  final String nama;
  final String nik;
  final KelasRawat kelas;
  final String faskes;
  final int tahunKepesertaan;
  final bool aktif;

  /// Segmen dari backend. Sumber role di aplikasi.
  final List<Kepesertaan> kepesertaan;

  /// Role yang dimiliki, aktif maupun sudah berhenti.
  /// Menu ditentukan dari sini, bukan dari status.
  Set<JenisKepesertaan> get peran => {for (final k in kepesertaan) k.jenis};

  bool punya(JenisKepesertaan jenis) => peran.contains(jenis);

  /// Masih bekerja di perusahaan yang membayar iuran.
  bool get masihBekerja =>
      kepesertaan.any((k) => k.jenis == JenisKepesertaan.perusahaan && k.aktif);

  bool get mandiriAktif =>
      kepesertaan.any((k) => k.jenis == JenisKepesertaan.mandiri && k.aktif);

  /// Siapa yang menanggung iuran bulan ini.
  String get pembayarIuran {
    if (masihBekerja) return JenisKepesertaan.perusahaan.label;
    if (mandiriAktif) return JenisKepesertaan.mandiri.label;
    return 'Tidak ada iuran berjalan';
  }

  String get nikDisamarkan {
    if (nik.length < 8) return nik;
    return '${nik.substring(0, 4)}••••${nik.substring(nik.length - 4)}';
  }

  Peserta copyWith({KelasRawat? kelas}) => Peserta(
    nomor: nomor,
    nama: nama,
    nik: nik,
    kelas: kelas ?? this.kelas,
    faskes: faskes,
    tahunKepesertaan: tahunKepesertaan,
    aktif: aktif,
    kepesertaan: kepesertaan,
  );

  factory Peserta.fromJson(Map<String, dynamic> json) {
    final segmen = json['kepesertaan'];
    return Peserta(
      nomor: '${json['nomor']}',
      nama: '${json['nama']}',
      nik: '${json['nik']}',
      kelas: KelasRawat.values.byName('${json['kelas']}'),
      faskes: '${json['faskes']}',
      tahunKepesertaan: (json['tahunKepesertaan'] as num).toInt(),
      aktif: json['aktif'] != false,
      // Cache lama tanpa field ini: role kosong, hanya menu bersama tampil
      // sampai snapshot berikutnya berhasil diunduh.
      kepesertaan: [
        if (segmen is List)
          for (final item in segmen)
            if (item is Map)
              ?Kepesertaan.tryParse(item.cast<String, dynamic>()),
      ],
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
    'kepesertaan': [for (final k in kepesertaan) k.toJson()],
  };
}
