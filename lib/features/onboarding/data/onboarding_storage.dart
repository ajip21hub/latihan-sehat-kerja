import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/token_storage.dart';

class OnboardingStorage {
  OnboardingStorage(this._store);

  final KeyValueStore _store;

  static const _key = 'onboarding_selesai';

  Future<bool> get sudahSelesai async {
    final val = await _store.read(_key);
    return val == 'true';
  }

  Future<void> tandaiSelesai() => _store.write(_key, 'true');

  Future<void> reset() => _store.delete(_key);
}

final onboardingStorageProvider = Provider<OnboardingStorage>((ref) {
  final store = ref.watch(keyValueStoreProvider);
  return OnboardingStorage(store);
});
