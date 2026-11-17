/// Saldo Jaminan Hari Tua versi latihan. Bukan perhitungan iuran resmi.
class SaldoJht {
  const SaldoJht({
    required this.iuranPeserta,
    required this.iuranPemberiKerja,
    required this.pengembangan,
  });

  final int iuranPeserta;
  final int iuranPemberiKerja;
  final int pengembangan;

  int get total => iuranPeserta + iuranPemberiKerja + pengembangan;

  factory SaldoJht.fromJson(Map<String, dynamic> json) {
    return SaldoJht(
      iuranPeserta: (json['iuranPeserta'] as num).toInt(),
      iuranPemberiKerja: (json['iuranPemberiKerja'] as num).toInt(),
      pengembangan: (json['pengembangan'] as num).toInt(),
    );
  }

  Map<String, dynamic> toJson() => {
    'iuranPeserta': iuranPeserta,
    'iuranPemberiKerja': iuranPemberiKerja,
    'pengembangan': pengembangan,
    'total': total,
  };

  SaldoJht kurang(int nominal) {
    final fromPeserta = nominal.clamp(0, iuranPeserta);
    var rest = nominal - fromPeserta;
    final fromPemberi = rest.clamp(0, iuranPemberiKerja);
    rest -= fromPemberi;
    final fromKembang = rest.clamp(0, pengembangan);
    return SaldoJht(
      iuranPeserta: iuranPeserta - fromPeserta,
      iuranPemberiKerja: iuranPemberiKerja - fromPemberi,
      pengembangan: pengembangan - fromKembang,
    );
  }
}
