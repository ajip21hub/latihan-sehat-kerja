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

  test('belum selesai onboarding diarahkan ke /onboarding', () {
    final ke = authRedirect(
      const AsyncData(null),
      Uri.parse('/beranda'),
      onboardingSelesai: false,
    );
    expect(ke, '/onboarding');
  });

  test('sedang di /onboarding saat belum selesai onboarding tetap di tempat', () {
    final ke = authRedirect(
      const AsyncData(null),
      Uri.parse('/onboarding'),
      onboardingSelesai: false,
    );
    expect(ke, isNull);
  });

  test('sudah selesai onboarding saat di /onboarding dialihkan ke login', () {
    final ke = authRedirect(
      const AsyncData(null),
      Uri.parse('/onboarding'),
      onboardingSelesai: true,
    );
    expect(ke, '/login');
  });

  test('sudah selesai onboarding dan login saat di /onboarding dialihkan ke beranda', () {
    final ke = authRedirect(
      const AsyncData('sesi'),
      Uri.parse('/onboarding'),
      onboardingSelesai: true,
    );
    expect(ke, '/beranda');
  });

  test('mode view di /onboarding tidak dialihkan', () {
    final ke = authRedirect(
      const AsyncData('sesi'),
      Uri.parse('/onboarding?view=true'),
      onboardingSelesai: true,
    );
    expect(ke, isNull);
  });
}
