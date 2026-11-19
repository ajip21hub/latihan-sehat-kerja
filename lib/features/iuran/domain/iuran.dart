import '../../peserta/domain/peserta.dart';

/// Tarif mandiri latihan per bulan. Angka contoh, bukan tarif resmi.
int tarifMandiri(KelasRawat kelas) => switch (kelas) {
  KelasRawat.satu => 150000,
  KelasRawat.dua => 100000,
  KelasRawat.tiga => 35000,
};

enum StatusTagihan {
  belumBayar('Belum dibayar'),

  /// Hanya di perangkat: pembayaran masih di antrean outbox.
  menunggu('Menunggu kirim'),
  lunas('Lunas');

  const StatusTagihan(this.label);
  final String label;
}

/// Tagihan iuran mandiri (role B) untuk satu bulan.
class TagihanIuran {
  const TagihanIuran({
    required this.id,
    required this.periode,
    required this.kelas,
    required this.nominal,
    required this.status,
    this.dibayar,
  });

  final String id;

  /// `2026-11`.
  final String periode;
  final KelasRawat kelas;
  final int nominal;
  final StatusTagihan status;
  final DateTime? dibayar;

  bool get bisaDibayar => status == StatusTagihan.belumBayar;

  TagihanIuran copyWith({StatusTagihan? status}) => TagihanIuran(
    id: id,
    periode: periode,
    kelas: kelas,
    nominal: nominal,
    status: status ?? this.status,
    dibayar: dibayar,
  );

  factory TagihanIuran.fromJson(Map<String, dynamic> json) {
    final dibayar = json['dibayar'];
    return TagihanIuran(
      id: '${json['id']}',
      periode: '${json['periode']}',
      kelas: KelasRawat.values.byName('${json['kelas']}'),
      nominal: (json['nominal'] as num).toInt(),
      status: StatusTagihan.values.byName('${json['status']}'),
      dibayar: dibayar == null ? null : DateTime.tryParse('$dibayar'),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'periode': periode,
    'kelas': kelas.name,
    'nominal': nominal,
    'status': status.name,
    if (dibayar != null) 'dibayar': dibayar!.toUtc().toIso8601String(),
  };
}

/// Satu bulan iuran yang dibayar lewat perusahaan (role A).
class IuranPerusahaan {
  const IuranPerusahaan({
    required this.periode,
    required this.pemberiKerja,
    required this.potonganPekerja,
    required this.porsiPemberiKerja,
  });

  final String periode;
  final String pemberiKerja;
  final int potonganPekerja;
  final int porsiPemberiKerja;

  int get total => potonganPekerja + porsiPemberiKerja;

  factory IuranPerusahaan.fromJson(Map<String, dynamic> json) {
    return IuranPerusahaan(
      periode: '${json['periode']}',
      pemberiKerja: '${json['pemberiKerja']}',
      potonganPekerja: (json['potonganPekerja'] as num).toInt(),
      porsiPemberiKerja: (json['porsiPemberiKerja'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'periode': periode,
    'pemberiKerja': pemberiKerja,
    'potonganPekerja': potonganPekerja,
    'porsiPemberiKerja': porsiPemberiKerja,
  };
}

const _bulan = [
  'Januari',
  'Februari',
  'Maret',
  'April',
  'Mei',
  'Juni',
  'Juli',
  'Agustus',
  'September',
  'Oktober',
  'November',
  'Desember',
];

/// `2026-11` menjadi `November 2026`. Teks lain dikembalikan apa adanya.
String labelPeriode(String periode) {
  final bagian = periode.split('-');
  if (bagian.length != 2) return periode;
  final bulan = int.tryParse(bagian[1]);
  if (bulan == null || bulan < 1 || bulan > 12) return periode;
  return '${_bulan[bulan - 1]} ${bagian[0]}';
}

sealed class HasilUbahKelas {
  const HasilUbahKelas();
}

class UbahKelasBoleh extends HasilUbahKelas {
  const UbahKelasBoleh();
}

class UbahKelasDitolak extends HasilUbahKelas {
  const UbahKelasDitolak(this.alasan);
  final String alasan;
}

/// Aturan murni. Server mengulang cek yang sama.
HasilUbahKelas cekUbahKelas({
  required Peserta peserta,
  required KelasRawat tujuan,
  required List<TagihanIuran> tagihan,
}) {
  if (!peserta.mandiriAktif) {
    return const UbahKelasDitolak(
      'Kelas hanya bisa dipilih sendiri oleh peserta mandiri yang aktif.',
    );
  }
  if (tujuan == peserta.kelas) {
    return const UbahKelasDitolak('Kelas tujuan sama dengan kelas sekarang.');
  }
  if (tagihan.any((t) => t.status != StatusTagihan.lunas)) {
    return const UbahKelasDitolak('Lunasi tagihan iuran dulu.');
  }
  return const UbahKelasBoleh();
}
