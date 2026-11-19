import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/database/app_database.dart';
import '../core/error/failure.dart';
import '../core/format.dart';
import '../core/storage/token_storage.dart';
import '../core/sync/outbox_sync.dart';
import '../core/sync/status_terapkan.dart';
import '../features/artikel/domain/artikel.dart';
import '../features/dana/domain/pengajuan_dana.dart';
import '../features/iuran/domain/iuran.dart';
import '../features/layanan/domain/pengajuan_layanan.dart';
import '../features/peserta/domain/auth_session.dart';
import 'app_snapshot.dart';
import 'sehat_api.dart';

/// Jaringan dulu. Kalau putus, layar memakai snapshot drift.
/// Pengajuan baru langsung masuk tabel outbox, lalu dikirim.
class SehatRepository {
  SehatRepository({
    required this._klien,
    required this._storage,
    required this._db,
  }) {
    _sync = OutboxSync(db: _db, klien: _klien, muatSnapshot: _muatTanpaSync);
  }

  final KlienSehat _klien;
  final TokenStorage _storage;
  final AppDatabase _db;
  late final OutboxSync _sync;

  AppSnapshot? _dasar;
  AppSnapshot? terakhir;

  Future<AuthSession?> pulihkan() async {
    final access = await _storage.accessToken;
    if (access == null) {
      terakhir = null;
      _dasar = null;
      return null;
    }
    try {
      final snap = await _jaga(_klien.snapshot);
      await _ingat(snap);
      await kirimAntrean();
      await _artikelDiam();
      return AuthSession(peserta: terakhir!.peserta);
    } on NetworkFailure {
      final cache = await _bacaCache();
      if (cache == null) rethrow;
      _dasar = cache.copyWith(fromCache: true);
      terakhir = await _denganAntrean(_dasar!);
      return AuthSession(peserta: terakhir!.peserta, fromCache: true);
    } on UnauthorizedFailure {
      await _hapusLokal();
      return null;
    }
  }

  Future<AuthSession> masuk(String nomor, String sandi) async {
    final hasil = await _jaga(() => _klien.masuk(nomor.trim(), sandi));
    await _storage.save(access: hasil.accessToken, refresh: hasil.refreshToken);
    await _db.hapusSemua();
    _dasar = null;
    terakhir = null;
    try {
      final snap = await _jaga(_klien.snapshot);
      await _ingat(snap);
      await kirimAntrean();
      await _artikelDiam();
      return AuthSession(peserta: terakhir!.peserta);
    } on NetworkFailure {
      final snap = AppSnapshot.kosong(hasil.peserta, fromCache: true);
      await _ingat(snap, fromCache: true);
      return AuthSession(peserta: hasil.peserta, fromCache: true);
    }
  }

  Future<AuthSession> muatUlang() async {
    final snap = await _jaga(_klien.snapshot);
    await _ingat(snap);
    await kirimAntrean();
    await _artikelDiam();
    return AuthSession(
      peserta: terakhir!.peserta,
      fromCache: terakhir!.fromCache,
    );
  }

  /// Jaringan dulu, lalu ganti cache. Putus: baca `artikel_cache`.
  /// Id yang tidak kembali dari server dihapus hanya kalau unduhan sukses.
  Future<DaftarArtikel> muatArtikel() async {
    try {
      final daftar = await _jaga(_klien.artikel);
      final sekarang = DateTime.now().millisecondsSinceEpoch;
      await _db.gantiArtikel([
        for (final artikel in daftar)
          ArtikelCacheCompanion.insert(
            id: artikel.id,
            judul: artikel.judul,
            ringkas: artikel.ringkas,
            isi: artikel.isi,
            diperbarui: artikel.diperbarui,
            disimpan: sekarang,
          ),
      ]);
      return DaftarArtikel(daftar: await _bacaArtikelLokal(), fromCache: false);
    } on NetworkFailure {
      final cache = await _bacaArtikelLokal();
      if (cache.isEmpty) rethrow;
      return DaftarArtikel(daftar: cache, fromCache: true);
    }
  }

  Future<void> _artikelDiam() async {
    try {
      await muatArtikel();
    } on Failure {
      return;
    }
  }

  Future<List<Artikel>> _bacaArtikelLokal() async {
    final rows = await _db.bacaArtikel();
    return [
      for (final row in rows)
        Artikel(
          id: row.id,
          judul: row.judul,
          ringkas: row.ringkas,
          isi: row.isi,
          diperbarui: row.diperbarui,
        ),
    ];
  }

  Future<void> keluar() => _hapusLokal();

  void lupakanMemori() {
    terakhir = null;
    _dasar = null;
  }

  Future<LaporanSync> kirimAntrean() async {
    try {
      return await _sync.sekarang();
    } on UnauthorizedFailure {
      await _hapusLokal();
      rethrow;
    }
  }

  Future<void> kirimLayanan({
    required String clientId,
    required String jenis,
    required String faskes,
    required String keluhan,
  }) {
    return _antre({
      'op': 'layanan',
      'clientId': clientId,
      'jenis': jenis,
      'faskes': faskes,
      'keluhan': keluhan,
      'tanggal': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> kirimDana({
    required String clientId,
    required String jenis,
    required String alasan,
    required int nominal,
    required int expectedSaldoTotal,
  }) {
    return _antre({
      'op': 'dana',
      'clientId': clientId,
      'jenis': jenis,
      'alasan': alasan,
      'nominal': nominal,
      'expectedSaldoTotal': expectedSaldoTotal,
    });
  }

  /// Role B. Server menolak dengan `peran_ditolak` kalau bukan mandiri aktif.
  Future<void> kirimBayarIuran({
    required String clientId,
    required String tagihanId,
    required int nominal,
  }) {
    return _antre({
      'op': 'bayarIuran',
      'clientId': clientId,
      'tagihanId': tagihanId,
      'nominal': nominal,
    });
  }

  Future<void> kirimUbahKelas({
    required String clientId,
    required String kelas,
  }) {
    return _antre({'op': 'ubahKelas', 'clientId': clientId, 'kelas': kelas});
  }

  /// Status dari WebSocket. `true` kalau ada baris yang berubah.
  Future<bool> terapkanPeristiwa(PeristiwaStatus peristiwa) async {
    final dasar = _dasar;
    final layar = terakhir;
    if (dasar == null || layar == null) return false;
    final dasarBaru = terapkanStatus(
      dasar,
      id: peristiwa.id,
      clientId: peristiwa.clientId,
      status: peristiwa.status,
    );
    final layarBaru = terapkanStatus(
      layar,
      id: peristiwa.id,
      clientId: peristiwa.clientId,
      status: peristiwa.status,
    );
    if (identical(dasarBaru, dasar) && identical(layarBaru, layar)) {
      return false;
    }
    if (!identical(dasarBaru, dasar)) {
      _dasar = dasarBaru;
      await _simpanJson(dasarBaru);
    }
    terakhir = layarBaru;
    return true;
  }

  Future<void> _antre(Map<String, dynamic> op) async {
    final snap = _dasar;
    if (snap == null) {
      throw const ServerFailure('Data peserta belum ada. Cek sesi lagi.');
    }
    final clientId = '${op['clientId']}';
    final teks = jsonEncode(op);
    await _db.antre(
      clientId: clientId,
      nomor: snap.peserta.nomor,
      payload: teks,
      sidik: teks,
      dibuat: DateTime.now().millisecondsSinceEpoch,
    );
    terakhir = await _denganAntrean(snap);
    final laporan = await kirimAntrean();
    final pesan = laporan.gagal[clientId];
    if (pesan != null) throw ServerFailure(pesan);
  }

  Future<void> _ingat(AppSnapshot snap, {bool fromCache = false}) async {
    _dasar = snap.copyWith(fromCache: fromCache);
    await _simpanJson(_dasar!);
    terakhir = await _denganAntrean(_dasar!);
  }

  Future<void> _simpanJson(AppSnapshot snap) async {
    final json = jsonEncode(snap.toJson());
    await _db.simpanSnapshot(snap.peserta.nomor, json);
    await _storage.saveSnapshot(json);
  }

  Future<AppSnapshot?> _muatTanpaSync() async {
    try {
      final snap = await _jaga(_klien.snapshot);
      await _ingat(snap);
      return _dasar;
    } on NetworkFailure {
      return _dasar;
    }
  }

  Future<AppSnapshot?> _bacaCache() async {
    final dariDrift = await _db.bacaSnapshot();
    final snap = _parse(dariDrift) ?? _parse(await _storage.cachedSnapshot);
    if (snap == null) return null;
    if (dariDrift == null || dariDrift.isEmpty) {
      await _db.simpanSnapshot(snap.peserta.nomor, jsonEncode(snap.toJson()));
    }
    return snap;
  }

  AppSnapshot? _parse(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return AppSnapshot.fromJson(decoded.cast<String, dynamic>());
    } on FormatException {
      return null;
    }
  }

  Future<AppSnapshot> _denganAntrean(AppSnapshot dasar) async {
    final baris = await _db.belumTerkirim();
    if (baris.isEmpty) return dasar;
    var layanan = dasar.layanan;
    var dana = dasar.dana;
    var tagihan = dasar.tagihan;
    for (final row in baris) {
      final Object? decoded;
      try {
        decoded = jsonDecode(row.payload);
      } on FormatException {
        continue;
      }
      if (decoded is! Map) continue;
      final op = decoded.cast<String, dynamic>();
      try {
        if (op['op'] == 'layanan') {
          final sudah = layanan.any(
            (item) => item.id == row.clientId || item.clientId == row.clientId,
          );
          if (sudah) continue;
          layanan = [_layananLokal(dasar, op), ...layanan];
        } else if (op['op'] == 'dana') {
          final sudah = dana.any(
            (item) => item.id == row.clientId || item.clientId == row.clientId,
          );
          if (sudah) continue;
          dana = [_danaLokal(dasar, op), ...dana];
        } else if (op['op'] == 'bayarIuran') {
          final id = '${op['tagihanId']}';
          tagihan = [
            for (final item in tagihan)
              item.id == id && item.bisaDibayar
                  ? item.copyWith(status: StatusTagihan.menunggu)
                  : item,
          ];
        }
      } on ArgumentError {
        continue;
      } on FormatException {
        continue;
      } on TypeError {
        continue;
      }
    }
    if (identical(layanan, dasar.layanan) &&
        identical(dana, dasar.dana) &&
        identical(tagihan, dasar.tagihan)) {
      return dasar;
    }
    return dasar.copyWith(layanan: layanan, dana: dana, tagihan: tagihan);
  }

  PengajuanLayanan _layananLokal(AppSnapshot dasar, Map<String, dynamic> op) {
    return PengajuanLayanan(
      id: '${op['clientId']}',
      clientId: '${op['clientId']}',
      nomorPeserta: dasar.peserta.nomor,
      jenis: JenisLayanan.values.byName('${op['jenis']}'),
      faskes: '${op['faskes']}',
      tanggal: DateTime.parse('${op['tanggal']}'),
      keluhan: '${op['keluhan']}',
      status: StatusPengajuan.diajukan,
    );
  }

  PengajuanDana _danaLokal(AppSnapshot dasar, Map<String, dynamic> op) {
    final nominal = (op['nominal'] as num).toInt();
    return PengajuanDana(
      id: '${op['clientId']}',
      clientId: '${op['clientId']}',
      nomorPeserta: dasar.peserta.nomor,
      jenis: JenisAmbil.values.byName('${op['jenis']}'),
      nominal: nominal,
      alasan: '${op['alasan']}',
      status: StatusPengajuan.diajukan,
      perkiraanHariKerja: perkiraanHariKerja(nominal),
    );
  }

  Future<void> _hapusLokal() async {
    await _storage.clear();
    await _db.hapusSemua();
    terakhir = null;
    _dasar = null;
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
    db: ref.watch(appDatabaseProvider),
  );
});

final menungguProvider = StreamProvider<int>((ref) {
  return ref.watch(appDatabaseProvider).watchMenunggu();
});
