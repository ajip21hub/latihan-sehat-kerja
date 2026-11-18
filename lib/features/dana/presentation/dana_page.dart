import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../ui/sehat_widgets.dart';
import '../../peserta/presentation/pita_antrean.dart';
import '../../peserta/presentation/sesi_controller.dart';
import 'dana_controller.dart';

class DanaPage extends ConsumerWidget {
  const DanaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peserta = ref.watch(sesiProvider).value?.peserta;
    final dana = ref.watch(danaProvider);
    if (peserta == null) return const SizedBox.shrink();
    return Scaffold(
      appBar: AppBar(title: const Text('Dana hari tua')),
      body: SehatScroll(
        children: [
          const PitaAntrean(),
          Catatan('Kepesertaan ${peserta.tahunKepesertaan} tahun'),
          const SizedBox(height: 8),
          Uang(rupiah(dana.saldo.total)),
          const SizedBox(height: 12),
          Lembaran(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                BarisNilai('Iuran peserta', rupiah(dana.saldo.iuranPeserta)),
                const Divider(height: 1),
                BarisNilai(
                  'Iuran pemberi kerja',
                  rupiah(dana.saldo.iuranPemberiKerja),
                ),
                const Divider(height: 1),
                BarisNilai('Pengembangan', rupiah(dana.saldo.pengembangan)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Catatan(
            'Angka ini contoh. Saldo JHT sungguhan adalah iuran ditambah hasil pengembangan, dan dicek lewat kanal resmi.',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.push('/dana/aju'),
            child: const Text('Ajukan pengambilan'),
          ),
          const SizedBox(height: 28),
          Text('Pengajuan', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          if (dana.pengajuan.isEmpty)
            const Catatan('Belum ada pengajuan dana.')
          else
            for (final item in dana.pengajuan) ...[
              Lembaran(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.jenisLabel,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        StatusChip(item.status),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Uang(rupiah(item.nominal), size: 20),
                    const SizedBox(height: 8),
                    Text(item.alasan),
                    const SizedBox(height: 4),
                    Catatan('Perkiraan ${item.perkiraanHariKerja} hari kerja'),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}
