import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/sehat_theme.dart';
import '../../../ui/sehat_widgets.dart';
import '../domain/artikel.dart';
import 'artikel_controller.dart';

class ArtikelBacaPage extends ConsumerWidget {
  const ArtikelBacaPage({super.key, required this.id});

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daftar = ref.watch(artikelProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Bacaan')),
      body: daftar.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => const SehatScroll(
          children: [PesanError('Bacaan gagal dibuka. Coba lagi.')],
        ),
        data: (data) {
          Artikel? artikel;
          for (final item in data.daftar) {
            if (item.id == id) artikel = item;
          }
          if (artikel == null) {
            return const SehatScroll(
              children: [Catatan('Bacaan ini tidak ada di perangkat.')],
            );
          }
          return SehatScroll(
            children: [
              if (data.fromCache)
                const PitaLuring(
                  'Teks ini terakhir diunduh dari server.',
                  judul: 'Bacaan dari data tersimpan',
                ),
              Text(
                artikel.judul,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: SehatWarna.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                artikel.isi,
                style: const TextStyle(height: 1.45, fontSize: 16),
              ),
            ],
          );
        },
      ),
    );
  }
}
