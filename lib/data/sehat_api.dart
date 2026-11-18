import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/dio_client.dart';
import '../features/peserta/domain/peserta.dart';
import 'app_snapshot.dart';

class HasilMasuk {
  const HasilMasuk({
    required this.accessToken,
    required this.refreshToken,
    required this.peserta,
  });

  final String accessToken;
  final String refreshToken;
  final Peserta peserta;
}

class HasilOutbox {
  const HasilOutbox({
    required this.ok,
    this.code,
    this.message,
    this.alreadyApplied = false,
    this.saldoTotal,
    this.nominalBenar,
  });

  final bool ok;
  final String? code;
  final String? message;
  final bool alreadyApplied;
  final int? saldoTotal;
  final int? nominalBenar;

  factory HasilOutbox.fromJson(Map<String, dynamic> json) {
    final saldo = json['saldo'];
    final nominal = json['nominalBenar'];
    return HasilOutbox(
      ok: json['ok'] == true,
      code: json['code']?.toString(),
      message: json['message']?.toString(),
      alreadyApplied: json['alreadyApplied'] == true,
      saldoTotal: saldo is Map && saldo['total'] is num
          ? (saldo['total'] as num).toInt()
          : null,
      nominalBenar: nominal is num ? nominal.toInt() : null,
    );
  }
}

/// Kontrak HTTP. Test memakai implementasi palsu, bukan server sungguhan.
abstract class KlienSehat {
  Future<HasilMasuk> masuk(String nomor, String sandi);
  Future<AppSnapshot> snapshot();
  Future<HasilOutbox> outbox(Map<String, dynamic> op);
  Future<List<HasilOutbox>> outboxSemua(List<Map<String, dynamic>> ops);
}

class DioKlienSehat implements KlienSehat {
  DioKlienSehat(this._dio);
  final Dio _dio;

  @override
  Future<HasilMasuk> masuk(String nomor, String sandi) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'nomor': nomor, 'sandi': sandi},
    );
    final json = _objek(res.data);
    return HasilMasuk(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      peserta: Peserta.fromJson(_objek(json['peserta'])),
    );
  }

  @override
  Future<AppSnapshot> snapshot() async {
    final res = await _dio.get<Map<String, dynamic>>('/v1/snapshot');
    return AppSnapshot.fromJson(_objek(res.data));
  }

  @override
  Future<HasilOutbox> outbox(Map<String, dynamic> op) async {
    final results = await outboxSemua([op]);
    return results.first;
  }

  @override
  Future<List<HasilOutbox>> outboxSemua(List<Map<String, dynamic>> ops) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/v1/outbox',
      data: {'ops': ops},
    );
    final results = _objek(res.data)['results'];
    if (results is! List || results.length != ops.length) {
      throw const FormatException('Server tidak mengembalikan results.');
    }
    return [for (final item in results) HasilOutbox.fromJson(_objek(item))];
  }
}

Map<String, dynamic> _objek(Object? data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return data.cast<String, dynamic>();
  throw const FormatException('Body harus objek JSON.');
}

final klienSehatProvider = Provider<KlienSehat>(
  (ref) => DioKlienSehat(ref.watch(dioProvider)),
);
