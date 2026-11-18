import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Penyimpanan kecil. Produksi memakai secure storage; test memakai memori.
abstract class KeyValueStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class MemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _values = {};

  @override
  Future<String?> read(String key) async => _values[key];

  @override
  Future<void> write(String key, String value) async => _values[key] = value;

  @override
  Future<void> delete(String key) async => _values.remove(key);
}

class SecureKeyValueStore implements KeyValueStore {
  SecureKeyValueStore([FlutterSecureStorage? storage])
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class TokenStorage {
  TokenStorage(this._store);
  final KeyValueStore _store;

  static const _accessKey = 'access_token';
  static const _refreshKey = 'refresh_token';

  /// Cadangan JSON. Drift adalah sumber utama; kunci ini dipakai
  /// sekali untuk sesi yang tersimpan sebelum tabel snapshot ada.
  static const _snapshotKey = 'cached_snapshot';

  Future<String?> get accessToken => _store.read(_accessKey);
  Future<String?> get refreshToken => _store.read(_refreshKey);
  Future<String?> get cachedSnapshot => _store.read(_snapshotKey);

  Future<void> save({required String access, required String refresh}) async {
    await _store.write(_accessKey, access);
    await _store.write(_refreshKey, refresh);
  }

  Future<void> saveSnapshot(String json) => _store.write(_snapshotKey, json);

  Future<void> clear() async {
    await _store.delete(_accessKey);
    await _store.delete(_refreshKey);
    await _store.delete(_snapshotKey);
  }
}

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => TokenStorage(SecureKeyValueStore()),
);
