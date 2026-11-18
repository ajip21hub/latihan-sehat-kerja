import 'package:flutter_test/flutter_test.dart';
import 'package:sehat_kerja/core/sync/status_terapkan.dart';
import 'package:sehat_kerja/data/app_snapshot.dart';
import 'package:sehat_kerja/features/dana/domain/pengajuan_dana.dart';
import 'package:sehat_kerja/features/layanan/domain/pengajuan_layanan.dart';

void main() {
  test('status websocket mengubah baris yang id atau clientId-nya sama', () {
    final snap = AppSnapshot.fromJson(const {
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
        'iuranPeserta': 1,
        'iuranPemberiKerja': 0,
        'pengembangan': 0,
        'total': 1,
      },
      'layanan': [
        {
          'id': 'L-9',
          'clientId': 'lokal-1',
          'jenis': 'rawatJalan',
          'faskes': 'Klinik Melati',
          'tanggal': '2026-10-02T00:00:00.000Z',
          'keluhan': 'Demam',
          'status': 'diajukan',
        },
      ],
      'dana': [
        {
          'id': 'lokal-dana',
          'jenis': 'sebagian10',
          'nominal': 1000,
          'alasan': 'Persiapan',
          'status': 'diajukan',
          'perkiraanHariKerja': 1,
        },
      ],
    });

    final dariClient = terapkanStatus(
      snap,
      clientId: 'lokal-1',
      status: 'diproses',
    );
    expect(dariClient.layanan.single.status, StatusPengajuan.diproses);
    expect(dariClient.saldo.total, snap.saldo.total);

    final dariId = terapkanStatus(snap, id: 'lokal-dana', status: 'disetujui');
    expect(dariId.dana.single.status, StatusPengajuan.disetujui);
    expect(dariId.dana.single.jenis, JenisAmbil.sebagian10);

    expect(
      identical(
        terapkanStatus(snap, id: 'tidak-ada', status: 'diproses'),
        snap,
      ),
      isTrue,
    );
    expect(
      identical(terapkanStatus(snap, id: 'L-9', status: 'aneh'), snap),
      isTrue,
    );
  });

  test('alamat stream dan jeda sambung', () {
    expect(
      alamatStream('http://127.0.0.1:8787', 'tok').toString(),
      'ws://127.0.0.1:8787/v1/stream?token=tok',
    );
    expect(
      alamatStream('https://api.contoh.test/v1', 'tok').toString(),
      'wss://api.contoh.test/v1/stream?token=tok',
    );
    expect(jedaSambung(1), const Duration(seconds: 1));
    expect(jedaSambung(2), const Duration(seconds: 2));
    expect(jedaSambung(3), const Duration(seconds: 4));
    expect(jedaSambung(5), const Duration(seconds: 15));
    expect(jedaSambung(8), const Duration(seconds: 15));
  });

  test('pesan status yang bukan json diabaikan', () {
    expect(bacaPeristiwa('bukan json'), isNull);
    expect(bacaPeristiwa('{"type":"lain"}'), isNull);
    final peristiwa = bacaPeristiwa(
      '{"type":"status","id":"L-1","clientId":"c","status":"diproses"}',
    );
    expect(peristiwa?.id, 'L-1');
    expect(peristiwa?.clientId, 'c');
    expect(peristiwa?.status, 'diproses');
  });
}
