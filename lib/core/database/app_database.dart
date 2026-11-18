import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

/// Snapshot terakhir per nomor peserta. UI tetap membaca [AppSnapshot].
class SnapshotCache extends Table {
  @override
  String get tableName => 'snapshot_cache';

  TextColumn get nomor => text()();
  TextColumn get isi => text()();

  @override
  Set<Column<Object>> get primaryKey => {nomor};
}

/// Operasi yang belum pasti sampai di server.
///
/// [sidik] adalah teks payload saat dikirim. Baris hanya ditandai
/// synced kalau sidik di database masih sama. Kalau pengguna mengubah
/// payload selagi permintaan berjalan, baris tetap antre.
class OutboxRows extends Table {
  @override
  String get tableName => 'outbox_rows';

  TextColumn get clientId => text().named('client_id')();
  TextColumn get nomor => text()();
  TextColumn get payload => text()();
  TextColumn get sidik => text()();
  BoolColumn get synced => boolean().withDefault(const Constant(false))();
  BoolColumn get batal => boolean().withDefault(const Constant(false))();
  IntColumn get dibuat => integer()();

  @override
  Set<Column<Object>> get primaryKey => {clientId};
}

/// Bacaan yang terakhir berhasil diunduh. Diganti utuh tiap sinkron sukses.
class ArtikelCache extends Table {
  @override
  String get tableName => 'artikel_cache';

  TextColumn get id => text()();
  TextColumn get judul => text()();
  TextColumn get ringkas => text()();
  TextColumn get isi => text()();
  IntColumn get diperbarui => integer()();
  IntColumn get disimpan => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [SnapshotCache, OutboxRows, ArtikelCache])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
    : super(
        executor ??
            driftDatabase(
              name: 'sehat_kerja',
              native: const DriftNativeOptions(shareAcrossIsolates: true),
              // Chrome menolak membuka database kalau opsi ini kosong.
              // Berkasnya ada di web/ dan ikut versi drift 2.35.4.
              web: DriftWebOptions(
                sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                driftWorker: Uri.parse('drift_worker.js'),
              ),
            ),
      );

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(outboxRows, outboxRows.batal);
      }
      if (from < 3) {
        await m.createTable(artikelCache);
      }
    },
  );

  Future<void> simpanSnapshot(String nomor, String isi) {
    return into(snapshotCache).insertOnConflictUpdate(
      SnapshotCacheCompanion.insert(nomor: nomor, isi: isi),
    );
  }

  Future<String?> bacaSnapshot() async {
    final row = await (select(snapshotCache)..limit(1)).getSingleOrNull();
    return row?.isi;
  }

  Future<void> antre({
    required String clientId,
    required String nomor,
    required String payload,
    required String sidik,
    required int dibuat,
  }) {
    return into(outboxRows).insertOnConflictUpdate(
      OutboxRowsCompanion.insert(
        clientId: clientId,
        nomor: nomor,
        payload: payload,
        sidik: sidik,
        dibuat: dibuat,
      ),
    );
  }

  Future<List<OutboxRow>> belumTerkirim() {
    return (select(outboxRows)
          ..where((t) => t.synced.equals(false) & t.batal.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.dibuat)]))
        .get();
  }

  Stream<int> watchMenunggu() {
    final jumlah = outboxRows.clientId.count();
    final query = selectOnly(outboxRows)
      ..addColumns([jumlah])
      ..where(outboxRows.synced.equals(false) & outboxRows.batal.equals(false));
    return query.map((row) => row.read(jumlah) ?? 0).watchSingle();
  }

  Future<void> perbaruiPayload({
    required String clientId,
    required String payload,
    required String sidik,
  }) {
    return (update(
      outboxRows,
    )..where((t) => t.clientId.equals(clientId))).write(
      OutboxRowsCompanion(payload: Value(payload), sidik: Value(sidik)),
    );
  }

  /// Mengembalikan jumlah baris yang benar-benar berubah.
  Future<int> tandaiSynced(String clientId, String sidik) {
    return (update(outboxRows)
          ..where((t) => t.clientId.equals(clientId) & t.sidik.equals(sidik)))
        .write(const OutboxRowsCompanion(synced: Value(true)));
  }

  Future<void> tandaiBatal(String clientId) {
    return (update(
      outboxRows,
    )..where((t) => t.clientId.equals(clientId))).write(
      const OutboxRowsCompanion(batal: Value(true), synced: Value(true)),
    );
  }

  Future<void> hapusSemua() async {
    await delete(outboxRows).go();
    await delete(snapshotCache).go();
  }

  /// Mengganti seluruh cache. Id yang tidak ada di [baris] ikut terhapus.
  Future<void> gantiArtikel(List<ArtikelCacheCompanion> baris) {
    return transaction(() async {
      await delete(artikelCache).go();
      if (baris.isEmpty) return;
      await batch((b) => b.insertAll(artikelCache, baris));
    });
  }

  Future<List<ArtikelCacheData>> bacaArtikel() {
    return (select(artikelCache)..orderBy([
          (t) => OrderingTerm.desc(t.diperbarui),
          (t) => OrderingTerm.asc(t.judul),
        ]))
        .get();
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
