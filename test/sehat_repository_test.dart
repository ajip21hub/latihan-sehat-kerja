import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehat_kerja/core/error/failure.dart';
import 'package:sehat_kerja/core/storage/token_storage.dart';
import 'package:sehat_kerja/core/sync/hari3.dart';
import 'package:sehat_kerja/data/app_snapshot.dart';
import 'package:sehat_kerja/data/sehat_api.dart';
import 'package:sehat_kerja/data/sehat_repository.dart';

void main() {
  test(
    'jaringan putus memakai snapshot tersimpan dan token tetap ada',
    () async {
      final storage = TokenStorage(MemoryKeyValueStore());
      await storage.save(access: 'akses', refresh: 'segar');
      await storage.saveSnapshot(jsonEncode(_contoh().toJson()));
      final container = _wadah(
        storage,
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
      container.dispose();
    },
  );

  test('tanpa cache, jaringan putus tidak menghapus token', () async {
    final storage = TokenStorage(MemoryKeyValueStore());
    await storage.save(access: 'akses', refresh: 'segar');
    final container = _wadah(
      storage,
      _Palsu()..snapshotError = const NetworkFailure(),
    );

    await expectLater(
      container.read(sehatRepositoryProvider).pulihkan(),
      throwsA(isA<NetworkFailure>()),
    );
    expect(await storage.accessToken, 'akses');
    container.dispose();
  });

  test('401 menghapus sesi', () async {
    final storage = TokenStorage(MemoryKeyValueStore());
    await storage.save(access: 'akses', refresh: 'segar');
    await storage.saveSnapshot(jsonEncode(_contoh().toJson()));
    final container = _wadah(
      storage,
      _Palsu()..snapshotError = const UnauthorizedFailure(),
    );

    final sesi = await container.read(sehatRepositoryProvider).pulihkan();
    expect(sesi, isNull);
    expect(await storage.accessToken, isNull);
    expect(await storage.cachedSnapshot, isNull);
    container.dispose();
  });

  test('kirim saat offline tidak mengantre', () async {
    final storage = TokenStorage(MemoryKeyValueStore());
    final container = _wadah(
      storage,
      _Palsu()..outboxError = const NetworkFailure(),
    );

    await expectLater(
      container
          .read(sehatRepositoryProvider)
          .kirimLayanan(
            clientId: 'lokal-1',
            jenis: 'rawatJalan',
            faskes: 'Klinik Melati',
            keluhan: 'Demam tiga hari',
          ),
      throwsA(
        isA<NetworkFailure>().having(
          (e) => e.message,
          'message',
          Hari3.belumTerkirim,
        ),
      ),
    );
    container.dispose();
  });

  test('saldo_berubah dilaporkan dan saldo di layar disegarkan', () async {
    final storage = TokenStorage(MemoryKeyValueStore());
    final palsu = _Palsu()
      ..outboxHasil = const HasilOutbox(
        ok: false,
        code: 'saldo_berubah',
        message: 'Saldo berubah saat pengajuan dikirim. Jangan tandai synced.',
      );
    final container = _wadah(storage, palsu);

    await expectLater(
      container
          .read(sehatRepositoryProvider)
          .kirimDana(
            clientId: 'dana-1',
            jenis: 'sebagian10',
            alasan: 'Persiapan masa tua',
            nominal: 1250000,
            expectedSaldoTotal: 12500000,
          ),
      throwsA(isA<ServerFailure>()),
    );
    expect(palsu.snapshotDipanggil, 1);
    expect(
      container.read(sehatRepositoryProvider).terakhir?.saldo.total,
      12500000,
    );
    container.dispose();
  });
}

ProviderContainer _wadah(TokenStorage storage, KlienSehat klien) {
  return ProviderContainer(
    overrides: [
      tokenStorageProvider.overrideWithValue(storage),
      klienSehatProvider.overrideWithValue(klien),
    ],
  );
}

AppSnapshot _contoh() {
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
      'iuranPeserta': 4500000,
      'iuranPemberiKerja': 6500000,
      'pengembangan': 1500000,
      'total': 12500000,
    },
    'layanan': <Map<String, dynamic>>[],
    'dana': <Map<String, dynamic>>[],
  });
}

class _Palsu implements KlienSehat {
  Failure? snapshotError;
  Failure? outboxError;
  HasilOutbox? outboxHasil;
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
    final error = outboxError;
    if (error != null) throw error;
    return outboxHasil ?? const HasilOutbox(ok: true);
  }

  @override
  Future<AppSnapshot> snapshot() async {
    snapshotDipanggil++;
    final error = snapshotError;
    if (error != null) throw error;
    return _contoh();
  }
}
