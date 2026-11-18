import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/sehat_repository.dart';
import '../domain/artikel.dart';

final artikelProvider = FutureProvider.autoDispose<DaftarArtikel>((ref) {
  return ref.watch(sehatRepositoryProvider).muatArtikel();
});
