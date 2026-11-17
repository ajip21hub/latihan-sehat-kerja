import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Path yang dipakai guard. Dipisah dari widget supaya bisa di-unit-test.
abstract final class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const beranda = '/beranda';
}

/// Guard murni. Tidak membaca widget, tidak memanggil plugin.
///
/// 1. Status belum diketahui → /splash, tujuan disimpan di `?from=`.
/// 2. Belum login → `/login?from=<tujuan>`.
/// 3. Sudah login tapi masih di /login atau /splash → kembali ke `from`.
String? authRedirect(AsyncValue<Object?> auth, Uri uri) {
  final path = uri.path;
  final atLogin = path == Routes.login;
  final atSplash = path == Routes.splash;
  final from = uri.queryParameters['from'];

  if (auth.isLoading && !auth.hasValue && !auth.hasError) {
    if (atLogin || atSplash) return null;
    return _withFrom(Routes.splash, uri.toString());
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
      from.startsWith(Routes.splash)) {
    return path;
  }
  return Uri(path: path, queryParameters: {'from': from}).toString();
}
