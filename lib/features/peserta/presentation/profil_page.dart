import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../ui/sehat_widgets.dart';
import 'menu_grid.dart';
import 'sesi_controller.dart';

class ProfilPage extends ConsumerWidget {
  const ProfilPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sesi = ref.watch(sesiProvider).value;
    if (sesi == null) return const SizedBox.shrink();
    final peserta = sesi.peserta;
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SehatScroll(
        children: [
          if (sesi.fromCache)
            const PitaLuring(
              'Server tidak terjangkau. Kamu tetap masuk karena snapshot terakhir ada.',
            ),
          Lembaran(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                BarisNilai('Nama', peserta.nama, tebal: true),
                const Divider(height: 1),
                BarisNilai('Nomor peserta', peserta.nomor),
                const Divider(height: 1),
                BarisNilai('NIK', peserta.nikDisamarkan),
                const Divider(height: 1),
                BarisNilai('Kelas rawat', peserta.kelas.label),
                const Divider(height: 1),
                BarisNilai('Faskes', peserta.faskes),
                const Divider(height: 1),
                BarisNilai(
                  'Lama kepesertaan',
                  '${peserta.tahunKepesertaan} tahun',
                ),
                const Divider(height: 1),
                BarisNilai('API', Env.apiBaseUrl),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('Kepesertaan', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Lembaran(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                BarisNilai(
                  'Iuran bulan ini',
                  peserta.pembayarIuran,
                  tebal: true,
                ),
                for (final k in peserta.kepesertaan) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          k.jenis.label,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 2),
                        Catatan(ringkasSegmen(k)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Catatan(
            'NIK disamarkan di layar. Di aplikasi sungguhan, nomor ini '
            'tidak boleh masuk log. Token juga disamarkan di log debug.',
          ),
          const SizedBox(height: 20),
          OutlinedButton(
            onPressed: () => context.push('/onboarding?view=true'),
            child: const Text('Panduan aplikasi (Onboarding)'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () async {
              final pesan = await ref.read(sesiProvider.notifier).cekLagi();
              if (pesan != null && context.mounted) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(pesan)));
              }
            },
            child: const Text('Cek sesi lagi'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: () => ref.read(sesiProvider.notifier).keluar(),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}
