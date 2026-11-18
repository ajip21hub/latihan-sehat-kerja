import 'package:flutter_riverpod/flutter_riverpod.dart';

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
String? authRedirect(
  AsyncValue<Object?> auth,
  Uri uri, {
  bool onboardingSelesai = true,
  bool isInitialLoading = false,
}) {
  final path = uri.path;
  final atLogin = path == Routes.login;
  final atSplash = path == Routes.splash;
  final atOnboarding = path == Routes.onboarding;
  final isViewMode = uri.queryParameters['view'] == 'true';
  final from = uri.queryParameters['from'];

  if (isInitialLoading || (auth.isLoading && !auth.hasValue && !auth.hasError)) {
    if (atLogin || atSplash || atOnboarding) return null;
    return _withFrom(Routes.splash, uri.toString());
  }

  if (!onboardingSelesai && !isViewMode) {
    if (atOnboarding) return null;
    return Routes.onboarding;
  }

  if (atOnboarding && !isViewMode) {
    final loggedIn = auth.value != null;
    return loggedIn ? (from ?? Routes.beranda) : Routes.login;
  }

  final loggedIn = auth.value != null;
  if (!loggedIn) {
    if (atLogin) return null;
    return _withFrom(Routes.login, atSplash ? from : uri.toString());
  }
  if (atLogin || atSplash) return from ?? Routes.beranda;
  return null;
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
