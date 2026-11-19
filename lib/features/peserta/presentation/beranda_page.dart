import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../core/format.dart';
import '../../../ui/sehat_theme.dart';
import '../../../ui/sehat_widgets.dart';
import '../../dana/presentation/dana_controller.dart';
import 'pita_antrean.dart';
import 'sesi_controller.dart';

class BerandaPage extends ConsumerWidget {
  const BerandaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesi = ref.watch(sesiProvider).value;
    final peserta = sesi?.peserta;
    final saldo = ref.watch(danaProvider).saldo.total;
    if (peserta == null || sesi == null) return const SizedBox.shrink();
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
          const SizedBox(height: 16),
          Lembaran(
            padding: EdgeInsets.zero,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => context.go('/dana'),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Dana hari tua terkumpul',
                            style: TextStyle(color: SehatWarna.inkSoft),
                          ),
                          const SizedBox(height: 6),
                          Uang(rupiah(saldo), size: 26),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: SehatWarna.inkSoft),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          const Catatan(
            'Kelas rawat menentukan ruang rawat inap, bukan harga obat.',
          ),
          const SizedBox(height: 16),
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
