import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../data/sehat_repository.dart';
import '../../peserta/presentation/sesi_controller.dart';
import '../domain/pengajuan_layanan.dart';

class LayananController extends Notifier<List<PengajuanLayanan>> {
  @override
  List<PengajuanLayanan> build() {
    return ref.watch(snapshotProvider)?.layanan ?? const [];
  }

  Future<String?> ajukan({
    required JenisLayanan jenis,
    required String faskes,
    required String keluhan,
  }) async {
    if (ref.read(sesiProvider).value == null) {
      return 'Sesi habis. Masuk lagi.';
    }
    try {
      await ref
          .read(sehatRepositoryProvider)
          .kirimLayanan(
            clientId: 'layanan-${DateTime.now().microsecondsSinceEpoch}',
            jenis: jenis.name,
            faskes: faskes.trim(),
            keluhan: keluhan.trim(),
          );
      ref.invalidate(snapshotProvider);
      return null;
    } on Failure catch (e) {
      ref.invalidate(snapshotProvider);
      return e.message;
    }
  }
}

final layananProvider =
    NotifierProvider<LayananController, List<PengajuanLayanan>>(
      LayananController.new,
    );

class KataCari extends Notifier<String> {
  @override
  String build() => '';

  void isi(String nilai) => state = nilai;
}

final kataCariProvider = NotifierProvider.autoDispose<KataCari, String>(
  KataCari.new,
);

/// Debounce tanpa `Timer`. Provider lama di-dispose sebelum delay selesai
/// kalau kata pencarian berubah. Daftar ini lokal, jadi tidak ada request.
final saringanLayananProvider =
    FutureProvider.autoDispose<List<PengajuanLayanan>>((ref) async {
      final kata = ref.watch(kataCariProvider).trim().toLowerCase();
      final semua = ref.watch(layananProvider);
      if (kata.isEmpty) return semua;

      var disposed = false;
      ref.onDispose(() => disposed = true);
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (disposed || !ref.mounted) return const [];
      return [
        for (final item in semua)
          if (item.keluhan.toLowerCase().contains(kata) ||
              item.faskes.toLowerCase().contains(kata) ||
              item.jenisLabel.toLowerCase().contains(kata))
            item,
      ];
    });
