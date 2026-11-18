import 'dart:convert';

import 'package:dio/dio.dart';

import '../../data/app_snapshot.dart';
import '../../data/sehat_api.dart';
import '../database/app_database.dart';
import '../error/failure.dart';

class LaporanSync {
  const LaporanSync({required this.terkirim, required this.gagal});

  static const kosong = LaporanSync(terkirim: 0, gagal: {});

  final int terkirim;
  final Map<String, String> gagal;
}

/// Mengirim semua baris `synced = false`.
///
/// Kalau pemanggilan kedua masuk selagi putaran pertama masih jalan,
/// putaran itu diulang sekali lagi supaya baris baru tidak tertinggal.
class OutboxSync {
  OutboxSync({
    required this._db,
    required this._klien,
    required this._muatSnapshot,
  });

  final AppDatabase _db;
  final KlienSehat _klien;
  final Future<AppSnapshot?> Function() _muatSnapshot;

  Future<LaporanSync>? _berjalan;
  var _lagi = false;

  Future<LaporanSync> sekarang() {
    final ikut = _berjalan;
    if (ikut != null) {
      _lagi = true;
      return ikut;
    }
    late final Future<LaporanSync> tugas;
    tugas = _putar().whenComplete(() {
      if (identical(_berjalan, tugas)) _berjalan = null;
    });
    _berjalan = tugas;
    return tugas;
  }

  Future<LaporanSync> _putar() async {
    final gagal = <String, String>{};
    var terkirim = 0;
    while (true) {
      _lagi = false;
      final putaran = await _satuPutaran();
      terkirim += putaran.terkirim;
      gagal.addAll(putaran.gagal);
      if (!_lagi) break;
    }
    return LaporanSync(terkirim: terkirim, gagal: Map.unmodifiable(gagal));
  }

  Future<LaporanSync> _satuPutaran() async {
    final baris = await _db.belumTerkirim();
    if (baris.isEmpty) return LaporanSync.kosong;

    final siap = <OutboxRow>[];
    final ops = <Map<String, dynamic>>[];
    final sidikTerkirim = <String>[];
    for (final row in baris) {
      final Object? decoded;
      try {
        decoded = jsonDecode(row.payload);
      } on FormatException {
        await _db.tandaiBatal(row.clientId);
        continue;
      }
      if (decoded is! Map) {
        await _db.tandaiBatal(row.clientId);
        continue;
      }
      siap.add(row);
      ops.add(decoded.cast<String, dynamic>());
      sidikTerkirim.add(row.sidik);
    }
    if (ops.isEmpty) return LaporanSync.kosong;

    final List<HasilOutbox> results;
    try {
      results = await _klien.outboxSemua(ops);
    } on DioException catch (e) {
      final failure = mapDioError(e);
      if (failure is NetworkFailure) return LaporanSync.kosong;
      throw failure;
    } on NetworkFailure {
      return LaporanSync.kosong;
    } on FormatException {
      return LaporanSync.kosong;
    }
    if (results.length != ops.length) return LaporanSync.kosong;

    final gagal = <String, String>{};
    var terkirim = 0;
    var perluMuat = false;
    for (var i = 0; i < results.length; i++) {
      final hasil = results[i];
      final clientId = siap[i].clientId;
      if (hasil.ok || hasil.alreadyApplied) {
        final n = await _db.tandaiSynced(clientId, sidikTerkirim[i]);
        if (n > 0) terkirim++;
        perluMuat = true;
        continue;
      }
      if (hasil.code == 'saldo_berubah' || hasil.code == 'nominal_berubah') {
        await _tulisUlangDana(siap[i], hasil);
        gagal[clientId] = hasil.message ?? 'Saldo berubah. Hitung ulang.';
        perluMuat = true;
        continue;
      }
      await _db.tandaiBatal(clientId);
      gagal[clientId] = hasil.message ?? 'Pengajuan ditolak.';
      perluMuat = true;
    }
    if (perluMuat) await _muatSnapshot();
    return LaporanSync(terkirim: terkirim, gagal: Map.unmodifiable(gagal));
  }

  Future<void> _tulisUlangDana(OutboxRow row, HasilOutbox hasil) async {
    final decoded = jsonDecode(row.payload);
    if (decoded is! Map) return;
    final payload = Map<String, dynamic>.from(decoded);
    var total = hasil.saldoTotal;
    if (total == null) {
      final segar = await _muatSnapshot();
      total = segar?.saldo.total;
    }
    if (total != null) payload['expectedSaldoTotal'] = total;
    if (hasil.code == 'nominal_berubah' && hasil.nominalBenar != null) {
      payload['nominal'] = hasil.nominalBenar;
    }
    final teks = jsonEncode(payload);
    await _db.perbaruiPayload(
      clientId: row.clientId,
      payload: teks,
      sidik: teks,
    );
  }
}
