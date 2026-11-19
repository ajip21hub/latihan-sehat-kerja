import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/format.dart';
import '../../../ui/sehat_theme.dart';
import '../../../ui/sehat_widgets.dart';
import '../../dana/presentation/dana_controller.dart';
import '../../iuran/domain/iuran.dart';
import '../../iuran/presentation/iuran_controller.dart';
import '../domain/kepesertaan.dart';
import 'menu_grid.dart';
import 'pita_antrean.dart';
import 'sesi_controller.dart';

class BerandaPage extends ConsumerWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesi = ref.watch(sesiProvider).value;
    final peserta = sesi?.peserta;
    if (peserta == null || sesi == null) return const SizedBox.shrink();
    final saldo = ref.watch(danaProvider).saldo.total;
    final belumLunas = ref.watch(iuranProvider).belumLunas;
    return Scaffold(
      appBar: AppBar(title: const Text('Beranda')),
      body: SehatScroll(
        children: [
          if (sesi.fromCache)
            const PitaLuring(
              'Jaringan belum terbaca. Token tidak dihapus. '
              'Pengajuan baru tetap tersimpan di perangkat.',
            ),
          const PitaAntrean(),
          KartuPeserta(peserta: peserta),
          const SizedBox(height: 8),
          Catatan('Iuran bulan ini: ${peserta.pembayarIuran}'),
          const SizedBox(height: 16),
          if (peserta.punya(JenisKepesertaan.perusahaan)) ...[
            _KartuRingkas(
              judul: 'Dana hari tua terkumpul',
              nilai: rupiah(saldo),
              onTap: () => context.push('/dana'),
            ),
            const SizedBox(height: 10),
          ],
          if (peserta.punya(JenisKepesertaan.mandiri)) ...[
            _KartuRingkas(
              judul: belumLunas.isEmpty
                  ? 'Iuran mandiri'
                  : 'Tagihan ${labelPeriode(belumLunas.first.periode)}',
              nilai: belumLunas.isEmpty
                  ? 'Lunas'
                  : rupiah(belumLunas.fold(0, (n, t) => n + t.nominal)),
              onTap: () => context.push('/iuran/tagihan'),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          MenuGrid(peserta: peserta),
          FilledButton(
            onPressed: () {
              ref.read(analyticsServiceProvider).logKlikAjukanLayanan();
              context.push('/layanan/baru');
            },
            child: const Text('Ajukan layanan kesehatan'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () => context.push('/artikel'),
            child: const Text('Bacaan'),
          ),
        ],
      ),
    );
  }
}

class _KartuRingkas extends StatelessWidget {
  const _KartuRingkas({
    required this.judul,
    required this.nilai,
    required this.onTap,
  });

  final String judul;
  final String nilai;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Lembaran(
      padding: EdgeInsets.zero,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      judul,
                      style: const TextStyle(color: SehatWarna.inkSoft),
                    ),
                    const SizedBox(height: 6),
                    Uang(nilai, size: 26),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: SehatWarna.inkSoft),
            ],
          ),
        ),
      ),
    );
  }
}
