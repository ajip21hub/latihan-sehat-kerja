import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/error/failure.dart';
import '../core/storage/token_storage.dart';
import '../core/sync/hari3.dart';
import '../features/peserta/domain/auth_session.dart';
import 'app_snapshot.dart';
import 'sehat_api.dart';

/// Jaringan dulu, cache JSON kalau putus.
///
/// Hari 3 mengganti [TokenStorage.cachedSnapshot] dengan drift dan
/// mengantre operasi yang gagal. Hari ini kegagalan jaringan dilempar
/// ke UI, tidak disimpan diam-diam.
class SehatRepository {
  SehatRepository({required this._klien, required this._storage});

  final KlienSehat _klien;
  final TokenStorage _storage;

  AppSnapshot? terakhir;

  Future<AuthSession?> pulihkan() async {
    final access = await _storage.accessToken;
    if (access == null) {
      terakhir = null;
      return null;
    }
    try {
      final snap = await _jaga(_klien.snapshot);
      await _ingat(snap);
      return AuthSession(peserta: snap.peserta);
    } on NetworkFailure {
      final cache = await _bacaCache();
      if (cache == null) rethrow;
      terakhir = cache.copyWith(fromCache: true);
      return AuthSession(peserta: cache.peserta, fromCache: true);
    } on UnauthorizedFailure {
      await _storage.clear();
      terakhir = null;
      return null;
    }
  }

  Future<AuthSession> masuk(String nomor, String sandi) async {
    final hasil = await _jaga(() => _klien.masuk(nomor.trim(), sandi));
    await _storage.save(access: hasil.accessToken, refresh: hasil.refreshToken);
    try {
      final snap = await _jaga(_klien.snapshot);
      await _ingat(snap);
      return AuthSession(peserta: snap.peserta);
    } on NetworkFailure {
      final snap = AppSnapshot.kosong(hasil.peserta, fromCache: true);
      await _ingat(snap);
      return AuthSession(peserta: hasil.peserta, fromCache: true);
    }
  }

  Future<AuthSession> muatUlang() async {
    final snap = await _jaga(_klien.snapshot);
    await _ingat(snap);
    return AuthSession(peserta: snap.peserta);
  }

  Future<void> keluar() async {
    await _storage.clear();
    terakhir = null;
  }

  void lupakanMemori() => terakhir = null;

  Future<void> kirimLayanan({
    required String clientId,
    required String jenis,
    required String faskes,
    required String keluhan,
  }) {
    return _kirim({
      'op': 'layanan',
      'clientId': clientId,
      'jenis': jenis,
      'faskes': faskes,
      'keluhan': keluhan,
      'tanggal': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// [expectedSaldoTotal] mengunci saldo yang dilihat pengguna.
  /// Kalau server sudah berubah, balasan `saldo_berubah` tidak boleh
  /// ditandai synced. Hari ini tidak ada baris antrean sama sekali.
  Future<void> kirimDana({
    required String clientId,
    required String jenis,
    required String alasan,
    required int nominal,
    required int expectedSaldoTotal,
  }) {
    return _kirim({
      'op': 'dana',
      'clientId': clientId,
      'jenis': jenis,
      'alasan': alasan,
      'nominal': nominal,
      'expectedSaldoTotal': expectedSaldoTotal,
    });
  }

  Future<void> _kirim(Map<String, dynamic> op) async {
    final HasilOutbox hasil;
    try {
      hasil = await _jaga(() => _klien.outbox(op));
    } on NetworkFailure {
      throw const NetworkFailure(Hari3.belumTerkirim);
    }
    if (!hasil.ok) {
      if (hasil.code == 'saldo_berubah' || hasil.code == 'nominal_berubah') {
        await _muatKalauBisa();
      }
      throw ServerFailure(hasil.message ?? 'Pengajuan ditolak.');
    }
    try {
      final snap = await _jaga(_klien.snapshot);
      await _ingat(snap);
    } on NetworkFailure {
      throw const NetworkFailure(
        'Sudah terkirim. Data di layar belum disegarkan.',
      );
    }
  }

  Future<void> _muatKalauBisa() async {
    try {
      final snap = await _jaga(_klien.snapshot);
      await _ingat(snap);
    } on Failure {
      // Konflik tetap dilaporkan ke UI meski refresh gagal.
    }
  }

  Future<void> _ingat(AppSnapshot snap) async {
    terakhir = snap;
    await _storage.saveSnapshot(jsonEncode(snap.toJson()));
  }

  Future<AppSnapshot?> _bacaCache() async {
    final raw = await _storage.cachedSnapshot;
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map) return null;
    return AppSnapshot.fromJson(decoded.cast<String, dynamic>());
  }

  Future<T> _jaga<T>(Future<T> Function() jalan) async {
    try {
      return await jalan();
    } on Failure {
      rethrow;
    } on DioException catch (e) {
      throw mapDioError(e);
    }
  }
}

final sehatRepositoryProvider = Provider<SehatRepository>((ref) {
  return SehatRepository(
    klien: ref.watch(klienSehatProvider),
    storage: ref.watch(tokenStorageProvider),
  );
});
