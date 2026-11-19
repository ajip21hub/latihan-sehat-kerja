import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehat_kerja/core/storage/token_storage.dart';
import 'package:sehat_kerja/features/onboarding/data/onboarding_storage.dart';
import 'package:sehat_kerja/features/onboarding/presentation/onboarding_controller.dart';
import 'package:sehat_kerja/features/onboarding/presentation/onboarding_page.dart';

void main() {
  group('OnboardingStorage', () {
    test('default adalah false, berubah true setelah ditandai', () async {
      final memory = MemoryKeyValueStore();
      final storage = OnboardingStorage(memory);

      expect(await storage.sudahSelesai, isFalse);

      await storage.tandaiSelesai();
      expect(await storage.sudahSelesai, isTrue);

      await storage.reset();
      expect(await storage.sudahSelesai, isFalse);
    });
  });

  group('OnboardingController', () {
    test('memperbarui state saat selesaikan dan reset', () async {
      final memory = MemoryKeyValueStore();
      final container = ProviderContainer(
        overrides: [keyValueStoreProvider.overrideWithValue(memory)],
      );
      addTearDown(container.dispose);

      final awal = await container.read(onboardingProvider.future);
      expect(awal, isFalse);

      await container.read(onboardingProvider.notifier).selesaikan();
      expect(container.read(onboardingProvider).value, isTrue);

      await container.read(onboardingProvider.notifier).reset();
      expect(container.read(onboardingProvider).value, isFalse);
    });
  });

  group('OnboardingPage Widget', () {
    testWidgets('menampilkan carousel onboarding dan tombol navigasi', (
      tester,
    ) async {
      final memory = MemoryKeyValueStore();
      final container = ProviderContainer(
        overrides: [keyValueStoreProvider.overrideWithValue(memory)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: OnboardingPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Cek header dan slide pertama
      expect(find.text('SehatKerja'), findsOneWidget);
      expect(find.text('Layanan Kesehatan Terpadu'), findsOneWidget);
      expect(find.text('Lewati'), findsAtLeastNWidgets(1));
      expect(find.text('Lanjut'), findsOneWidget);

      // Tekan tombol lanjut
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();

      // Cek slide kedua
      expect(find.text('Pantau Saldo Jaminan Hari Tua'), findsOneWidget);

      // Tekan lanjut lagi ke slide ketiga (terakhir)
      await tester.tap(find.text('Lanjut'));
      await tester.pumpAndSettle();

      // Cek slide ketiga
      expect(find.text('Akses Mandiri & Siaga Offline'), findsOneWidget);
      expect(find.text('Mulai Sekarang'), findsOneWidget);

      // Tekan tombol "Mulai Sekarang"
      await tester.tap(find.text('Mulai Sekarang'));
      await tester.pumpAndSettle();

      // State onboarding harus sudah selesai
      expect(container.read(onboardingProvider).value, isTrue);
      expect(await memory.read('onboarding_selesai'), 'true');
    });

    testWidgets('menekan Lewati langsung menyelesaikan onboarding', (
      tester,
    ) async {
      final memory = MemoryKeyValueStore();
      final container = ProviderContainer(
        overrides: [keyValueStoreProvider.overrideWithValue(memory)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: OnboardingPage()),
        ),
      );
      await tester.pumpAndSettle();

      // Tekan salah satu tombol Lewati
      await tester.tap(find.text('Lewati').first);
      await tester.pumpAndSettle();

      expect(container.read(onboardingProvider).value, isTrue);
    });

    testWidgets('mode viewOnly menampilkan tombol tutup', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: OnboardingPage(isViewOnly: true)),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.close), findsOneWidget);
      expect(find.text('Lewati'), findsNothing);
    });
  });
}
