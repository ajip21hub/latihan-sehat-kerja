import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehat_kerja/core/network/auth_interceptor.dart';
import 'package:sehat_kerja/core/storage/token_storage.dart';

void main() {
  test('beberapa 401 hanya me-refresh satu kali', () async {
    final storage = TokenStorage(MemoryKeyValueStore());
    await storage.save(access: 'old-access', refresh: 'old-refresh');

    var refreshCount = 0;
    final plain = Dio(BaseOptions(baseUrl: 'https://example.test'));
    plain.httpClientAdapter = ScriptedAdapter((options) async {
      if (options.path.contains('/auth/refresh')) {
        refreshCount++;
        return jsonBody(200, {
          'accessToken': 'new-access',
          'refreshToken': 'new-refresh',
        });
      }
      return jsonBody(200, {'ok': true, 'path': options.path});
    });

    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = ScriptedAdapter((options) async {
      if (options.headers['Authorization'] == 'Bearer old-access') {
        return jsonBody(401, {'message': 'expired'});
      }
      return jsonBody(200, {'ok': true, 'path': options.path});
    });
    dio.interceptors.add(AuthInterceptor(storage: storage, plainDio: plain));

    final results = await Future.wait([
      dio.get<Map<String, dynamic>>('/v1/snapshot'),
      dio.get<Map<String, dynamic>>('/v1/snapshot'),
    ]);

    expect(refreshCount, 1);
    expect(await storage.accessToken, 'new-access');
    expect(
      results.map((r) => r.requestOptions.headers['Authorization']).toSet(),
      {'Bearer new-access'},
    );
  });

  test('timeout saat refresh tidak menghapus token', () async {
    final storage = TokenStorage(MemoryKeyValueStore());
    await storage.save(access: 'old-access', refresh: 'old-refresh');
    var expired = 0;

    final plain = Dio(BaseOptions(baseUrl: 'https://example.test'));
    plain.httpClientAdapter = ScriptedAdapter((options) async {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionTimeout,
      );
    });

    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = ScriptedAdapter(
      (_) async => jsonBody(401, {'message': 'expired'}),
    );
    dio.interceptors.add(
      AuthInterceptor(
        storage: storage,
        plainDio: plain,
        onSessionExpired: () => expired++,
      ),
    );

    await expectLater(
      dio.get<void>('/v1/snapshot'),
      throwsA(isA<DioException>()),
    );
    expect(await storage.accessToken, 'old-access');
    expect(expired, 0);
  });

  test('refresh ditolak server menghapus sesi', () async {
    final storage = TokenStorage(MemoryKeyValueStore());
    await storage.save(access: 'old-access', refresh: 'old-refresh');
    var expired = 0;

    final plain = Dio(BaseOptions(baseUrl: 'https://example.test'));
    plain.httpClientAdapter = ScriptedAdapter((options) async {
      if (options.path.contains('/auth/refresh')) {
        return jsonBody(401, {'message': 'refresh rejected'});
      }
      return jsonBody(200, {'ok': true});
    });

    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = ScriptedAdapter(
      (_) async => jsonBody(401, {'message': 'expired'}),
    );
    dio.interceptors.add(
      AuthInterceptor(
        storage: storage,
        plainDio: plain,
        onSessionExpired: () => expired++,
      ),
    );

    await expectLater(
      dio.get<void>('/v1/snapshot'),
      throwsA(isA<DioException>()),
    );
    expect(await storage.accessToken, isNull);
    expect(expired, 1);
  });

  test('401 pada login tidak memicu refresh', () async {
    final storage = TokenStorage(MemoryKeyValueStore());
    await storage.save(access: 'old-access', refresh: 'old-refresh');
    var refreshCount = 0;

    final plain = Dio(BaseOptions(baseUrl: 'https://example.test'));
    plain.httpClientAdapter = ScriptedAdapter((options) async {
      if (options.path.contains('/auth/refresh')) refreshCount++;
      return jsonBody(200, {'ok': true});
    });

    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.httpClientAdapter = ScriptedAdapter(
      (_) async => jsonBody(401, {'message': 'salah'}),
    );
    dio.interceptors.add(AuthInterceptor(storage: storage, plainDio: plain));

    await expectLater(
      dio.post<void>('/auth/login', data: {'nomor': '0001', 'sandi': 'salah'}),
      throwsA(isA<DioException>()),
    );
    expect(refreshCount, 0);
    expect(await storage.accessToken, 'old-access');
  });
}

class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this._handle);
  final Future<ResponseBody> Function(RequestOptions options) _handle;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return _handle(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(int status, Object data) {
  return ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}
