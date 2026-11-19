import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/analytics/analytics_service.dart';

import '../features/artikel/presentation/artikel_baca_page.dart';
import '../features/artikel/presentation/artikel_page.dart';
import '../features/dana/presentation/aju_dana_page.dart';
import '../features/dana/presentation/dana_page.dart';
import '../features/iuran/presentation/iuran_pages.dart';
import '../features/layanan/presentation/aju_layanan_page.dart';
import '../features/layanan/presentation/layanan_page.dart';
import '../features/onboarding/presentation/onboarding_controller.dart';
import '../features/onboarding/presentation/onboarding_page.dart';
import '../features/peserta/presentation/beranda_page.dart';
import '../features/peserta/presentation/login_page.dart';
import '../features/peserta/presentation/perusahaan_pages.dart';
import '../features/peserta/presentation/profil_page.dart';
import '../features/peserta/presentation/sesi_controller.dart';
import '../features/peserta/presentation/splash_page.dart';
import 'auth_redirect.dart';

final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final appRouterProvider = Provider<GoRouter>((ref) {
  final tick = ValueNotifier(0);
  ref.onDispose(tick.dispose);
  ref.listen(sesiProvider, (_, _) => tick.value++);
  ref.listen(onboardingProvider, (_, _) => tick.value++);

  final observer = ref.watch(analyticsObserverProvider);

  final router = GoRouter(
    navigatorKey: _rootKey,
    initialLocation: Routes.beranda,
    observers: [?observer],
    refreshListenable: tick,
    redirect: (_, state) {
      final auth = ref.read(sesiProvider);
      final onboarding = ref.read(onboardingProvider);
      final isInitialLoading =
          (auth.isLoading && !auth.hasValue && !auth.hasError) ||
          (onboarding.isLoading &&
              !onboarding.hasValue &&
              !onboarding.hasError);
      return authRedirect(
        auth,
        state.uri,
        onboardingSelesai: onboarding.value ?? false,
        isInitialLoading: isInitialLoading,
        peran: auth.value?.peserta.peran,
      );
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashPage()),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, state) => OnboardingPage(
          isViewOnly: state.uri.queryParameters['view'] == 'true',
        ),
      ),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginPage()),
      // Menu role. Di luar shell supaya tampil penuh tanpa bottom nav.
      // Guard di authRedirect yang memastikan role cocok.
      GoRoute(
        path: '/pemberi-kerja',
        builder: (_, _) => const PemberiKerjaPage(),
      ),
      GoRoute(
        path: '/iuran-perusahaan',
        builder: (_, _) => const IuranPerusahaanPage(),
      ),
      GoRoute(
        path: '/dana',
        builder: (_, _) => const DanaPage(),
        routes: [GoRoute(path: 'aju', builder: (_, _) => const AjuDanaPage())],
      ),
      GoRoute(path: '/iuran/tagihan', builder: (_, _) => const TagihanPage()),
      GoRoute(
        path: '/iuran/bayar',
        builder: (_, state) =>
            BayarIuranPage(tagihanId: state.uri.queryParameters['id']),
      ),
      GoRoute(
        path: '/iuran/riwayat',
        builder: (_, _) => const RiwayatBayarPage(),
      ),
      GoRoute(path: '/kelas', builder: (_, _) => const UbahKelasPage()),
      GoRoute(
        path: '/artikel',
        builder: (_, _) => const ArtikelPage(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, state) =>
                ArtikelBacaPage(id: state.pathParameters['id']!),
          ),
        ],
      ),
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
