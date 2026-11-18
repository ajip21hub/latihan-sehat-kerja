import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/error/failure.dart';
import '../../../ui/sehat_widgets.dart';
import 'artikel_controller.dart';

class ArtikelPage extends ConsumerWidget {
  const ArtikelPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daftar = ref.watch(artikelProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bacaan'),
        actions: [
          IconButton(
            tooltip: 'Muat ulang',
            onPressed: () => ref.invalidate(artikelProvider),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: daftar.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => SehatScroll(
          children: [
            PesanError(
              error is Failure
                  ? error.message
                  : 'Bacaan gagal dibuka. Coba lagi.',
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () => ref.invalidate(artikelProvider),
              child: const Text('Coba lagi'),
            ),
          ],
        ),
        data: (data) => SehatScroll(
          children: [
            if (data.fromCache)
              const PitaLuring(
                'Daftar ini terakhir diunduh dari server.',
                judul: 'Bacaan dari data tersimpan',
              ),
            if (data.daftar.isEmpty)
              const Catatan('Belum ada bacaan.')
            else
              for (final artikel in data.daftar) ...[
                Lembaran(
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => context.push('/artikel/${artikel.id}'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            artikel.judul,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(artikel.ringkas),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
          ],
        ),
      ),
    );
  }
}
