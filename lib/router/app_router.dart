import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/dana/presentation/aju_dana_page.dart';
import '../features/dana/presentation/dana_page.dart';
import '../features/layanan/presentation/aju_layanan_page.dart';
import '../features/layanan/presentation/layanan_page.dart';
import '../features/peserta/presentation/beranda_page.dart';
import '../features/peserta/presentation/login_page.dart';
import '../features/peserta/presentation/profil_page.dart';
import '../features/peserta/presentation/sesi_controller.dart';
import '../features/peserta/presentation/splash_page.dart';
import 'auth_redirect.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  final tick = ValueNotifier(0);
  ref.onDispose(tick.dispose);
  ref.listen(sesiProvider, (_, _) => tick.value++);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.beranda,
    refreshListenable: tick,
    redirect: (_, state) => authRedirect(ref.read(sesiProvider), state.uri),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => Scaffold(
          body: shell,
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFD5DEDB))),
            ),
            child: NavigationBar(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: (index) => shell.goBranch(
                index,
                initialLocation: index == shell.currentIndex,
              ),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home),
                  label: 'Beranda',
                ),
                NavigationDestination(
                  icon: Icon(Icons.local_hospital_outlined),
                  selectedIcon: Icon(Icons.local_hospital),
                  label: 'Layanan',
                ),
                NavigationDestination(
                  icon: Icon(Icons.savings_outlined),
                  selectedIcon: Icon(Icons.savings),
                  label: 'Dana',
                ),
                NavigationDestination(
                  icon: Icon(Icons.badge_outlined),
                  selectedIcon: Icon(Icons.badge),
                  label: 'Profil',
                ),
              ],
            ),
          ),
        ),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.beranda,
                builder: (_, _) => const BerandaPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/layanan',
                builder: (_, _) => const LayananPage(),
                routes: [
                  GoRoute(
                    path: 'baru',
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const AjuLayananPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dana',
                builder: (_, _) => const DanaPage(),
                routes: [
                  GoRoute(
                    path: 'aju',
                    parentNavigatorKey: _rootKey,
                    builder: (_, _) => const AjuDanaPage(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/profil', builder: (_, _) => const ProfilPage()),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
