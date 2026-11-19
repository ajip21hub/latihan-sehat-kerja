import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehat_kerja/data/app_snapshot.dart';
import 'package:sehat_kerja/features/iuran/domain/iuran.dart';
import 'package:sehat_kerja/features/peserta/domain/kepesertaan.dart';
import 'package:sehat_kerja/features/peserta/domain/menu_utama.dart';
import 'package:sehat_kerja/features/peserta/domain/peserta.dart';
import 'package:sehat_kerja/router/auth_redirect.dart';

import 'akun_contoh.dart';

const _a = {JenisKepesertaan.perusahaan};
const _b = {JenisKepesertaan.mandiri};
const _ab = {JenisKepesertaan.perusahaan, JenisKepesertaan.mandiri};

void main() {
  group('menu per role', () {
    test('role A: 4 menu perusahaan + menu bersama', () {
      expect(menuUntuk(_a), [
        MenuUtama.pemberiKerja,
        MenuUtama.iuranPerusahaan,
        MenuUtama.saldoJht,
        MenuUtama.klaimJht,
        MenuUtama.layanan,
      ]);
    });

    test('role B: menu bersama + 4 menu mandiri', () {
      expect(menuUntuk(_b), [
        MenuUtama.layanan,
        MenuUtama.tagihan,
        MenuUtama.bayar,
        MenuUtama.riwayatBayar,
        MenuUtama.ubahKelas,
      ]);
    });

    test('role A + B: semua menu', () {
      expect(menuUntuk(_ab), MenuUtama.values);
    });

    test('tanpa role: hanya menu bersama', () {
      expect(menuUntuk(const {}), [MenuUtama.layanan]);
    });

    test('bolehBuka memakai prefiks terpanjang dan batas segmen', () {
      expect(bolehBuka('/dana/aju', _a), isTrue);
      expect(bolehBuka('/dana/aju', _b), isFalse);
      expect(bolehBuka('/iuran/bayar', _a), isFalse);
      expect(bolehBuka('/iuran-perusahaan', _b), isFalse);
      expect(bolehBuka('/iuran-perusahaan', _a), isTrue);
      expect(bolehBuka('/layanan/baru', const {}), isTrue);
      expect(bolehBuka('/profil', const {}), isTrue);
    });
  });

  group('kepesertaan dari backend', () {
    test('0003 punya dua role, sudah berhenti bekerja, mandiri aktif', () {
      final p = Peserta.fromJson(snapshot0003()['peserta']);
      expect(p.peran, _ab);
      expect(p.masihBekerja, isFalse);
      expect(p.mandiriAktif, isTrue);
      expect(p.pembayarIuran, 'Mandiri');
    });

    test('role yang belum dikenal diabaikan, bukan crash', () {
      final p = Peserta.fromJson(
        pesertaJson(
          '0009',
          kepesertaan: [
            segmenMandiri,
            {
              'jenis': 'penerimaBantuan',
              'status': 'aktif',
              'mulai': '2020-01-01',
            },
          ],
        ),
      );
      expect(p.peran, _b);
    });

    test('cache lama tanpa kepesertaan dibaca sebagai tanpa role', () {
      final json = pesertaJson('0001', kepesertaan: const [])
        ..remove('kepesertaan');
      expect(Peserta.fromJson(json).peran, isEmpty);
    });

    test('snapshot role B tanpa saldo tetap terbaca, lalu ditulis ulang', () {
      final snap = AppSnapshot.fromJson(snapshot0002());
      expect(snap.saldo.total, 0);
      expect(snap.tagihan, hasLength(2));
      final ulang = AppSnapshot.fromJson(snap.toJson());
      expect(ulang.peserta.peran, _b);
      expect(ulang.tagihan.last.status, StatusTagihan.belumBayar);
    });
  });

  group('guard router', () {
    test('role B membuka /dana lewat deep link dikembalikan ke beranda', () {
      final ke = authRedirect(
        const AsyncData('sesi'),
        Uri.parse('/dana'),
        peran: _b,
      );
      expect(ke, Routes.beranda);
    });

    test('role A membuka /iuran/bayar dikembalikan ke beranda', () {
      final ke = authRedirect(
        const AsyncData('sesi'),
        Uri.parse('/iuran/bayar?id=T-1'),
        peran: _a,
      );
      expect(ke, Routes.beranda);
    });

    test('role A + B boleh membuka menu dua role', () {
      for (final path in ['/dana/aju', '/iuran/bayar', '/pemberi-kerja']) {
        final ke = authRedirect(
          const AsyncData('sesi'),
          Uri.parse(path),
          peran: _ab,
        );
        expect(ke, isNull, reason: path);
      }
    });

    test('from yang bukan haknya tidak dipakai setelah login', () {
      final ke = authRedirect(
        const AsyncData('sesi'),
        Uri.parse('/login?from=%2Fdana%2Faju'),
        peran: _b,
      );
      expect(ke, Routes.beranda);
    });
  });

  group('ubah kelas', () {
    Peserta peserta(Map<String, dynamic> snap) =>
        Peserta.fromJson(snap['peserta']);

    test('role A saja tidak bisa memilih kelas sendiri', () {
      final hasil = cekUbahKelas(
        peserta: peserta(snapshot0001()),
        tujuan: KelasRawat.satu,
        tagihan: const [],
      );
      expect(hasil, isA<UbahKelasDitolak>());
    });

    test('masih ada tagihan belum lunas ditolak', () {
      final snap = AppSnapshot.fromJson(snapshot0003());
      final hasil = cekUbahKelas(
        peserta: snap.peserta,
        tujuan: KelasRawat.satu,
        tagihan: snap.tagihan,
      );
      expect(hasil, isA<UbahKelasDitolak>());
    });

    test('mandiri aktif dan lunas boleh', () {
      final hasil = cekUbahKelas(
        peserta: peserta(snapshot0003()),
        tujuan: KelasRawat.satu,
        tagihan: const [],
      );
      expect(hasil, isA<UbahKelasBoleh>());
    });
  });

  test('label periode', () {
    expect(labelPeriode('2026-11'), 'November 2026');
    expect(labelPeriode('acak'), 'acak');
  });
}
