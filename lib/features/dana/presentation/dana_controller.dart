import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/failure.dart';
import '../../../data/sehat_repository.dart';
import '../../peserta/presentation/sesi_controller.dart';
import '../domain/ajukan_pencairan.dart';
import '../domain/pengajuan_dana.dart';
import '../domain/saldo_jht.dart';

class DanaState {
  const DanaState({required this.saldo, required this.pengajuan});

  final SaldoJht saldo;
  final List<PengajuanDana> pengajuan;
}

class DanaController extends Notifier<DanaState> {
  @override
  DanaState build() {
    final snap = ref.watch(snapshotProvider);
    if (snap == null) {
      return const DanaState(
        saldo: SaldoJht(iuranPeserta: 0, iuranPemberiKerja: 0, pengembangan: 0),
        pengajuan: [],
      );
    }
    return DanaState(saldo: snap.saldo, pengajuan: snap.dana);
  }

  /// Aturan dicek dulu di klien, lalu dikirim. Server mengulang cek yang sama.
  Future<String?> ajukan({
    required JenisAmbil jenis,
    required String alasan,
  }) async {
    final peserta = ref.read(sesiProvider).value?.peserta;
    if (peserta == null) return 'Sesi habis. Masuk lagi.';
    final sekarang = state;
    final hasil = const AjukanPencairan().call(
      nomorPeserta: peserta.nomor,
      saldo: sekarang.saldo,
      tahunKepesertaan: peserta.tahunKepesertaan,
      jenis: jenis,
      alasan: alasan,
      adaYangMasihBerjalan: sekarang.pengajuan.any(
        (item) => item.masihBerjalan,
      ),
    );
    return switch (hasil) {
      AjuanDitolak(:final alasan) => alasan,
      AjuanDiterima(:final pengajuan) => _kirim(
        pengajuan,
        sekarang.saldo.total,
      ),
    };
  }

  Future<String?> _kirim(
    PengajuanDana pengajuan,
    int expectedSaldoTotal,
  ) async {
    try {
      await ref
          .read(sehatRepositoryProvider)
          .kirimDana(
            clientId: pengajuan.id,
            jenis: pengajuan.jenis.name,
            alasan: pengajuan.alasan,
            nominal: pengajuan.nominal,
            expectedSaldoTotal: expectedSaldoTotal,
          );
      ref.invalidate(snapshotProvider);
      return null;
    } on Failure catch (e) {
      ref.invalidate(snapshotProvider);
      return e.message;
    }
  }
}

final danaProvider = NotifierProvider<DanaController, DanaState>(
  DanaController.new,
);
