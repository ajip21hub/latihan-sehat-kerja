import 'dart:convert';

import '../../data/app_snapshot.dart';
import '../../features/dana/domain/pengajuan_dana.dart';
import '../../features/layanan/domain/pengajuan_layanan.dart';

class PeristiwaStatus {
  const PeristiwaStatus({this.id, this.clientId, required this.status});

  final String? id;
  final String? clientId;
  final String status;
}

/// Pesan `{"type":"status","id":"...","clientId":"...","status":"diproses"}`.
PeristiwaStatus? bacaPeristiwa(String pesan) {
  final Object? json;
  try {
    json = jsonDecode(pesan);
  } on FormatException {
    return null;
  }
  if (json is! Map || json['type'] != 'status') return null;
  final status = json['status'];
  if (status is! String || status.isEmpty) return null;
  return PeristiwaStatus(
    id: json['id']?.toString(),
    clientId: json['clientId']?.toString(),
    status: status,
  );
}

/// Mengembalikan [snap] yang sama kalau tidak ada baris yang berubah.
AppSnapshot terapkanStatus(
  AppSnapshot snap, {
  String? id,
  String? clientId,
  required String status,
}) {
  final berikutnya = StatusPengajuan.values.asNameMap()[status];
  if (berikutnya == null) return snap;

  var berubah = false;
  final layanan = <PengajuanLayanan>[];
  for (final item in snap.layanan) {
    if (_kena(item.id, item.clientId, id, clientId) &&
        item.status != berikutnya) {
      berubah = true;
      layanan.add(item.copyWith(status: berikutnya));
    } else {
      layanan.add(item);
    }
  }
  final dana = <PengajuanDana>[];
  for (final item in snap.dana) {
    if (_kena(item.id, item.clientId, id, clientId) &&
        item.status != berikutnya) {
      berubah = true;
      dana.add(item.copyWith(status: berikutnya));
    } else {
      dana.add(item);
    }
  }
  if (!berubah) return snap;
  return snap.copyWith(layanan: layanan, dana: dana);
}

bool _kena(String idItem, String? clientItem, String? id, String? clientId) {
  if (id != null && id.isNotEmpty && (idItem == id || clientItem == id)) {
    return true;
  }
  if (clientId != null &&
      clientId.isNotEmpty &&
      (idItem == clientId || clientItem == clientId)) {
    return true;
  }
  return false;
}

/// `http://127.0.0.1:8787` menjadi `ws://127.0.0.1:8787/v1/stream?token=`.
Uri alamatStream(String apiBase, String token) {
  final http = Uri.parse(apiBase);
  final scheme = switch (http.scheme) {
    'https' => 'wss',
    'wss' => 'wss',
    'ws' => 'ws',
    _ => 'ws',
  };
  return http.replace(
    scheme: scheme,
    path: '/v1/stream',
    queryParameters: {'token': token},
  );
}

/// 1 d, 2 d, 4 d, 8 d, lalu mentok 15 d.
Duration jedaSambung(int attempt) {
  final pangkat = attempt <= 1 ? 0 : attempt - 1;
  final detik = 1 << pangkat.clamp(0, 4);
  return Duration(seconds: detik > 15 ? 15 : detik);
}
