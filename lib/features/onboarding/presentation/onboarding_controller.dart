import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_storage.dart';

class OnboardingController extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    return ref.read(onboardingStorageProvider).sudahSelesai;
  }

  Future<void> selesaikan() async {
    await ref.read(onboardingStorageProvider).tandaiSelesai();
    state = const AsyncData(true);
  }

  Future<void> reset() async {
    await ref.read(onboardingStorageProvider).reset();
    state = const AsyncData(false);
  }
}

final onboardingProvider = AsyncNotifierProvider<OnboardingController, bool>(
  OnboardingController.new,
);
