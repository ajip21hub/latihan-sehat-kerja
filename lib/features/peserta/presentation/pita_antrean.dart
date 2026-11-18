import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/sync/hari3.dart';
import '../../../data/sehat_repository.dart';
import '../../../ui/sehat_theme.dart';
import 'sesi_controller.dart';

/// Muncul selama masih ada baris outbox yang belum synced.
class PitaAntrean extends ConsumerWidget {
  const PitaAntrean({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jumlah = ref.watch(menungguProvider).value ?? 0;
    if (jumlah == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFE7F2EF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFB7D0C8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$jumlah pengajuan menunggu kirim',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 2),
          const Text(
            Hari3.menunggu,
            style: TextStyle(color: SehatWarna.inkSoft, height: 1.35),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () async {
                final pesan = await ref
                    .read(sesiProvider.notifier)
                    .kirimAntrean();
                if (!context.mounted || pesan == null) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(pesan)));
              },
              child: const Text('Kirim sekarang'),
            ),
          ),
        ],
      ),
    );
  }
}
