import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import '../../data/sehat_repository.dart';

const outboxSyncTask = 'sehatkerja.outboxSync';

/// Titik masuk isolate background. Wajib top-level.
/// Isolate ini tidak melihat state UI, jadi container dibuat sendiri.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != outboxSyncTask) return true;
    WidgetsFlutterBinding.ensureInitialized();
    final container = ProviderContainer();
    try {
      await container.read(sehatRepositoryProvider).kirimAntrean();
      return true;
    } catch (e) {
      debugPrint('[bg] antrean gagal: $e');
      return false;
    } finally {
      container.dispose();
    }
  });
}

/// Hanya Android. Periodik minimal 15 menit, dan hanya saat ada jaringan.
/// iOS tidak didaftarkan, sama seperti lab Hari 3.
Future<void> registerBackgroundSync() async {
  if (defaultTargetPlatform != TargetPlatform.android) return;
  await Workmanager().initialize(callbackDispatcher);
  await Workmanager().registerPeriodicTask(
    outboxSyncTask,
    outboxSyncTask,
    frequency: const Duration(minutes: 15),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
  );
}
