import 'kepesertaan.dart';

/// Menu di grid Beranda. [syarat] `null` berarti untuk semua peserta.
///
/// Role A (perusahaan) membuka 4 menu pertama, role B (mandiri) 4 menu
/// terakhir. Peserta dengan dua role melihat semuanya.
enum MenuUtama {
  pemberiKerja(
    'Info pemberi kerja',
    '/pemberi-kerja',
    JenisKepesertaan.perusahaan,
  ),
  iuranPerusahaan(
    'Iuran perusahaan',
    '/iuran-perusahaan',
    JenisKepesertaan.perusahaan,
  ),
  saldoJht('Saldo JHT', '/dana', JenisKepesertaan.perusahaan),
  klaimJht('Klaim JHT', '/dana/aju', JenisKepesertaan.perusahaan),
  layanan('Layanan faskes', '/layanan', null),
  tagihan('Tagihan iuran', '/iuran/tagihan', JenisKepesertaan.mandiri),
  bayar('Bayar iuran', '/iuran/bayar', JenisKepesertaan.mandiri),
  riwayatBayar('Riwayat bayar', '/iuran/riwayat', JenisKepesertaan.mandiri),
  ubahKelas('Ubah kelas rawat', '/kelas', JenisKepesertaan.mandiri);

  const MenuUtama(this.label, this.path, this.syarat);

  final String label;
  final String path;
  final JenisKepesertaan? syarat;

  bool bolehUntuk(Set<JenisKepesertaan> peran) =>
      syarat == null || peran.contains(syarat);
}

/// Urutan tetap mengikuti deklarasi enum.
List<MenuUtama> menuUntuk(Set<JenisKepesertaan> peran) => [
  for (final menu in MenuUtama.values)
    if (menu.bolehUntuk(peran)) menu,
];

/// Dipakai guard router supaya deep link tidak melewati role.
///
/// Path yang tidak terdaftar sebagai menu (beranda, profil, artikel) selalu
/// boleh. Yang dicek adalah prefiks terpanjang, jadi `/dana/aju` mengikuti
/// syarat `/dana/aju`, bukan `/dana`.
bool bolehBuka(String path, Set<JenisKepesertaan> peran) {
  MenuUtama? cocok;
  for (final menu in MenuUtama.values) {
    final kena = path == menu.path || path.startsWith('${menu.path}/');
    if (!kena) continue;
    if (cocok == null || menu.path.length > cocok.path.length) cocok = menu;
  }
  return cocok == null || cocok.bolehUntuk(peran);
}
