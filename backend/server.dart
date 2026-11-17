// Backend latihan SehatKerja. Bukan server BPJS.
//
//   dart run backend/server.dart            # http://localhost:8787
//   dart run backend/server.dart --self-check
//
// Emulator Android memakai http://10.0.2.2:8787
//
// Kontrak Hari 2: POST /auth/login, POST /auth/refresh (access bisa kedaluwarsa).
// Kontrak untuk kasus offline Hari 3:
//   GET  /v1/snapshot     isi cache (network-first)
//   POST /v1/outbox       kirim baris yang synced=false
//   GET  /v1/stream       WebSocket, status pengajuan berubah sendiri
//
// Dana mengirim expectedSaldoTotal. Kalau saldo di server sudah lain,
// balasan 409 saldo_berubah. Klien TIDAK boleh menandai baris itu synced.
// clientId yang sama dikirim ulang mengembalikan hasil lama (idempoten).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

const _portDefault = 8787;

Future<void> main(List<String> args) async {
  final check = args.contains('--self-check');
  final port = check ? 0 : _portArg(args);
  final store = Store();
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  final timer = Timer.periodic(const Duration(seconds: 3), (_) {
    store.majuStatus();
  });
  if (!check) {
    stdout.writeln('SehatKerja backend: http://localhost:${server.port}');
    stdout.writeln('Akun: 0001 atau 0002 / belajar');
    stdout.writeln('WebSocket: ws://localhost:${server.port}/v1/stream');
  }

  final serving = () async {
    await for (final request in server) {
      unawaited(_handle(request, store));
    }
  }();

  if (!check) {
    await serving;
    return;
  }

  final code = await _selfCheck(server.port, store);
  timer.cancel();
  await server.close(force: true);
  await serving;
  exit(code);
}

int _portArg(List<String> args) {
  final numbers = args.where((a) => int.tryParse(a) != null);
  if (numbers.isEmpty) return _portDefault;
  return int.parse(numbers.first);
}

Future<void> _handle(HttpRequest request, Store store) async {
  final response = request.response;
  response.headers
    ..set('Access-Control-Allow-Origin', '*')
    ..set(
      'Access-Control-Allow-Headers',
      'Authorization, Content-Type, Cache-Control, Pragma',
    )
    ..set('Cache-Control', 'no-store')
    ..set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  if (request.method == 'OPTIONS') {
    response.statusCode = HttpStatus.noContent;
    await response.close();
    return;
  }

  try {
    final path = request.uri.path;
    if (request.method == 'GET' && path == '/health') {
      await _json(response, {'ok': true});
      return;
    }
    if (request.method == 'POST' && path == '/auth/login') {
      await _login(request, response, store);
      return;
    }
    if (request.method == 'POST' && path == '/auth/refresh') {
      await _refresh(request, response, store);
      return;
    }
    if (request.method == 'GET' && path == '/v1/stream') {
      await _stream(request, store);
      return;
    }

    final nomor = store.nomorUntuk(request.headers.value('authorization'));
    if (nomor == null) {
      await _json(response, {'message': 'Masuk dulu.'}, status: 401);
      return;
    }
    if (request.method == 'GET' && path == '/v1/snapshot') {
      await _json(response, store.snapshot(nomor));
      return;
    }
    if (request.method == 'POST' && path == '/v1/outbox') {
      final body = await _body(request);
      final ops = body['ops'];
      if (ops is! List) {
        await _json(response, {
          'message': 'ops harus berupa daftar.',
        }, status: 400);
        return;
      }
      final results = [
        for (final op in ops)
          if (op is Map<String, dynamic>)
            store.terapkan(nomor, op)
          else if (op is Map)
            store.terapkan(nomor, op.cast<String, dynamic>())
          else
            {
              'ok': false,
              'code': 'bentuk',
              'message': 'Operasi tidak dikenal.',
            },
      ];
      await _json(response, {'results': results});
      return;
    }
    await _json(response, {'message': 'Tidak ada.'}, status: 404);
  } catch (e) {
    await _json(response, {'message': '$e'}, status: 400);
  }
}

Future<void> _login(
  HttpRequest request,
  HttpResponse response,
  Store store,
) async {
  final body = await _body(request);
  final mentah = body['expiresInSecs'];
  final expiresInSecs = mentah is num ? mentah.toInt() : 900;
  final sesi = store.masuk(
    '${body['nomor'] ?? ''}',
    '${body['sandi'] ?? ''}',
    expiresInSecs: expiresInSecs,
  );
  if (sesi == null) {
    await _json(response, {
      'message': 'Nomor atau sandi tidak cocok.',
    }, status: 401);
    return;
  }
  await _json(response, sesi);
}

Future<void> _refresh(
  HttpRequest request,
  HttpResponse response,
  Store store,
) async {
  final body = await _body(request);
  final sesi = store.segarkan('${body['refreshToken'] ?? ''}');
  if (sesi == null) {
    await _json(response, {'message': 'Refresh ditolak.'}, status: 401);
    return;
  }
  await _json(response, sesi);
}

Future<void> _stream(HttpRequest request, Store store) async {
  final token =
      request.uri.queryParameters['token'] ??
      request.headers.value('authorization');
  final nomor = store.nomorUntuk(token);
  if (nomor == null) {
    request.response.statusCode = HttpStatus.unauthorized;
    await request.response.close();
    return;
  }
  final socket = await WebSocketTransformer.upgrade(request);
  store.ikut(nomor, socket);
  socket.listen(
    (_) {},
    onDone: () => store.lepas(socket),
    onError: (_) => store.lepas(socket),
  );
}

Future<Map<String, dynamic>> _body(HttpRequest request) async {
  final text = await utf8.decoder.bind(request).join();
  if (text.isEmpty) return {};
  final decoded = jsonDecode(text);
  if (decoded is Map<String, dynamic>) return decoded;
  if (decoded is Map) return decoded.cast<String, dynamic>();
  throw const FormatException('Body harus objek JSON.');
}

Future<void> _json(
  HttpResponse response,
  Object body, {
  int status = 200,
}) async {
  response.statusCode = status;
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(body));
  await response.close();
}

class Store {
  Store() {
    _saldo.addAll({
      '0001': _Saldo(4500000, 6500000, 1500000),
      '0002': _Saldo(1200000, 1600000, 400000),
    });
    _layanan['0001'] = [
      _Layanan(
        id: 'L-1',
        clientId: 'seed-L-1',
        nomor: '0001',
        jenis: 'rawatJalan',
        faskes: 'Klinik Melati',
        tanggal: '2026-10-02T00:00:00.000Z',
        keluhan: 'Demam dan batuk',
        status: 'disetujui',
      ),
    ];
  }

  static const _peserta = {
    '0001': (
      sandi: 'belajar',
      nama: 'Sari Wulandari',
      nik: '3275011201900001',
      kelas: 'dua',
      kelasLabel: 'Kelas 2',
      faskes: 'Klinik Melati',
      tahun: 11,
    ),
    '0002': (
      sandi: 'belajar',
      nama: 'Budi Santoso',
      nik: '3275010801950002',
      kelas: 'tiga',
      kelasLabel: 'Kelas 3',
      faskes: 'Puskesmas Dahlia',
      tahun: 4,
    ),
  };

  final _access = <String, ({String nomor, DateTime exp})>{};
  final _refresh = <String, String>{};
  final _saldo = <String, _Saldo>{};
  final _layanan = <String, List<_Layanan>>{};
  final _dana = <String, List<_Dana>>{};
  final _sockets = <WebSocket, String>{};
  final _random = Random();

  Map<String, dynamic>? masuk(
    String nomor,
    String sandi, {
    int expiresInSecs = 900,
  }) {
    final id = nomor.trim();
    final orang = _peserta[id];
    if (orang == null || orang.sandi != sandi) return null;
    return _terbitkan(id, expiresInSecs: expiresInSecs);
  }

  /// `null` bila refresh tidak dikenal. Token lama langsung dibuang.
  Map<String, dynamic>? segarkan(String refreshToken) {
    final nomor = _refresh.remove(refreshToken);
    if (nomor == null) return null;
    return _terbitkan(nomor);
  }

  Map<String, dynamic> _terbitkan(String nomor, {int expiresInSecs = 900}) {
    final access = _acak();
    final refresh = _acak();
    _access[access] = (
      nomor: nomor,
      exp: DateTime.now().toUtc().add(Duration(seconds: expiresInSecs)),
    );
    _refresh[refresh] = nomor;
    return {
      'accessToken': access,
      'refreshToken': refresh,
      'expiresIn': expiresInSecs,
      'peserta': _profil(nomor),
    };
  }

  String? nomorUntuk(String? header) {
    if (header == null || header.isEmpty) return null;
    final token = header.startsWith('Bearer ') ? header.substring(7) : header;
    final rec = _access[token];
    if (rec == null || !rec.exp.isAfter(DateTime.now().toUtc())) return null;
    return rec.nomor;
  }

  Map<String, dynamic> snapshot(String nomor) => {
    'serverTime': DateTime.now().toUtc().toIso8601String(),
    'peserta': _profil(nomor),
    'saldo': _saldo[nomor]!.json,
    'layanan': [for (final item in _layanan[nomor] ?? const []) item.json],
    'dana': [for (final item in _dana[nomor] ?? const []) item.json],
  };

  void ikut(String nomor, WebSocket socket) {
    _sockets[socket] = nomor;
    socket.add(jsonEncode({'type': 'hello', 'nomor': nomor}));
  }

  void lepas(WebSocket socket) => _sockets.remove(socket);

  /// Satu operasi outbox. Selalu objek, supaya satu gagal tidak menggagalkan yang lain.
  Map<String, dynamic> terapkan(String nomor, Map<String, dynamic> op) {
    final clientId = '${op['clientId'] ?? ''}'.trim();
    if (clientId.isEmpty) {
      return {'ok': false, 'code': 'client_id', 'message': 'clientId wajib.'};
    }
    final sudah = _cari(nomor, clientId);
    if (sudah != null) {
      return {
        'clientId': clientId,
        'ok': true,
        'alreadyApplied': true,
        'item': sudah,
      };
    }
    return switch (op['op']) {
      'layanan' => _layananBaru(nomor, clientId, op),
      'dana' => _danaBaru(nomor, clientId, op),
      _ => {
        'clientId': clientId,
        'ok': false,
        'code': 'op',
        'message': 'op tidak dikenal.',
      },
    };
  }

  void majuStatus() {
    for (final daftar in [..._layanan.values, ..._dana.values]) {
      for (final item in daftar) {
        final next = switch (item.status) {
          'diajukan' => 'diproses',
          'diproses' => 'disetujui',
          _ => null,
        };
        if (next == null) continue;
        item.status = next;
        _siarkan({
          'type': 'status',
          'nomor': item.nomor,
          'kind': item.kind,
          'id': item.id,
          'clientId': item.clientId,
          'status': next,
        });
      }
    }
  }

  Map<String, dynamic> _layananBaru(
    String nomor,
    String clientId,
    Map<String, dynamic> op,
  ) {
    final jenis = '${op['jenis'] ?? ''}';
    final faskes = '${op['faskes'] ?? ''}'.trim();
    final keluhan = '${op['keluhan'] ?? ''}'.trim();
    if (jenis != 'rawatJalan' && jenis != 'rawatInap') {
      return _tolak(clientId, 'jenis', 'Jenis layanan tidak dikenal.');
    }
    if (faskes.isEmpty || keluhan.length < 5) {
      return _tolak(
        clientId,
        'ditolak',
        'Isi faskes dan keluhan, minimal 5 huruf.',
      );
    }
    final item = _Layanan(
      id: 'L-${_acak()}',
      clientId: clientId,
      nomor: nomor,
      jenis: jenis,
      faskes: faskes,
      tanggal: '${op['tanggal'] ?? DateTime.now().toUtc().toIso8601String()}',
      keluhan: keluhan,
      status: 'diajukan',
    );
    _layanan.putIfAbsent(nomor, () => []).insert(0, item);
    return {
      'clientId': clientId,
      'ok': true,
      'alreadyApplied': false,
      'item': item.json,
    };
  }

  Map<String, dynamic> _danaBaru(
    String nomor,
    String clientId,
    Map<String, dynamic> op,
  ) {
    final saldo = _saldo[nomor]!;
    final expected = op['expectedSaldoTotal'];
    if (expected is! num || expected.toInt() != saldo.total) {
      return {
        'clientId': clientId,
        'ok': false,
        'code': 'saldo_berubah',
        'message':
            'Saldo berubah saat pengajuan dikirim. Jangan tandai synced.',
        'saldo': saldo.json,
      };
    }
    final orang = _peserta[nomor]!;
    final berjalan = (_dana[nomor] ?? const []).any(
      (item) => item.masihBerjalan,
    );
    final jenis = '${op['jenis'] ?? ''}';
    final alasan = '${op['alasan'] ?? ''}'.trim();
    if (alasan.length < 8) {
      return _tolak(clientId, 'ditolak', 'Alasan minimal 8 huruf.');
    }
    if (berjalan) {
      return _tolak(
        clientId,
        'ditolak',
        'Masih ada pengajuan dana yang belum selesai.',
      );
    }
    if (saldo.total <= 0) {
      return _tolak(clientId, 'ditolak', 'Saldo kosong.');
    }

    final nominal = switch (jenis) {
      'seluruhnya' => saldo.total,
      'sebagian10' when orang.tahun >= 10 => (saldo.total * 10) ~/ 100,
      'sebagian10' => -1,
      _ => -2,
    };
    if (nominal == -2) {
      return _tolak(clientId, 'jenis', 'Jenis pengambilan tidak dikenal.');
    }
    if (nominal < 0) {
      return _tolak(
        clientId,
        'ditolak',
        'Pengambilan 10% hanya untuk kepesertaan minimal 10 tahun.',
      );
    }
    final dikirim = op['nominal'];
    if (dikirim is! num || dikirim.toInt() != nominal) {
      return {
        'clientId': clientId,
        'ok': false,
        'code': 'nominal_berubah',
        'message': 'Nominal tidak sama dengan saldo sekarang. Hitung ulang, jangan tandai synced.',
        'nominalBenar': nominal,
        'saldo': saldo.json,
      };
    }

    final item = _Dana(
      id: 'D-${_acak()}',
      clientId: clientId,
      nomor: nomor,
      jenis: jenis,
      nominal: nominal,
      alasan: alasan,
      status: 'diajukan',
      perkiraanHariKerja: nominal <= 10000000 ? 1 : 5,
    );
    _dana.putIfAbsent(nomor, () => []).insert(0, item);
    _saldo[nomor] = saldo.kurang(nominal);
    return {
      'clientId': clientId,
      'ok': true,
      'alreadyApplied': false,
      'item': item.json,
      'saldo': _saldo[nomor]!.json,
    };
  }

  Map<String, dynamic>? _cari(String nomor, String clientId) {
    for (final item in _layanan[nomor] ?? const <_Item>[]) {
      if (item.clientId == clientId) return item.json;
    }
    for (final item in _dana[nomor] ?? const <_Item>[]) {
      if (item.clientId == clientId) return item.json;
    }
    return null;
  }

  Map<String, dynamic> _tolak(String clientId, String code, String message) => {
    'clientId': clientId,
    'ok': false,
    'code': code,
    'message': message,
  };

  Map<String, dynamic> _profil(String nomor) {
    final orang = _peserta[nomor]!;
    return {
      'nomor': nomor,
      'nama': orang.nama,
      'nik': orang.nik,
      'kelas': orang.kelas,
      'kelasLabel': orang.kelasLabel,
      'faskes': orang.faskes,
      'tahunKepesertaan': orang.tahun,
      'aktif': true,
    };
  }

  void _siarkan(Map<String, dynamic> event) {
    final nomor = event['nomor'];
    final text = jsonEncode(event);
    for (final entry in _sockets.entries) {
      if (entry.value == nomor) entry.key.add(text);
    }
  }

  String _acak() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64Url.encode(bytes).replaceAll('=', '');
  }
}

class _Saldo {
  _Saldo(this.iuranPeserta, this.iuranPemberiKerja, this.pengembangan);

  final int iuranPeserta;
  final int iuranPemberiKerja;
  final int pengembangan;

  int get total => iuranPeserta + iuranPemberiKerja + pengembangan;

  _Saldo kurang(int nominal) {
    final fromPeserta = nominal.clamp(0, iuranPeserta);
    var rest = nominal - fromPeserta;
    final fromPemberi = rest.clamp(0, iuranPemberiKerja);
    rest -= fromPemberi;
    final fromKembang = rest.clamp(0, pengembangan);
    return _Saldo(
      iuranPeserta - fromPeserta,
      iuranPemberiKerja - fromPemberi,
      pengembangan - fromKembang,
    );
  }

  Map<String, dynamic> get json => {
    'iuranPeserta': iuranPeserta,
    'iuranPemberiKerja': iuranPemberiKerja,
    'pengembangan': pengembangan,
    'total': total,
  };
}

abstract class _Item {
  String get id;
  String get clientId;
  String get nomor;
  String get kind;
  String get status;
  set status(String value);
  Map<String, dynamic> get json;
}

class _Layanan implements _Item {
  _Layanan({
    required this.id,
    required this.clientId,
    required this.nomor,
    required this.jenis,
    required this.faskes,
    required this.tanggal,
    required this.keluhan,
    required this.status,
  });

  @override
  final String id;
  @override
  final String clientId;
  @override
  final String nomor;
  final String jenis;
  final String faskes;
  final String tanggal;
  final String keluhan;
  @override
  String status;

  @override
  String get kind => 'layanan';

  @override
  Map<String, dynamic> get json => {
    'id': id,
    'clientId': clientId,
    'jenis': jenis,
    'faskes': faskes,
    'tanggal': tanggal,
    'keluhan': keluhan,
    'status': status,
  };
}

class _Dana implements _Item {
  _Dana({
    required this.id,
    required this.clientId,
    required this.nomor,
    required this.jenis,
    required this.nominal,
    required this.alasan,
    required this.status,
    required this.perkiraanHariKerja,
  });

  @override
  final String id;
  @override
  final String clientId;
  @override
  final String nomor;
  final String jenis;
  final int nominal;
  final String alasan;
  @override
  String status;
  final int perkiraanHariKerja;

  bool get masihBerjalan => status == 'diajukan' || status == 'diproses';

  @override
  String get kind => 'dana';

  @override
  Map<String, dynamic> get json => {
    'id': id,
    'clientId': clientId,
    'jenis': jenis,
    'nominal': nominal,
    'alasan': alasan,
    'status': status,
    'perkiraanHariKerja': perkiraanHariKerja,
  };
}

Future<int> _selfCheck(int port, Store store) async {
  final base = 'http://127.0.0.1:$port';
  final client = HttpClient();
  try {
    final bad = await _call(client, 'POST', '$base/auth/login', {
      'nomor': '0001',
      'sandi': 'salah',
    });
    _expect(bad.status == 401, 'login salah harus 401');

    final login = await _call(client, 'POST', '$base/auth/login', {
      'nomor': '0001',
      'sandi': 'belajar',
    });
    _expect(login.status == 200, 'login 0001');
    final token = login.json['accessToken'] as String;

    final awal = await _call(client, 'GET', '$base/v1/snapshot', null, token);
    _expect(awal.json['saldo']['total'] == 12500000, 'saldo awal 12,5 juta');

    final layanan = await _call(client, 'POST', '$base/v1/outbox', {
      'ops': [
        {
          'op': 'layanan',
          'clientId': 'lokal-1',
          'jenis': 'rawatJalan',
          'faskes': 'Klinik Melati',
          'keluhan': 'Sakit kepala',
          'tanggal': '2026-11-17T00:00:00.000Z',
        },
      ],
    }, token);
    _expect(layanan.json['results'][0]['ok'] == true, 'layanan masuk');
    final ulang = await _call(client, 'POST', '$base/v1/outbox', {
      'ops': [
        {
          'op': 'layanan',
          'clientId': 'lokal-1',
          'jenis': 'rawatJalan',
          'faskes': 'Klinik Melati',
          'keluhan': 'Sakit kepala',
        },
      ],
    }, token);
    _expect(
      ulang.json['results'][0]['alreadyApplied'] == true,
      'clientId diulang tidak menggandakan',
    );

    final dana = await _call(client, 'POST', '$base/v1/outbox', {
      'ops': [
        {
          'op': 'dana',
          'clientId': 'dana-1',
          'jenis': 'sebagian10',
          'alasan': 'Persiapan masa tua',
          'nominal': 1250000,
          'expectedSaldoTotal': 12500000,
        },
      ],
    }, token);
    _expect(dana.json['results'][0]['ok'] == true, '10% diterima');
    _expect(
      dana.json['results'][0]['saldo']['total'] == 11250000,
      'saldo berkurang 1,25 juta',
    );

    final basi = await _call(client, 'POST', '$base/v1/outbox', {
      'ops': [
        {
          'op': 'dana',
          'clientId': 'dana-basi',
          'jenis': 'sebagian10',
          'alasan': 'Masih memakai saldo lama',
          'nominal': 1250000,
          'expectedSaldoTotal': 12500000,
        },
      ],
    }, token);
    _expect(
      basi.json['results'][0]['code'] == 'saldo_berubah',
      'saldo basi ditolak',
    );
    final setelah = await _call(
      client,
      'GET',
      '$base/v1/snapshot',
      null,
      token,
    );
    _expect(
      setelah.json['saldo']['total'] == 11250000,
      '409 tidak mengubah saldo',
    );

    final login2 = await _call(client, 'POST', '$base/auth/login', {
      'nomor': '0002',
      'sandi': 'belajar',
    });
    final token2 = login2.json['accessToken'] as String;
    final ditolak = await _call(client, 'POST', '$base/v1/outbox', {
      'ops': [
        {
          'op': 'dana',
          'clientId': 'dana-2',
          'jenis': 'sebagian10',
          'alasan': 'Belum sepuluh tahun',
          'nominal': 320000,
          'expectedSaldoTotal': 3200000,
        },
      ],
    }, token2);
    _expect(
      ditolak.json['results'][0]['code'] == 'ditolak',
      '0002 belum 10 tahun',
    );

    final cepat = await _call(client, 'POST', '$base/auth/login', {
      'nomor': '0001',
      'sandi': 'belajar',
      'expiresInSecs': 0,
    });
    _expect(cepat.status == 200, 'login dengan access yang langsung habis');
    final accessPendek = cepat.json['accessToken'] as String;
    final refreshPendek = cepat.json['refreshToken'] as String;
    final kedaluwarsa = await _call(
      client,
      'GET',
      '$base/v1/snapshot',
      null,
      accessPendek,
    );
    _expect(kedaluwarsa.status == 401, 'access kedaluwarsa ditolak');
    final segar = await _call(client, 'POST', '$base/auth/refresh', {
      'refreshToken': refreshPendek,
    });
    _expect(segar.status == 200, 'refresh diterima');
    final accessBaru = segar.json['accessToken'] as String;
    final setelahRefresh = await _call(
      client,
      'GET',
      '$base/v1/snapshot',
      null,
      accessBaru,
    );
    _expect(setelahRefresh.status == 200, 'snapshot setelah refresh');
    final refreshBasi = await _call(client, 'POST', '$base/auth/refresh', {
      'refreshToken': refreshPendek,
    });
    _expect(refreshBasi.status == 401, 'refresh lama tidak bisa dipakai lagi');

    store.majuStatus();
    stdout.writeln('self-check ok');
    return 0;
  } on Object catch (e) {
    stderr.writeln('self-check gagal: $e');
    return 1;
  } finally {
    client.close(force: true);
  }
}

void _expect(bool ok, String label) {
  if (!ok) throw StateError(label);
}

class _Res {
  _Res(this.status, this.json);
  final int status;
  final Map<String, dynamic> json;
}

Future<_Res> _call(
  HttpClient client,
  String method,
  String url,
  Map<String, dynamic>? body, [
  String? token,
]) async {
  final request = await client.openUrl(method, Uri.parse(url));
  request.headers.contentType = ContentType.json;
  if (token != null) request.headers.set('authorization', 'Bearer $token');
  if (body != null) request.write(jsonEncode(body));
  final response = await request.close();
  final text = await utf8.decoder.bind(response).join();
  final decoded = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
  return _Res(
    response.statusCode,
    decoded is Map<String, dynamic> ? decoded : decoded.cast<String, dynamic>(),
  );
}
