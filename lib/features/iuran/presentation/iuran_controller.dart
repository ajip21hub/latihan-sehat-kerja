import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../data/sehat_repository.dart';
import '../../peserta/domain/peserta.dart';
import '../../peserta/presentation/sesi_controller.dart';
import '../domain/iuran.dart';

class IuranState {
  const IuranState({required this.tagihan, required this.perusahaan});

  final List<TagihanIuran> tagihan;
  final List<IuranPerusahaan> perusahaan;

  /// Tertua dulu: yang paling lama menunggak dibayar lebih dulu.
  List<TagihanIuran> get belumLunas => [
    for (final t in tagihan)
      if (t.status != StatusTagihan.lunas) t,
  ]..sort((a, b) => a.periode.compareTo(b.periode));

  /// Terbaru dulu.
  List<TagihanIuran> get lunas => [
    for (final t in tagihan)
      if (t.status == StatusTagihan.lunas) t,
  ]..sort((a, b) => b.periode.compareTo(a.periode));
}

class IuranController extends Notifier<IuranState> {
  @override
  IuranState build() {
    final snap = ref.watch(snapshotProvider);
    return IuranState(
      tagihan: snap?.tagihan ?? const [],
      perusahaan: snap?.iuranPerusahaan ?? const [],
    );
  }

  Future<String?> bayar(TagihanIuran tagihan) async {
    if (ref.read(sesiProvider).value == null) return 'Sesi habis. Masuk lagi.';
    if (!tagihan.bisaDibayar) return 'Tagihan ini tidak menunggu pembayaran.';
    return _jalan(
      () => ref
          .read(sehatRepositoryProvider)
          .kirimBayarIuran(
            clientId: 'bayar-${DateTime.now().microsecondsSinceEpoch}',
            tagihanId: tagihan.id,
            nominal: tagihan.nominal,
          ),
    );
  }

  Future<String?> ubahKelas(KelasRawat tujuan) async {
    final peserta = ref.read(sesiProvider).value?.peserta;
    if (peserta == null) return 'Sesi habis. Masuk lagi.';
    final cek = cekUbahKelas(
      peserta: peserta,
      tujuan: tujuan,
      tagihan: state.tagihan,
    );
    return switch (cek) {
      UbahKelasDitolak(:final alasan) => alasan,
      UbahKelasBoleh() => _jalan(
        () => ref
            .read(sehatRepositoryProvider)
            .kirimUbahKelas(
              clientId: 'kelas-${DateTime.now().microsecondsSinceEpoch}',
              kelas: tujuan.name,
            ),
      ),
    };
  }

  Future<String?> _jalan(Future<void> Function() kirim) async {
    try {
      await kirim();
      return null;
    } on Failure catch (e) {
      return e.message;
    } finally {
      // Kelas ada di peserta, jadi sesi ikut diperbarui, bukan hanya snapshot.
      ref.read(sesiProvider.notifier).segarkanDariRepo();
    }
  }
}

final iuranProvider = NotifierProvider<IuranController, IuranState>(
  IuranController.new,
);
