import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/sehat_widgets.dart';
import '../domain/kepesertaan.dart';
import 'sesi_controller.dart';

/// Menu 1 (role A). Riwayat perusahaan tetap tampil walau sudah berhenti.
class PemberiKerjaPage extends ConsumerWidget {
  const PemberiKerjaPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final peserta = ref.watch(sesiProvider).value?.peserta;
    if (peserta == null) return const SizedBox.shrink();
    final segmen = [
      for (final k in peserta.kepesertaan)
        if (k.jenis == JenisKepesertaan.perusahaan) k,
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('Info pemberi kerja')),
      body: SehatScroll(
        children: [
          if (segmen.isEmpty)
            const Catatan('Belum ada riwayat kepesertaan lewat perusahaan.'),
          for (final k in segmen) ...[
            Lembaran(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  BarisNilai(
                    'Pemberi kerja',
                    k.pemberiKerja ?? '-',
                    tebal: true,
                  ),
                  const Divider(height: 1),
                  BarisNilai('Status', k.status.label),
                  const Divider(height: 1),
                  BarisNilai('Mulai', tanggalPendek(k.mulai)),
                  if (k.selesai != null) ...[
                    const Divider(height: 1),
                    BarisNilai('Berhenti', tanggalPendek(k.selesai!)),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 4),
          Catatan(
            peserta.masihBekerja
                ? 'Iuran bulan ini dipotong dari gaji dan ditambah porsi pemberi kerja.'
                : 'Sudah tidak bekerja di sini. Riwayat iuran dan saldo JHT '
                      'dari masa kerja ini tetap milikmu.',
          ),
        ],
      ),
    );
  }
}
