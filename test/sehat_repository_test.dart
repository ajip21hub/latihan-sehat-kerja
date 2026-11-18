import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehat_kerja/core/database/app_database.dart';
import 'package:sehat_kerja/core/error/failure.dart';
import 'package:sehat_kerja/core/storage/token_storage.dart';
import 'package:sehat_kerja/core/sync/outbox_sync.dart';
import 'package:sehat_kerja/data/app_snapshot.dart';
import 'package:sehat_kerja/data/sehat_api.dart';
import 'package:sehat_kerja/data/sehat_repository.dart';
import 'package:sehat_kerja/features/artikel/domain/artikel.dart';
import 'package:sehat_kerja/features/layanan/domain/pengajuan_layanan.dart';

void main() {
  test(
    'jaringan putus memakai snapshot tersimpan dan token tetap ada',
    () async {
      final storage = TokenStorage(MemoryKeyValueStore());
      await storage.save(access: 'akses', refresh: 'segar');
      await storage.saveSnapshot(jsonEncode(_contoh().toJson()));
      final db = _memori();
      final container = _wadah(
        storage,
        db,
        _Palsu()..snapshotError = const NetworkFailure(),
      );

      final sesi = await container.read(sehatRepositoryProvider).pulihkan();
      expect(sesi?.fromCache, isTrue);
      expect(sesi?.peserta.nama, 'Sari Wulandari');
      expect(await storage.accessToken, 'akses');
      expect(
        container.read(sehatRepositoryProvider).terakhir?.saldo.total,
        12500000,
      );
      expect(await db.bacaSnapshot(), isNotNull);
      container.dispose();
      await db.close();
    },
  );

  test('tanpa cache, jaringan putus tidak menghapus token', () async {
    final storage = TokenStorage(MemoryKeyValueStore());
    await storage.save(access: 'akses', refresh: 'segar');
    final db = _memori();
    final container = _wadah(
      storage,
      db,
      _Palsu()..snapshotError = const NetworkFailure(),
    );

    await expectLater(
      container.read(sehatRepositoryProvider).pulihkan(),
      throwsA(isA<NetworkFailure>()),
    );
    expect(await storage.accessToken, 'akses');
    container.dispose();
    await db.close();
  });

  test('401 menghapus sesi', () async {
    final storage = TokenStorage(MemoryKeyValueStore());
    await storage.save(access: 'akses', refresh: 'segar');
    await storage.saveSnapshot(jsonEncode(_contoh().toJson()));
    final db = _memori();
    final container = _wadah(
      storage,
      db,
      _Palsu()..snapshotError = const UnauthorizedFailure(),
    );

    final sesi = await container.read(sehatRepositoryProvider).pulihkan();
    expect(sesi, isNull);
    expect(await storage.accessToken, isNull);
    expect(await storage.cachedSnapshot, isNull);
    expect(await db.bacaSnapshot(), isNull);
    container.dispose();
    await db.close();
  });

  test('kirim saat offline masuk antrean dan tampil di layar', () async {
    final storage = TokenStorage(MemoryKeyValueStore());
    await storage.save(access: 'akses', refresh: 'segar');
    await storage.saveSnapshot(jsonEncode(_contoh().toJson()));
    final db = _memori();
    final container = _wadah(
      storage,
      db,
      _Palsu()
        ..snapshotError = const NetworkFailure()
        ..outboxError = const NetworkFailure(),
    );
    final repo = container.read(sehatRepositoryProvider);
    await repo.pulihkan();

    await repo.kirimLayanan(
      clientId: 'lokal-1',
      jenis: 'rawatJalan',
      faskes: 'Klinik Melati',
      keluhan: 'Demam tiga hari',
    );

    final antre = await db.belumTerkirim();
    expect(antre, hasLength(1));
    expect(antre.single.synced, isFalse);
    expect(repo.terakhir?.layanan.single.id, 'lokal-1');
    expect(repo.terakhir?.layanan.single.status, StatusPengajuan.diajukan);
    container.dispose();
    await db.close();
  });

  test('saldo_berubah tetap antre dan expected saldo ditulis ulang', () async {
    final storage = TokenStorage(MemoryKeyValueStore());
    await storage.save(access: 'akses', refresh: 'segar');
    final db = _memori();
    final palsu = _Palsu();
    final container = _wadah(storage, db, palsu);
    final repo = container.read(sehatRepositoryProvider);
    await repo.pulihkan();
    palsu.gantiSnapshot = _total(10000000);
    palsu.outboxHasil = const HasilOutbox(
      ok: false,
      code: 'saldo_berubah',
      message: 'Saldo berubah saat pengajuan dikirim. Jangan tandai synced.',
      saldoTotal: 10000000,
    );

    await expectLater(
      repo.kirimDana(
        clientId: 'dana-1',
        jenis: 'sebagian10',
        alasan: 'Persiapan masa tua',
        nominal: 1250000,
        expectedSaldoTotal: 12500000,
      ),
      throwsA(isA<ServerFailure>()),
    );

    final antre = await db.belumTerkirim();
    expect(antre, hasLength(1));
    expect(jsonDecode(antre.single.payload)['expectedSaldoTotal'], 10000000);
    expect(repo.terakhir?.saldo.total, 10000000);
    expect(palsu.snapshotDipanggil, 2);
    container.dispose();
    await db.close();
  });

  test('ditolak tidak diantre ulang', () async {
    final storage = TokenStorage(MemoryKeyValueStore());
    await storage.save(access: 'akses', refresh: 'segar');
    final db = _memori();
    final palsu = _Palsu()
      ..outboxHasil = const HasilOutbox(
        ok: false,
        code: 'ditolak',
        message: 'Belum 10 tahun.',
      );
    final container = _wadah(storage, db, palsu);
    final repo = container.read(sehatRepositoryProvider);
    await repo.pulihkan();

    await expectLater(
      repo.kirimDana(
        clientId: 'dana-2',
        jenis: 'sebagian10',
        alasan: 'Butuh biaya',
        nominal: 320000,
        expectedSaldoTotal: 12500000,
      ),
      throwsA(isA<ServerFailure>()),
    );
    expect(await db.belumTerkirim(), isEmpty);
    final semua = await db.select(db.outboxRows).get();
    expect(semua.single.batal, isTrue);
    container.dispose();
    await db.close();
  });

  test('sidik berubah saat permintaan membuat baris tetap antre', () async {
    final db = _memori();
    const awal = '{"op":"layanan","clientId":"lokal-1"}';
    final palsu = _Palsu();
    palsu.sebelumBalas = () async {
      await db.perbaruiPayload(
        clientId: 'lokal-1',
        payload: '{"op":"layanan","clientId":"lokal-1","baru":true}',
        sidik: 'berubah',
      );
    };
    final sync = OutboxSync(
      db: db,
      klien: palsu,
      muatSnapshot: () async => null,
    );
    await db.antre(
      clientId: 'lokal-1',
      nomor: '0001',
      payload: awal,
      sidik: awal,
      dibuat: 1,
    );

    final laporan = await sync.sekarang();
    expect(laporan.terkirim, 0);
    final sisa = await db.belumTerkirim();
    expect(sisa, hasLength(1));
    expect(sisa.single.sidik, 'berubah');
    await db.close();
  });

  test('artikel online mengganti cache dan menghapus id lama', () async {
    final db = _memori();
    await db.gantiArtikel([
      ArtikelCacheCompanion.insert(
        id: 'lama',
        judul: 'Lama',
        ringkas: 'Lama',
        isi: 'Lama',
        diperbarui: 1,
        disimpan: 1,
      ),
    ]);
    final palsu = _Palsu()
      ..artikelDaftar = const [
        Artikel(
          id: 'baru',
          judul: 'Baru',
          ringkas: 'Ringkas',
          isi: 'Isi',
          diperbarui: 2,
        ),
      ];
    final container = _wadah(TokenStorage(MemoryKeyValueStore()), db, palsu);
    final hasil = await container.read(sehatRepositoryProvider).muatArtikel();
    expect(hasil.fromCache, isFalse);
    expect(hasil.daftar.map((a) => a.id), ['baru']);
    expect((await db.bacaArtikel()).map((r) => r.id), ['baru']);
    container.dispose();
    await db.close();
  });

  test('artikel offline memakai cache', () async {
    final db = _memori();
    await db.gantiArtikel([
      ArtikelCacheCompanion.insert(
        id: 'kelas-rawat',
        judul: 'Kelas',
        ringkas: 'Ringkas',
        isi: 'Isi panjang',
        diperbarui: 9,
        disimpan: 1,
      ),
    ]);
    final container = _wadah(
      TokenStorage(MemoryKeyValueStore()),
      db,
      _Palsu()..artikelError = const NetworkFailure(),
    );
    final hasil = await container.read(sehatRepositoryProvider).muatArtikel();
    expect(hasil.fromCache, isTrue);
    expect(hasil.daftar.single.isi, 'Isi panjang');
    container.dispose();
    await db.close();
  });

  test('artikel offline tanpa cache melempar jaringan', () async {
    final db = _memori();
    final container = _wadah(
      TokenStorage(MemoryKeyValueStore()),
      db,
      _Palsu()..artikelError = const NetworkFailure(),
    );
    await expectLater(
      container.read(sehatRepositoryProvider).muatArtikel(),
      throwsA(isA<NetworkFailure>()),
    );
    container.dispose();
    await db.close();
  });
}

AppDatabase _memori() => AppDatabase(NativeDatabase.memory());

ProviderContainer _wadah(
  TokenStorage storage,
  AppDatabase db,
  KlienSehat klien,
) {
  return ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(storage),
      appDatabaseProvider.overrideWithValue(db),
      klienSehatProvider.overrideWithValue(klien),
    ],
  );
}

AppSnapshot _contoh() => _total(12500000);

AppSnapshot _total(int total) {
  return AppSnapshot.fromJson({
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
      'iuranPeserta': total,
      'iuranPemberiKerja': 0,
      'pengembangan': 0,
      'total': total,
    },
    'layanan': <Map<String, dynamic>>[],
    'dana': <Map<String, dynamic>>[],
  });
}

class _Palsu implements KlienSehat {
  Failure? snapshotError;
  Failure? artikelError;
  List<Artikel> artikelDaftar = const [];
  Failure? outboxError;
  HasilOutbox? outboxHasil;
  AppSnapshot? gantiSnapshot;
  Future<void> Function()? sebelumBalas;
  int snapshotDipanggil = 0;

  @override
  Future<HasilMasuk> masuk(String nomor, String sandi) async {
    return HasilMasuk(
      accessToken: 'akses',
      refreshToken: 'segar',
      peserta: _contoh().peserta,
    );
  }

  @override
  Future<HasilOutbox> outbox(Map<String, dynamic> op) async {
    final semua = await outboxSemua([op]);
    return semua.first;
  }

  @override
  Future<List<HasilOutbox>> outboxSemua(List<Map<String, dynamic>> ops) async {
    final sebelum = sebelumBalas;
    if (sebelum != null) await sebelum();
    final error = outboxError;
    if (error != null) throw error;
    return [for (final _ in ops) outboxHasil ?? const HasilOutbox(ok: true)];
  }

  @override
  Future<AppSnapshot> snapshot() async {
    snapshotDipanggil++;
    final error = snapshotError;
    if (error != null) throw error;
    return gantiSnapshot ?? _contoh();
  }

  @override
  Future<List<Artikel>> artikel() async {
    final error = artikelError;
    if (error != null) throw error;
    return artikelDaftar;
  }
}
