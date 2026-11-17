import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Menyisipkan Bearer token dan me-refresh saat 401.
///
/// [QueuedInterceptor] memproses callback satu per satu. Itu belum cukup:
/// beberapa request bisa sama-sama masuk `onError`. Sebelum refresh, kode
/// ini membandingkan token pada request dengan token tersimpan. Kalau sudah
/// berbeda, request lain sudah me-refresh — cukup diulang.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required this.storage,
    required this.plainDio,
    this.onSessionExpired,
  });

  final TokenStorage storage;

  /// Dio tanpa interceptor ini. Dipakai untuk refresh dan retry.
  ///
  /// Retry lewat Dio yang sama akan deadlock: antrean `onError` menunggu
  /// retry, retry menunggu antrean itu selesai.
  final Dio plainDio;

  /// Dipanggil hanya saat server menolak refresh token.
  final void Function()? onSessionExpired;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_lewati(options)) {
      final token = await storage.accessToken;
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final is401 = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;
    if (!is401 || alreadyRetried || _lewati(err.requestOptions)) {
      handler.next(err);
      return;
    }

    // Setiap jalur keluar wajib memanggil handler. Kalau tidak,
    // antrean berhenti selamanya dan app terlihat hang.
    try {
      var access = await storage.accessToken;
      if (access == null) {
        handler.next(err);
        return;
      }

      final sentWith = err.requestOptions.headers['Authorization'];
      if (sentWith == 'Bearer $access') {
        access = await _refresh();
        if (access == null) {
          await storage.clear();
          onSessionExpired?.call();
          handler.next(err);
          return;
        }
      }

      final retryOptions = err.requestOptions
        ..headers['Authorization'] = 'Bearer $access'
        ..extra['retried'] = true;
      final response = await plainDio.fetch<dynamic>(retryOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      // Gangguan jaringan saat refresh: jangan logout.
      handler.next(e);
    } catch (e, st) {
      handler.next(
        DioException(
          requestOptions: err.requestOptions,
          error: e,
          stackTrace: st,
        ),
      );
    }
  }

  /// Access token baru, atau `null` bila server menolak refresh
  /// (400/401/403). Error jaringan dilempar ulang.
  Future<String?> _refresh() async {
    final refresh = await storage.refreshToken;
    if (refresh == null) return null;
    try {
      final res = await plainDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final data = Map<String, dynamic>.from(res.data!);
      final access = data['accessToken'] as String;
      await storage.save(
        access: access,
        refresh: data['refreshToken'] as String,
      );
      return access;
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 400 || code == 401 || code == 403) return null;
      rethrow;
    }
  }

  /// Login yang salah juga 401. Itu bukan sinyal untuk refresh.
  bool _lewati(RequestOptions options) {
    final path = options.uri.path;
    return path == '/auth/login' || path == '/auth/refresh';
  }
}
