import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/sync/status_socket.dart';
import 'router/app_router.dart';
import 'ui/sehat_theme.dart';

class SehatKerjaApp extends ConsumerWidget {
  const SehatKerjaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(statusSocketProvider);
    return MaterialApp.router(
      title: 'Latihan SehatKerja',
      debugShowCheckedModeBanner: false,
      theme: sehatTheme(),
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
