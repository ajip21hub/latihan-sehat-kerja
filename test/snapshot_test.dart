import 'package:flutter_test/flutter_test.dart';
import 'package:sehat_kerja/core/network/log_redaction.dart';
import 'package:sehat_kerja/data/app_snapshot.dart';
import 'package:sehat_kerja/features/dana/domain/saldo_jht.dart';

void main() {
  test('snapshot server bisa dibaca dan ditulis ulang', () {
    const mentah = {
      'peserta': {
        'nomor': '0001',
        'nama': 'Sari Wulandari',
        'nik': '3275011201900001',
        'kelas': 'dua',
        'faskes': 'Klinik Melati',
        'tahunKepesertaan': 11,
        'aktif': true,
      },
      'saldo': {
        'iuranPeserta': 4500000,
        'iuranPemberiKerja': 6500000,
        'pengembangan': 1500000,
        'total': 12500000,
      },
      'layanan': [
        {
          'id': 'L-1',
          'jenis': 'rawatJalan',
          'faskes': 'Klinik Melati',
          'tanggal': '2026-10-02T00:00:00.000Z',
          'keluhan': 'Demam dan batuk',
          'status': 'disetujui',
        },
      ],
      'dana': <Map<String, dynamic>>[],
    };

    final snap = AppSnapshot.fromJson(mentah);
    expect(snap.peserta.nikDisamarkan, '3275••••0001');
    expect(snap.saldo.total, 12500000);
    expect(snap.layanan.single.statusLabel, 'Disetujui');
    expect(snap.layanan.single.nomorPeserta, '0001');

    final ulang = AppSnapshot.fromJson(snap.toJson());
    expect(ulang.saldo, isA<SaldoJht>());
    expect(ulang.dana, isEmpty);
    expect(ulang.layanan.single.keluhan, 'Demam dan batuk');
  });

  test('log menyembunyikan bearer dan sandi', () {
    const raw =
        'Authorization: Bearer abc.def "sandi":"belajar" "refreshToken":"zzz"';
    final bersih = redactSecrets(raw);
    expect(bersih.contains('abc.def'), isFalse);
    expect(bersih.contains('belajar'), isFalse);
    expect(bersih.contains('zzz'), isFalse);
    expect(bersih, contains('Bearer ***'));
  });
}
