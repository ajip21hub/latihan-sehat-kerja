import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bel "sesi berakhir".
///
/// Dio di lapisan core membunyikannya. SesiController di fitur peserta
/// yang mendengarkan. Core tidak meng-import fitur, jadi tidak ada
/// siklus `core ↔ peserta`.
class SessionExpired extends Notifier<int> {
  @override
  int build() => 0;

  void notifyListenersOfExpiry() => state++;
}

final sessionExpiredProvider = NotifierProvider<SessionExpired, int>(
  SessionExpired.new,
);
