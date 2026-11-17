import '../../../core/format.dart';
import '../../layanan/domain/pengajuan_layanan.dart';
import 'pengajuan_dana.dart';
import 'saldo_jht.dart';

/// Aturan murni, tanpa widget dan tanpa jaringan.
/// Ini padanan use case di Hari 1: mudah diuji, UI hanya menampilkan hasilnya.
sealed class HasilAjuan {
  const HasilAjuan();
}

class AjuanDiterima extends HasilAjuan {
  const AjuanDiterima(this.pengajuan);
  final PengajuanDana pengajuan;
}

class AjuanDitolak extends HasilAjuan {
  const AjuanDitolak(this.alasan);
  final String alasan;
}

class AjukanPencairan {
  const AjukanPencairan();

  HasilAjuan call({
    required String nomorPeserta,
    required SaldoJht saldo,
    required int tahunKepesertaan,
    required JenisAmbil jenis,
    required String alasan,
    required bool adaYangMasihBerjalan,
    DateTime? sekarang,
  }) {
    final bersih = alasan.trim();
    if (bersih.length < 8) {
      return const AjuanDitolak('Alasan minimal 8 huruf.');
    }
    if (adaYangMasihBerjalan) {
      return const AjuanDitolak('Masih ada pengajuan dana yang belum selesai.');
    }
    if (saldo.total <= 0) {
      return const AjuanDitolak('Saldo kosong.');
    }

    final nominal = switch (jenis) {
      JenisAmbil.seluruhnya => saldo.total,
      JenisAmbil.sebagian10 => () {
        if (tahunKepesertaan < 10) return -1;
        return (saldo.total * 10) ~/ 100;
      }(),
    };
    if (nominal < 0) {
      return const AjuanDitolak(
        'Pengambilan 10% hanya untuk kepesertaan minimal 10 tahun. '
        'Di aturan resmi, ini untuk peserta yang masih aktif.',
      );
    }
    if (nominal == 0) return const AjuanDitolak('Nominal terlalu kecil.');

    final id = (sekarang ?? DateTime.now()).millisecondsSinceEpoch.toString();
    return AjuanDiterima(
      PengajuanDana(
        id: id,
        nomorPeserta: nomorPeserta,
        jenis: jenis,
        nominal: nominal,
        alasan: bersih,
        status: StatusPengajuan.diajukan,
        perkiraanHariKerja: perkiraanHariKerja(nominal),
      ),
    );
  }
}
