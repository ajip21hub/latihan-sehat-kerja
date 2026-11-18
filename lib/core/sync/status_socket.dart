import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../config/env.dart';
import '../storage/token_storage.dart';
import '../../data/sehat_repository.dart';
import '../../features/peserta/presentation/sesi_controller.dart';
import 'status_terapkan.dart';

typedef PenyambungSocket = Stream<String> Function(Uri uri);

Stream<String> sambungWebSocket(Uri uri) async* {
  final channel = WebSocketChannel.connect(uri);
  try {
    await channel.ready;
    yield* channel.stream.map((pesan) => pesan.toString());
  } finally {
    await channel.sink.close();
  }
}

/// Menyambung ulang dengan jeda 1, 2, 4, ... maksimal 15 detik.
/// [tutup] membatalkan timer dan menutup socket.
class StatusSocket {
  StatusSocket({
    required this.token,
    required this.apiBase,
    required this.onPesan,
    this.backoff = jedaSambung,
    this.sambungkan = sambungWebSocket,
  });

  final Future<String?> Function() token;
  final String apiBase;
  final Future<void> Function(String pesan) onPesan;
  final Duration Function(int attempt) backoff;
  final PenyambungSocket sambungkan;

  var _tutup = false;
  var _attempt = 0;
  Timer? _timer;
  StreamSubscription<String>? _sub;

  void mulai() {
    _tutup = false;
    unawaited(_buka());
  }

  Future<void> _buka() async {
    if (_tutup) return;
    final akses = await token();
    if (_tutup || akses == null || akses.isEmpty) return;
    try {
      final stream = sambungkan(alamatStream(apiBase, akses));
      _sub = stream.listen(
        (pesan) {
          _attempt = 0;
          unawaited(onPesan(pesan));
        },
        onError: (Object _, StackTrace _) => _jadwalUlang(),
        onDone: _jadwalUlang,
        cancelOnError: true,
      );
    } catch (_) {
      _jadwalUlang();
    }
  }

  void _jadwalUlang() {
    if (_tutup) return;
    _attempt++;
    _timer?.cancel();
    _timer = Timer(backoff(_attempt), () {
      unawaited(_buka());
    });
  }

  Future<void> tutup() async {
    _tutup = true;
    _timer?.cancel();
    await _sub?.cancel();
    _sub = null;
  }
}

final statusSocketProvider = Provider<void>((ref) {
  final sesi = ref.watch(sesiProvider).asData?.value;
  if (sesi == null) return;
  final repo = ref.read(sehatRepositoryProvider);
  final storage = ref.read(tokenStorageProvider);
  final socket = StatusSocket(
    token: () => storage.accessToken,
    apiBase: Env.apiBaseUrl,
    onPesan: (pesan) async {
      final peristiwa = bacaPeristiwa(pesan);
      if (peristiwa == null) return;
      final berubah = await repo.terapkanPeristiwa(peristiwa);
      if (berubah) ref.invalidate(snapshotProvider);
    },
  );
  socket.mulai();
  ref.onDispose(socket.tutup);
});
