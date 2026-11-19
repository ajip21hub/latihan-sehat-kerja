import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehat_kerja/app.dart';
import 'package:sehat_kerja/core/database/app_database.dart';
import 'package:sehat_kerja/core/error/failure.dart';
import 'package:sehat_kerja/core/storage/token_storage.dart';
import 'package:sehat_kerja/core/sync/status_socket.dart';
import 'package:sehat_kerja/data/app_snapshot.dart';
import 'package:sehat_kerja/data/sehat_api.dart';
import 'package:sehat_kerja/features/artikel/domain/artikel.dart';

void main() {
  testWidgets(
    'pengguna baru melihat onboarding terlebih dahulu, lalu masuk ke login',
    (tester) async {
      final store = MemoryKeyValueStore();
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            keyValueStoreProvider.overrideWithValue(store),
            tokenStorageProvider.overrideWithValue(TokenStorage(store)),
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const SehatKerjaApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Layanan Kesehatan Terpadu'), findsOneWidget);
      expect(find.text('Lewati'), findsAtLeastNWidgets(1));

      await tester.tap(find.text('Lewati').first);
      await tester.pumpAndSettle();

      expect(find.text('Latihan SehatKerja'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
    },
  );

  testWidgets(
    'belum masuk tetapi sudah onboarding langsung menampilkan halaman login',
    (tester) async {
      final store = MemoryKeyValueStore();
      await store.write('onboarding_selesai', 'true');
      final db = AppDatabase(NativeDatabase.memory());
      addTearDown(db.close);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            keyValueStoreProvider.overrideWithValue(store),
            tokenStorageProvider.overrideWithValue(TokenStorage(store)),
            appDatabaseProvider.overrideWithValue(db),
          ],
          child: const SehatKerjaApp(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Latihan SehatKerja'), findsOneWidget);
      expect(find.text('Masuk'), findsOneWidget);
    },
  );

  testWidgets('pengajuan offline tampil di beranda dan tetap antre', (
    tester,
  ) async {
    final store = MemoryKeyValueStore();
    await store.write('onboarding_selesai', 'true');
    final storage = TokenStorage(store);
    await storage.save(access: 'akses', refresh: 'segar');
    await storage.saveSnapshot(jsonEncode(_snap().toJson()));
    final db = AppDatabase(NativeDatabase.memory());
    await db.antre(
      clientId: 'lokal-1',
      nomor: '0001',
      payload: jsonEncode({
        'op': 'layanan',
        'clientId': 'lokal-1',
        'jenis': 'rawatJalan',
        'faskes': 'Klinik Melati',
        'keluhan': 'Demam tiga hari',
        'tanggal': '2026-11-18T00:00:00.000Z',
      }),
      sidik: 'sidik',
      dibuat: 1,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          keyValueStoreProvider.overrideWithValue(store),
          tokenStorageProvider.overrideWithValue(storage),
          appDatabaseProvider.overrideWithValue(db),
          klienSehatProvider.overrideWithValue(_Putus()),
          statusSocketProvider.overrideWith((ref) {}),
        ],
        child: const SehatKerjaApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 pengajuan menunggu kirim'), findsOneWidget);
    await tester.tap(find.text('Kirim sekarang'));
    await tester.pumpAndSettle();
    expect(await db.belumTerkirim(), hasLength(1));
    expect(find.text('1 pengajuan menunggu kirim'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(milliseconds: 1));
    await db.close();
  });
}

AppSnapshot _snap() {
  return AppSnapshot.fromJson(const {
    'peserta': {
      'nomor': '0001',
      'nama': 'Sari Wulandari',
      'nik': '3275011201900001',
      'kelas': 'dua',
      'faskes': 'Klinik Melati',
      'tahunKepesertaan': 11,
      'aktif': true,
    },
    'saldo': {
      'iuranPeserta': 12500000,
      'iuranPemberiKerja': 0,
      'pengembangan': 0,
      'total': 12500000,
    },
    'layanan': <Map<String, dynamic>>[],
    'dana': <Map<String, dynamic>>[],
  });
}

class _Putus implements KlienSehat {
  @override
  Future<HasilMasuk> masuk(String nomor, String sandi) {
    throw UnimplementedError();
  }

  @override
  Future<HasilOutbox> outbox(Map<String, dynamic> op) {
    throw const NetworkFailure();
  }

  @override
  Future<List<HasilOutbox>> outboxSemua(List<Map<String, dynamic>> ops) {
    throw const NetworkFailure();
  }

  @override
  Future<AppSnapshot> snapshot() {
    throw const NetworkFailure();
  }

  @override
  Future<List<Artikel>> artikel() {
    throw const NetworkFailure();
  }
}
