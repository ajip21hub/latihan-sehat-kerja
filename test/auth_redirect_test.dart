import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehat_kerja/router/auth_redirect.dart';

void main() {
  test('masih memuat mengirim ke splash dan menyimpan tujuan', () {
    final ke = authRedirect(const AsyncLoading(), Uri.parse('/dana/aju'));
    expect(ke, '/splash?from=%2Fdana%2Faju');
  });

  test('belum login menyimpan from', () {
    final ke = authRedirect(const AsyncData(null), Uri.parse('/profil'));
    expect(ke, '/login?from=%2Fprofil');
  });

  test('sudah login di splash kembali ke from', () {
    final ke = authRedirect(
      const AsyncData('sesi'),
      Uri.parse('/splash?from=%2Flayanan%2Fbaru'),
    );
    expect(ke, '/layanan/baru');
  });

  test('sudah login di beranda tidak diarahkan lagi', () {
    final ke = authRedirect(const AsyncData('sesi'), Uri.parse('/beranda'));
    expect(ke, isNull);
  });
}
