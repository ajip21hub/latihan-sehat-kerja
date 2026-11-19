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
//   GET  /v1/artikel      bacaan; klien menyimpan salinan di perangkat
//   POST /v1/outbox       kirim baris yang synced=false
//   GET  /v1/stream       WebSocket, status pengajuan berubah sendiri
//
// Role = siapa yang membayar iuran, dikirim di `peserta.kepesertaan`:
//   perusahaan (role A)  iuran dipotong gaji + porsi pemberi kerja
//   mandiri    (role B)  iuran dibayar sendiri
// Role bertambah, tidak saling mengganti. 0003 dulu perusahaan, berhenti,
// lalu daftar mandiri: memegang dua role. Snapshot hanya berisi bagian yang
// sesuai role, dan outbox menolak aksi di luar role dengan `peran_ditolak`.
//
// Dana mengirim expectedSaldoTotal. Kalau saldo di server sudah lain,
// balasan 409 saldo_berubah. Klien TIDAK boleh menandai baris itu synced.
// clientId yang sama dikirim ulang mengembalikan hasil lama (idempoten).
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

const _portDefault = 8787;

/// Bacaan yang sama untuk semua akun latihan. Bukan salinan peraturan.
const _artikel = [
  {
    'id': 'kelas-rawat',
    'judul': 'Kelas rawat 1, 2, dan 3',
    'ringkas': 'Kelas menentukan ruang rawat inap, bukan harga obat.',
    'isi':
        'Di latihan ini peserta punya satu kelas: 1, 2, atau 3, plus satu faskes. '
        'Kelas itu contoh golongan layanan, bukan perhitungan iuran. '
        'Naik atau turun kelas tidak dibuat di versi ini.',
    'diperbarui': 1763000000000,
  },
  {
    'id': 'saldo-jht',
    'judul': 'Saldo JHT bukan pensiun bulanan',
    'ringkas': 'Yang tampil adalah tabungan: iuran peserta, pemberi kerja, dan pengembangan.',
    'isi':
        'Jaminan Hari Tua di layar ini adalah saldo sekaligus, bukan manfaat bulanan. '
        'Jaminan Pensiun bulanan tidak ada di aplikasi latihan. '
        'Angka saldo adalah contoh supaya pengajuan bisa dicoba.',
    'diperbarui': 1763000001000,
  },
  {
    'id': 'ambil-sebagian',
    'judul': 'Pengambilan 10% butuh 10 tahun',
    'ringkas': 'Akun 0001 masih bekerja: boleh 10%. Akun 0003 sudah berhenti: ambil seluruhnya.',
    'isi':
        'Pengambilan sebagian 10% untuk peserta yang masih bekerja, di latihan ini, '
        'mensyaratkan kepesertaan minimal 10 tahun. Seluruh saldo hanya setelah '
        'berhenti bekerja. Jalur 30% untuk rumah tidak dibuat. '
        'Perkiraan 1 hari kerja di bawah Rp10 juta dan 5 hari di atasnya hanya label belajar.',
    'diperbarui': 1763000002000,
  },
  {
    'id': 'antrean-offline',
    'judul': 'Pengajuan tetap tersimpan di perangkat',
    'ringkas':
        'Kalau server mati, pengajuan masuk antrean dan dikirim lagi nanti.',
    'isi':
        'Bacaan ini diunduh sekali lalu disimpan di SQLite. Saat server tidak terjangkau, '
        'daftar yang sudah ada tetap bisa dibuka. Pengajuan layanan dan dana tidak '
        'ditandai sukses sebelum server menerimanya.',
    'diperbarui': 1763000003000,
  },
];

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
    stdout.writeln(
      'Akun (sandi belajar): 0001 perusahaan, 0002 mandiri, '
      '0003 perusahaan berhenti + mandiri',
    );
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
    if (request.method == 'GET' && path == '/v1/artikel') {
      await _json(response, {'artikel': _artikel});
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
      '0003': _Saldo(6000000, 9000000, 3000000),
    });
    for (final entry in _peserta.entries) {
      _kelas[entry.key] = entry.value.kelas;
    }
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
    _iuranPerusahaan['0001'] = _iuranBulanan(
      'PT Maju Jaya',
      dari: (2026, 5),
      sampai: (2026, 10),
      pekerja: 120000,
      pemberiKerja: 222000,
    );
    _iuranPerusahaan['0003'] = _iuranBulanan(
      'PT Sinar Abadi',
      dari: (2026, 1),
      sampai: (2026, 6),
      pekerja: 140000,
      pemberiKerja: 259000,
    );
    _tagihan['0002'] = [
      _Tagihan('T-0002-2026-09', '2026-09', 'tiga', '2026-09-08T03:00:00.000Z'),
      _Tagihan('T-0002-2026-10', '2026-10', 'tiga', '2026-10-09T03:00:00.000Z'),
      _Tagihan('T-0002-2026-11', '2026-11', 'tiga', null),
    ];
    _tagihan['0003'] = [
      _Tagihan('T-0003-2026-07', '2026-07', 'dua', '2026-07-05T03:00:00.000Z'),
      _Tagihan('T-0003-2026-08', '2026-08', 'dua', '2026-08-06T03:00:00.000Z'),
      _Tagihan('T-0003-2026-09', '2026-09', 'dua', '2026-09-04T03:00:00.000Z'),
      _Tagihan('T-0003-2026-10', '2026-10', 'dua', '2026-10-07T03:00:00.000Z'),
      _Tagihan('T-0003-2026-11', '2026-11', 'dua', null),
    ];
  }

  static const _peserta = {
    '0001': (
      sandi: 'belajar',
      nama: 'Sari Wulandari',
      nik: '3275011201900001',
      kelas: 'dua',
      faskes: 'Klinik Melati',
      tahun: 11,
      kepesertaan: [
        {
          'jenis': 'perusahaan',
          'status': 'aktif',
          'pemberiKerja': 'PT Maju Jaya',
          'mulai': '2015-03-01',
        },
      ],
    ),
    '0002': (
      sandi: 'belajar',
      nama: 'Budi Santoso',
      nik: '3275010801950002',
      kelas: 'tiga',
      faskes: 'Puskesmas Dahlia',
      tahun: 4,
      kepesertaan: [
        {'jenis': 'mandiri', 'status': 'aktif', 'mulai': '2022-09-01'},
      ],
    ),
    '0003': (
      sandi: 'belajar',
      nama: 'Dewi Lestari',
      nik: '3275014405880003',
      kelas: 'dua',
      faskes: 'Klinik Kenanga',
      tahun: 13,
      kepesertaan: [
        {
          'jenis': 'perusahaan',
          'status': 'berhenti',
          'pemberiKerja': 'PT Sinar Abadi',
          'mulai': '2013-02-01',
          'selesai': '2026-06-30',
        },
        {'jenis': 'mandiri', 'status': 'aktif', 'mulai': '2026-07-01'},
      ],
    ),
  };

  static const _tarifMandiri = {'satu': 150000, 'dua': 100000, 'tiga': 35000};

  final _access = <String, ({String nomor, DateTime exp})>{};
  final _refresh = <String, String>{};
  final _saldo = <String, _Saldo>{};
  final _layanan = <String, List<_Layanan>>{};
  final _dana = <String, List<_Dana>>{};
  final _kelas = <String, String>{};
  final _iuranPerusahaan = <String, List<Map<String, dynamic>>>{};
  final _tagihan = <String, List<_Tagihan>>{};

  /// Hasil op yang tidak punya baris sendiri (bayar, ubah kelas), per clientId.
  final _opSelesai = <String, Map<String, Map<String, dynamic>>>{};
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

  /// Hanya bagian yang sesuai role yang dikirim.
  Map<String, dynamic> snapshot(String nomor) => {
    'serverTime': DateTime.now().toUtc().toIso8601String(),
    'peserta': _profil(nomor),
    'layanan': [for (final item in _layanan[nomor] ?? const []) item.json],
    if (_punya(nomor, 'perusahaan')) ...{
      'saldo': (_saldo[nomor] ?? _Saldo(0, 0, 0)).json,
      'dana': [for (final item in _dana[nomor] ?? const []) item.json],
      'iuranPerusahaan': _iuranPerusahaan[nomor] ?? const [],
    },
    if (_punya(nomor, 'mandiri'))
      'tagihan': [for (final t in _tagihan[nomor] ?? const []) t.json],
  };

  bool _punya(String nomor, String jenis, {bool harusAktif = false}) {
    final segmen = _peserta[nomor]?.kepesertaan ?? const [];
    return segmen.any(
      (k) => k['jenis'] == jenis && (!harusAktif || k['status'] == 'aktif'),
    );
  }

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
    // Menyembunyikan menu di aplikasi hanya tampilan. Di sini aturannya.
    final syarat = switch (op['op']) {
      'dana' => _punya(nomor, 'perusahaan'),
      'bayarIuran' || 'ubahKelas' => _punya(nomor, 'mandiri', harusAktif: true),
      _ => true,
    };
    if (!syarat) {
      return _tolak(
        clientId,
        'peran_ditolak',
        'Jenis kepesertaanmu tidak punya akses ke aksi ini.',
      );
    }
    return switch (op['op']) {
      'layanan' => _layananBaru(nomor, clientId, op),
      'dana' => _danaBaru(nomor, clientId, op),
      'bayarIuran' => _simpanOp(nomor, clientId, _bayarIuran(nomor, op)),
      'ubahKelas' => _simpanOp(nomor, clientId, _ubahKelas(nomor, op)),
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

    final bekerja = _punya(nomor, 'perusahaan', harusAktif: true);
    if (jenis != 'seluruhnya' && jenis != 'sebagian10') {
      return _tolak(clientId, 'jenis', 'Jenis pengambilan tidak dikenal.');
    }
    if (jenis == 'seluruhnya' && bekerja) {
      return _tolak(
        clientId,
        'ditolak',
        'Seluruh saldo hanya bisa diambil setelah berhenti bekerja.',
      );
    }
    if (jenis == 'sebagian10' && !bekerja) {
      return _tolak(
        clientId,
        'ditolak',
        'Jalur 10% untuk peserta yang masih bekerja.',
      );
    }
    if (jenis == 'sebagian10' && orang.tahun < 10) {
      return _tolak(
        clientId,
        'ditolak',
        'Pengambilan 10% hanya untuk kepesertaan minimal 10 tahun.',
      );
    }
    final nominal = jenis == 'seluruhnya'
        ? saldo.total
        : (saldo.total * 10) ~/ 100;
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
    return _opSelesai[nomor]?[clientId];
  }

  /// Hasil sukses disimpan supaya clientId yang sama tidak diproses dua kali.
  Map<String, dynamic> _simpanOp(
    String nomor,
    String clientId,
    Map<String, dynamic> hasil,
  ) {
    if (hasil['ok'] != true) return {'clientId': clientId, ...hasil};
    final item = hasil['item'] as Map<String, dynamic>;
    _opSelesai.putIfAbsent(nomor, () => {})[clientId] = item;
    return {'clientId': clientId, 'alreadyApplied': false, ...hasil};
  }

  Map<String, dynamic> _bayarIuran(String nomor, Map<String, dynamic> op) {
    final id = '${op['tagihanId'] ?? ''}';
    final tagihan = (_tagihan[nomor] ?? const <_Tagihan>[])
        .where((t) => t.id == id)
        .firstOrNull;
    if (tagihan == null) {
      return {'ok': false, 'code': 'ditolak', 'message': 'Tagihan tidak ada.'};
    }
    if (tagihan.dibayar != null) {
      return {
        'ok': false,
        'code': 'ditolak',
        'message': 'Tagihan ${tagihan.periode} sudah lunas.',
      };
    }
    final nominal = op['nominal'];
    final harus = _tarifMandiri[tagihan.kelas]!;
    if (nominal is! num || nominal.toInt() != harus) {
      return {
        'ok': false,
        'code': 'ditolak',
        'message': 'Nominal harus ${tagihan.nominal}.',
      };
    }
    tagihan.dibayar = DateTime.now().toUtc().toIso8601String();
    return {'ok': true, 'item': tagihan.json};
  }

  Map<String, dynamic> _ubahKelas(String nomor, Map<String, dynamic> op) {
    final kelas = '${op['kelas'] ?? ''}';
    if (!_tarifMandiri.containsKey(kelas)) {
      return {'ok': false, 'code': 'jenis', 'message': 'Kelas tidak dikenal.'};
    }
    if (_kelas[nomor] == kelas) {
      return {
        'ok': false,
        'code': 'ditolak',
        'message': 'Kelas tujuan sama dengan kelas sekarang.',
      };
    }
    final menunggak = (_tagihan[nomor] ?? const <_Tagihan>[]).any(
      (t) => t.dibayar == null,
    );
    if (menunggak) {
      return {
        'ok': false,
        'code': 'ditolak',
        'message': 'Lunasi tagihan iuran dulu.',
      };
    }
    _kelas[nomor] = kelas;
    return {
      'ok': true,
      'item': {'kelas': kelas},
    };
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
      'kelas': _kelas[nomor] ?? orang.kelas,
      'faskes': orang.faskes,
      'tahunKepesertaan': orang.tahun,
      'aktif': true,
      'kepesertaan': orang.kepesertaan,
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

class _Tagihan {
  _Tagihan(this.id, this.periode, this.kelas, this.dibayar);

  final String id;
  final String periode;
  final String kelas;
  String? dibayar;

  int get nominal => Store._tarifMandiri[kelas]!;

  Map<String, dynamic> get json => {
    'id': id,
    'periode': periode,
    'kelas': kelas,
    'nominal': nominal,
    'status': dibayar == null ? 'belumBayar' : 'lunas',
    'dibayar': ?dibayar,
  };
}

List<Map<String, dynamic>> _iuranBulanan(
  String perusahaan, {
  required (int, int) dari,
  required (int, int) sampai,
  required int pekerja,
  required int pemberiKerja,
}) {
  final hasil = <Map<String, dynamic>>[];
  var (tahun, bulan) = sampai;
  while (tahun > dari.$1 || (tahun == dari.$1 && bulan >= dari.$2)) {
    hasil.add({
      'periode': '$tahun-${bulan.toString().padLeft(2, '0')}',
      'pemberiKerja': perusahaan,
      'potonganPekerja': pekerja,
      'porsiPemberiKerja': pemberiKerja,
    });
    bulan--;
    if (bulan == 0) {
      bulan = 12;
      tahun--;
    }
  }
  return hasil;
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

    final bacaan = await _call(client, 'GET', '$base/v1/artikel', null, token);
    _expect(bacaan.status == 200, 'artikel 200');
    _expect(bacaan.json['artikel'] is List, 'artikel berupa daftar');
    _expect((bacaan.json['artikel'] as List).length == 4, 'empat bacaan');

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

    Future<dynamic> op(String token, Map<String, dynamic> body) async {
      final res = await _call(client, 'POST', '$base/v1/outbox', {
        'ops': [body],
      }, token);
      return res.json['results'][0];
    }

    // 0001: role A aktif. Masih bekerja, jadi seluruh saldo ditolak.
    _expect(
      (awal.json['peserta']['kepesertaan'] as List).length == 1,
      '0001 satu role',
    );
    _expect(!awal.json.containsKey('tagihan'), '0001 tidak menerima tagihan');
    final seluruh1 = await op(token, {
      'op': 'dana',
      'clientId': 'dana-seluruh-1',
      'jenis': 'seluruhnya',
      'alasan': 'Masih bekerja tapi coba',
      'nominal': 11250000,
      'expectedSaldoTotal': 11250000,
    });
    _expect(seluruh1['code'] == 'ditolak', '0001 masih bekerja');
    final bayar1 = await op(token, {
      'op': 'bayarIuran',
      'clientId': 'bayar-1',
      'tagihanId': 'T-0002-2026-11',
      'nominal': 35000,
    });
    _expect(bayar1['code'] == 'peran_ditolak', '0001 bukan mandiri');

    // 0002: role B. Tidak ada saldo JHT, ada tagihan.
    final login2 = await _call(client, 'POST', '$base/auth/login', {
      'nomor': '0002',
      'sandi': 'belajar',
    });
    final token2 = login2.json['accessToken'] as String;
    final snap2 = await _call(client, 'GET', '$base/v1/snapshot', null, token2);
    _expect(!snap2.json.containsKey('saldo'), '0002 tidak menerima saldo');
    _expect((snap2.json['tagihan'] as List).length == 3, '0002 tiga tagihan');
    final dana2 = await op(token2, {
      'op': 'dana',
      'clientId': 'dana-2',
      'jenis': 'sebagian10',
      'alasan': 'Bukan role perusahaan',
      'nominal': 0,
      'expectedSaldoTotal': 0,
    });
    _expect(dana2['code'] == 'peran_ditolak', '0002 bukan perusahaan');
    final kelasDini = await op(token2, {
      'op': 'ubahKelas',
      'clientId': 'kelas-dini',
      'kelas': 'dua',
    });
    _expect(kelasDini['code'] == 'ditolak', 'ubah kelas saat menunggak');
    final bayar2 = await op(token2, {
      'op': 'bayarIuran',
      'clientId': 'bayar-2',
      'tagihanId': 'T-0002-2026-11',
      'nominal': 35000,
    });
    _expect(bayar2['ok'] == true, '0002 bayar tagihan');
    final bayarUlang = await op(token2, {
      'op': 'bayarIuran',
      'clientId': 'bayar-2',
      'tagihanId': 'T-0002-2026-11',
      'nominal': 35000,
    });
    _expect(bayarUlang['alreadyApplied'] == true, 'bayar idempoten');
    final kelas2 = await op(token2, {
      'op': 'ubahKelas',
      'clientId': 'kelas-2',
      'kelas': 'dua',
    });
    _expect(kelas2['ok'] == true, '0002 ubah kelas setelah lunas');
    final snap2b = await _call(
      client,
      'GET',
      '$base/v1/snapshot',
      null,
      token2,
    );
    _expect(snap2b.json['peserta']['kelas'] == 'dua', 'kelas baru tersimpan');

    // 0003: role A berhenti + role B aktif. Dua-duanya terkirim.
    final login3 = await _call(client, 'POST', '$base/auth/login', {
      'nomor': '0003',
      'sandi': 'belajar',
    });
    final token3 = login3.json['accessToken'] as String;
    final snap3 = await _call(client, 'GET', '$base/v1/snapshot', null, token3);
    _expect(
      (snap3.json['peserta']['kepesertaan'] as List).length == 2,
      '0003 dua role',
    );
    _expect(snap3.json['saldo']['total'] == 18000000, '0003 saldo 18 juta');
    _expect(snap3.json['tagihan'] is List, '0003 menerima tagihan');
    final sebagian3 = await op(token3, {
      'op': 'dana',
      'clientId': 'dana-3a',
      'jenis': 'sebagian10',
      'alasan': 'Sudah berhenti bekerja',
      'nominal': 1800000,
      'expectedSaldoTotal': 18000000,
    });
    _expect(sebagian3['code'] == 'ditolak', '0003 tidak lewat jalur 10%');
    final seluruh3 = await op(token3, {
      'op': 'dana',
      'clientId': 'dana-3b',
      'jenis': 'seluruhnya',
      'alasan': 'Sudah berhenti bekerja',
      'nominal': 18000000,
      'expectedSaldoTotal': 18000000,
    });
    _expect(seluruh3['ok'] == true, '0003 ambil seluruh saldo');

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
