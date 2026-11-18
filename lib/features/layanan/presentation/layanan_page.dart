import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../ui/sehat_theme.dart';
import '../../../ui/sehat_widgets.dart';
import '../../peserta/presentation/pita_antrean.dart';
import 'layanan_controller.dart';

class LayananPage extends ConsumerWidget {
  const LayananPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saringan = ref.watch(saringanLayananProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Layanan kesehatan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/layanan/baru'),
        icon: const Icon(Icons.add),
        label: const Text('Ajukan'),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Column(
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
                child: PitaAntrean(),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Cari keluhan atau faskes',
                    prefixIcon: Icon(Icons.search, color: SehatWarna.inkSoft),
                  ),
                  onChanged: (nilai) =>
                      ref.read(kataCariProvider.notifier).isi(nilai),
                ),
              ),
              Expanded(
                child: saringan.when(
                  skipLoadingOnReload: true,
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('$error')),
                  data: (daftar) {
                    if (daftar.isEmpty) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Catatan('Belum ada pengajuan.'),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 88),
                      itemCount: daftar.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (_, i) {
                        final item = daftar[i];
                        return Lembaran(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.jenisLabel,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  StatusChip(item.status),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                item.faskes,
                                style: const TextStyle(
                                  color: SehatWarna.inkSoft,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(tanggalPendek(item.tanggal)),
                              const SizedBox(height: 8),
                              Text(item.keluhan),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
