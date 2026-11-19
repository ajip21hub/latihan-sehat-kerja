import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../core/network/session_events.dart';
import '../../../data/app_snapshot.dart';
import '../../../data/sehat_repository.dart';
import '../domain/auth_session.dart';

class SesiController extends AsyncNotifier<AuthSession?> {
  @override
  Future<AuthSession?> build() async {
    ref.listen(sessionExpiredProvider, (prev, next) {
      if (prev == null || next == prev) return;
      // Jangan mengubah state di tengah build yang sedang menunggu jaringan.
      Future(() {
        if (!ref.mounted) return;
        ref.read(sehatRepositoryProvider).lupakanMemori();
        state = const AsyncData(null);
      });
    });
    return ref.read(sehatRepositoryProvider).pulihkan();
  }

  Future<String?> masuk(String nomor, String sandi) async {
    try {
      final sesi = await ref.read(sehatRepositoryProvider).masuk(nomor, sandi);
      state = AsyncData(sesi);
      return null;
    } on Failure catch (e) {
      return e.message;
    } catch (_) {
      return 'Data lokal gagal dibuka. Muat ulang aplikasi.';
    }
  }

  Future<void> keluar() async {
    await ref.read(sehatRepositoryProvider).keluar();
    state = const AsyncData(null);
  }

  /// Mengirim antrean tanpa mengubah sesi menjadi loading.
  Future<String?> kirimAntrean() async {
    final sebelumnya = state.value;
    try {
      final laporan = await ref.read(sehatRepositoryProvider).kirimAntrean();
      final terakhir = ref.read(sehatRepositoryProvider).terakhir;
      if (terakhir != null && sebelumnya != null) {
        state = AsyncData(
          AuthSession(peserta: terakhir.peserta, fromCache: terakhir.fromCache),
        );
      }
      if (laporan.gagal.isEmpty) return null;
      return laporan.gagal.values.first;
    } on Failure catch (e) {
      return e.message;
    }
  }

  /// Menyalin snapshot terakhir repository ke sesi tanpa request baru.
  /// Dipakai setelah aksi yang bisa mengubah data peserta (kelas, role).
  void segarkanDariRepo() {
    final terakhir = ref.read(sehatRepositoryProvider).terakhir;
    if (terakhir == null || state.value == null) return;
    state = AsyncData(
      AuthSession(peserta: terakhir.peserta, fromCache: terakhir.fromCache),
    );
  }

  /// Coba jaringan lagi tanpa membuang sesi yang sedang tampil.
  /// `AsyncLoading` akan mengosongkan value dan router balik ke splash.
  Future<String?> cekLagi() async {
    final sebelumnya = state.value;
    try {
      final sesi = await ref.read(sehatRepositoryProvider).muatUlang();
      state = AsyncData(sesi);
      return null;
    } on NetworkFailure catch (e) {
      if (sebelumnya != null) {
        state = AsyncData(
          AuthSession(peserta: sebelumnya.peserta, fromCache: true),
        );
      }
      return e.message;
    } on Failure catch (e) {
      return e.message;
    }
  }
}

final sesiProvider = AsyncNotifierProvider<SesiController, AuthSession?>(
  SesiController.new,
);

/// Mengikuti [sesiProvider]. Isi daftar diisi repository sebelum state sesi berubah.
final snapshotProvider = Provider<AppSnapshot?>((ref) {
  ref.watch(sesiProvider);
  return ref.read(sehatRepositoryProvider).terakhir;
});
