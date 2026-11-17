import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/env.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';
import 'certificate_pinning.dart';
import 'certificate_pinning_stub.dart'
    if (dart.library.io) 'certificate_pinning_io.dart';
import 'log_redaction.dart';
import 'session_events.dart';

Dio _newDio() {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: Headers.jsonContentType,
    ),
  );
  // Pin yang sama untuk Dio utama dan Dio refresh/retry.
  final pinned = pinnedHttpClientAdapter(parsePins(Env.certSha256Pins));
  if (pinned != null) dio.httpClientAdapter = pinned;
  return dio;
}

final dioProvider = Provider<Dio>((ref) {
  final dio = _newDio();
  final plainDio = _newDio();
  dio.interceptors.addAll([
    AuthInterceptor(
      storage: ref.watch(tokenStorageProvider),
      plainDio: plainDio,
      onSessionExpired: () =>
          ref.read(sessionExpiredProvider.notifier).notifyListenersOfExpiry(),
    ),
    if (kDebugMode)
      LogInterceptor(
        requestHeader: true,
        requestBody: true,
        responseBody: false,
        logPrint: (object) => debugPrint(redactSecrets('$object')),
      ),
  ]);
  ref.onDispose(() {
    dio.close();
    plainDio.close();
  });
  return dio;
});
