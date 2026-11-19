import 'package:flutter_test/flutter_test.dart';
import 'package:sehat_kerja/features/dana/domain/ajukan_pencairan.dart';
import 'package:sehat_kerja/features/dana/domain/pengajuan_dana.dart';
import 'package:sehat_kerja/features/dana/domain/saldo_jht.dart';

void main() {
  const saldo = SaldoJht(
    iuranPeserta: 4500000,
    iuranPemberiKerja: 6500000,
    pengembangan: 1500000,
  );
  const aksi = AjukanPencairan();

  test('10% ditolak bila kepesertaan belum 10 tahun', () {
    final hasil = aksi(
      nomorPeserta: '0002',
      saldo: saldo,
      tahunKepesertaan: 4,
      masihBekerja: true,
      jenis: JenisAmbil.sebagian10,
      alasan: 'Persiapan masa tua',
      adaYangMasihBerjalan: false,
    );
    expect(hasil, isA<AjuanDitolak>());
  });

  test('10% dari saldo 12,5 juta adalah 1,25 juta', () {
    final hasil = aksi(
      nomorPeserta: '0001',
      saldo: saldo,
      tahunKepesertaan: 11,
      masihBekerja: true,
      jenis: JenisAmbil.sebagian10,
      alasan: 'Persiapan masa tua',
      adaYangMasihBerjalan: false,
      sekarang: DateTime(2026, 11, 17),
    );
    expect(hasil, isA<AjuanDiterima>());
    final diterima = hasil as AjuanDiterima;
    expect(diterima.pengajuan.nominal, 1250000);
    expect(diterima.pengajuan.perkiraanHariKerja, 1);
  });

  test('seluruh saldo di atas 10 juta diperkirakan 5 hari kerja', () {
    final hasil = aksi(
      nomorPeserta: '0003',
      saldo: saldo,
      tahunKepesertaan: 13,
      masihBekerja: false,
      jenis: JenisAmbil.seluruhnya,
      alasan: 'Berhenti bekerja',
      adaYangMasihBerjalan: false,
    ) as AjuanDiterima;
    expect(hasil.pengajuan.nominal, 12500000);
    expect(hasil.pengajuan.perkiraanHariKerja, 5);
  });

  test('pengajuan yang masih berjalan menolak ajuan baru', () {
    final hasil = aksi(
      nomorPeserta: '0003',
      saldo: saldo,
      tahunKepesertaan: 13,
      masihBekerja: false,
      jenis: JenisAmbil.seluruhnya,
      alasan: 'Berhenti bekerja',
      adaYangMasihBerjalan: true,
    );
    expect(hasil, isA<AjuanDitolak>());
  });

  test('masih bekerja (role A aktif) tidak boleh ambil seluruh saldo', () {
    final hasil = aksi(
      nomorPeserta: '0001',
      saldo: saldo,
      tahunKepesertaan: 11,
      masihBekerja: true,
      jenis: JenisAmbil.seluruhnya,
      alasan: 'Ingin ambil semua',
      adaYangMasihBerjalan: false,
    );
    expect(hasil, isA<AjuanDitolak>());
  });

  test('sudah berhenti (role A riwayat) tidak lewat jalur 10%', () {
    final hasil = aksi(
      nomorPeserta: '0003',
      saldo: saldo,
      tahunKepesertaan: 13,
      masihBekerja: false,
      jenis: JenisAmbil.sebagian10,
      alasan: 'Sudah berhenti bekerja',
      adaYangMasihBerjalan: false,
    );
    expect(hasil, isA<AjuanDitolak>());
  });
}
