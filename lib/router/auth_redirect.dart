import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/peserta/domain/kepesertaan.dart';
import '../features/peserta/domain/menu_utama.dart';

/// Path yang dipakai guard. Dipisah dari widget supaya bisa di-unit-test.
abstract final class Routes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const beranda = '/beranda';
}

/// Guard murni. Tidak membaca widget, tidak memanggil plugin.
///
/// 1. Status belum diketahui → /splash, tujuan disimpan di `?from=`.
/// 2. Belum selesai onboarding → /onboarding (kecuali mode view).
/// 3. Sudah selesai onboarding tapi masih di /onboarding (tanpa mode view) → login atau beranda.
/// 4. Belum login → `/login?from=<tujuan>`.
/// 5. Sudah login tapi masih di /login atau /splash → kembali ke `from` / beranda.
/// 6. Sudah login tapi membuka menu yang bukan role-nya → beranda.
///    [peran] `null` berarti role belum diketahui, cek ini dilewati.
///    Menyembunyikan menu hanya tampilan. Backend tetap menolak aksinya.
String? authRedirect(
  AsyncValue<Object?> auth,
  Uri uri, {
  bool onboardingSelesai = true,
  bool isInitialLoading = false,
  Set<JenisKepesertaan>? peran,
}) {
  final path = uri.path;
  final atLogin = path == Routes.login;
  final atSplash = path == Routes.splash;
  final atOnboarding = path == Routes.onboarding;
  final isViewMode = uri.queryParameters['view'] == 'true';
  final from = uri.queryParameters['from'];

  if (isInitialLoading ||
      (auth.isLoading && !auth.hasValue && !auth.hasError)) {
    if (atLogin || atSplash || atOnboarding) return null;
    return _withFrom(Routes.splash, uri.toString());
  }

  if (!onboardingSelesai && !isViewMode) {
    if (atOnboarding) return null;
    return Routes.onboarding;
  }

  if (atOnboarding && !isViewMode) {
    final loggedIn = auth.value != null;
    return loggedIn ? _bolehAtauBeranda(from, peran) : Routes.login;
  }

  final loggedIn = auth.value != null;
  if (!loggedIn) {
    if (atLogin) return null;
    return _withFrom(Routes.login, atSplash ? from : uri.toString());
  }
  if (atLogin || atSplash) return _bolehAtauBeranda(from, peran);
  if (peran != null && !bolehBuka(path, peran)) return Routes.beranda;
  return null;
}

String _bolehAtauBeranda(String? tujuan, Set<JenisKepesertaan>? peran) {
  if (tujuan == null) return Routes.beranda;
  if (peran == null) return tujuan;
  return bolehBuka(Uri.parse(tujuan).path, peran) ? tujuan : Routes.beranda;
}

String _withFrom(String path, String? from) {
  if (from == null ||
      from == Routes.beranda ||
      from == '/' ||
      from.startsWith(Routes.login) ||
      from.startsWith(Routes.splash) ||
      from.startsWith(Routes.onboarding)) {
    return path;
  }
  return Uri(path: path, queryParameters: {'from': from}).toString();
}
