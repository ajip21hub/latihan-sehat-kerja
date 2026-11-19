// Snapshot tiga akun latihan, bentuknya sama dengan backend/server.dart.
// Bukan file test (tidak berakhiran _test), hanya dipakai test lain.

Map<String, dynamic> pesertaJson(
  String nomor, {
  required List<Map<String, dynamic>> kepesertaan,
  String kelas = 'dua',
  int tahun = 11,
}) => {
  'nomor': nomor,
  'nama': 'Peserta $nomor',
  'nik': '327501120190$nomor',
  'kelas': kelas,
  'faskes': 'Klinik Melati',
  'tahunKepesertaan': tahun,
  'aktif': true,
  'kepesertaan': kepesertaan,
};

const segmenPerusahaanAktif = {
  'jenis': 'perusahaan',
  'status': 'aktif',
  'pemberiKerja': 'PT Maju Jaya',
  'mulai': '2015-03-01',
};

const segmenPerusahaanBerhenti = {
  'jenis': 'perusahaan',
  'status': 'berhenti',
  'pemberiKerja': 'PT Sinar Abadi',
  'mulai': '2013-02-01',
  'selesai': '2026-06-30',
};

const segmenMandiri = {
  'jenis': 'mandiri',
  'status': 'aktif',
  'mulai': '2026-07-01',
};

const _saldo = {
  'iuranPeserta': 4500000,
  'iuranPemberiKerja': 6500000,
  'pengembangan': 1500000,
  'total': 12500000,
};

Map<String, dynamic> _tagihan(String periode, {bool lunas = false}) => {
  'id': 'T-$periode',
  'periode': periode,
  'kelas': 'dua',
  'nominal': 100000,
  'status': lunas ? 'lunas' : 'belumBayar',
  if (lunas) 'dibayar': '$periode-05T03:00:00.000Z',
};

/// Role A saja: masih bekerja.
Map<String, dynamic> snapshot0001() => {
  'peserta': pesertaJson('0001', kepesertaan: [segmenPerusahaanAktif]),
  'saldo': _saldo,
  'layanan': <Map<String, dynamic>>[],
  'dana': <Map<String, dynamic>>[],
  'iuranPerusahaan': [
    {
      'periode': '2026-10',
      'pemberiKerja': 'PT Maju Jaya',
      'potonganPekerja': 120000,
      'porsiPemberiKerja': 222000,
    },
  ],
};

/// Role B saja: backend tidak mengirim saldo, dana, iuranPerusahaan.
Map<String, dynamic> snapshot0002() => {
  'peserta': pesertaJson(
    '0002',
    kepesertaan: [segmenMandiri],
    kelas: 'tiga',
    tahun: 4,
  ),
  'layanan': <Map<String, dynamic>>[],
  'tagihan': [_tagihan('2026-10', lunas: true), _tagihan('2026-11')],
};

/// Role A (berhenti) + role B (aktif).
Map<String, dynamic> snapshot0003() => {
  'peserta': pesertaJson(
    '0003',
    kepesertaan: [segmenPerusahaanBerhenti, segmenMandiri],
    tahun: 13,
  ),
  'saldo': _saldo,
  'layanan': <Map<String, dynamic>>[],
  'dana': <Map<String, dynamic>>[],
  'iuranPerusahaan': <Map<String, dynamic>>[],
  'tagihan': [_tagihan('2026-11')],
};
