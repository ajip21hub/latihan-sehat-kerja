import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehat_kerja/core/database/app_database.dart';

void main() {
  test('watchMenunggu menghitung baris yang belum selesai', () async {
    final db = AppDatabase(NativeDatabase.memory());
    expect(await db.watchMenunggu().first, 0);
    await db.antre(
      clientId: 'a',
      nomor: '0001',
      payload: '{}',
      sidik: '{}',
      dibuat: 1,
    );
    await db.antre(
      clientId: 'b',
      nomor: '0001',
      payload: '{}',
      sidik: '{}',
      dibuat: 2,
    );
    expect(await db.watchMenunggu().first, 2);
    expect(await db.tandaiSynced('a', '{}'), 1);
    expect(await db.watchMenunggu().first, 1);
    await db.tandaiBatal('b');
    expect(await db.watchMenunggu().first, 0);
    await db.close();
  });

  test('migrasi v1 menambah batal dan baris lama tetap ada', () async {
    final file = File(
      '${Directory.systemTemp.path}/sehat-migrasi-${DateTime.now().microsecondsSinceEpoch}.sqlite',
    );
    final lama = _BasisLama(NativeDatabase(file));
    await lama.customStatement(
      "INSERT INTO outbox_rows (client_id, nomor, payload, sidik, synced, dibuat) "
      "VALUES ('c', '0001', '{}', '{}', 0, 1)",
    );
    await lama.close();

    final baru = AppDatabase(NativeDatabase(file));
    final rows = await baru.belumTerkirim();
    expect(rows.single.clientId, 'c');
    expect(rows.single.batal, isFalse);
    await baru.close();
    if (await file.exists()) await file.delete();
  });
}

/// Skema sebelum kolom `batal` ada. `user_version` menjadi 1.
class _BasisLama extends AppDatabase {
  _BasisLama(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.database.customStatement('''
        CREATE TABLE snapshot_cache (
          nomor TEXT NOT NULL PRIMARY KEY,
          isi TEXT NOT NULL
        )
      ''');
      await m.database.customStatement('''
        CREATE TABLE outbox_rows (
          client_id TEXT NOT NULL PRIMARY KEY,
          nomor TEXT NOT NULL,
          payload TEXT NOT NULL,
          sidik TEXT NOT NULL,
          synced INTEGER NOT NULL DEFAULT 0,
          dibuat INTEGER NOT NULL
        )
      ''');
    },
  );
}
