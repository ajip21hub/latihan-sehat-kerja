import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../ui/sehat_theme.dart';
import '../../../ui/sehat_widgets.dart';
import '../domain/kepesertaan.dart';
import '../domain/menu_utama.dart';
import '../domain/peserta.dart';

/// Grid menu Beranda, dikelompokkan per role.
///
/// Peserta A+B melihat dua kelompok. Kelompok perusahaan tetap tampil
/// walau statusnya sudah berhenti, hanya labelnya yang berubah.
class MenuGrid extends StatelessWidget {
  const MenuGrid({super.key, required this.peserta});

  final Peserta peserta;

  @override
  Widget build(BuildContext context) {
    final boleh = menuUntuk(peserta.peran);
    final kelompok = <(String, List<MenuUtama>)>[
      for (final jenis in JenisKepesertaan.values)
        if (peserta.punya(jenis))
          (
            _judul(jenis),
            [
              for (final m in boleh)
                if (m.syarat == jenis) m,
            ],
          ),
      (
        'Layanan umum',
        [
          for (final m in boleh)
            if (m.syarat == null) m,
        ],
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (peserta.peran.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12),
            child: Catatan(
              'Jenis kepesertaan belum terbaca. Tekan "Cek sesi lagi" di Profil.',
            ),
          ),
        for (final (judul, menu) in kelompok)
          if (menu.isNotEmpty) ...[
            Text(judul, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.82,
              children: [for (final m in menu) _Ubin(m)],
            ),
            const SizedBox(height: 16),
          ],
      ],
    );
  }

  String _judul(JenisKepesertaan jenis) {
    final segmen = peserta.kepesertaan.where((k) => k.jenis == jenis);
    final aktif = segmen.any((k) => k.aktif);
    return '${jenis.label} · ${aktif ? 'aktif' : 'riwayat'}';
  }
}

class _Ubin extends StatelessWidget {
  const _Ubin(this.menu);

  final MenuUtama menu;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: SehatWarna.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: SehatWarna.line),
      ),
      child: InkWell(
        key: ValueKey('menu-${menu.name}'),
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Layanan adalah tab di shell, menu lain halaman penuh.
          if (menu == MenuUtama.layanan) {
            context.go(menu.path);
          } else {
            context.push(menu.path);
          }
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_ikon(menu), color: SehatWarna.ink),
              const SizedBox(height: 6),
              Text(
                menu.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, height: 1.2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

IconData _ikon(MenuUtama menu) => switch (menu) {
  MenuUtama.pemberiKerja => Icons.apartment_outlined,
  MenuUtama.iuranPerusahaan => Icons.receipt_long_outlined,
  MenuUtama.saldoJht => Icons.savings_outlined,
  MenuUtama.klaimJht => Icons.request_quote_outlined,
  MenuUtama.layanan => Icons.local_hospital_outlined,
  MenuUtama.tagihan => Icons.event_note_outlined,
  MenuUtama.bayar => Icons.payments_outlined,
  MenuUtama.riwayatBayar => Icons.history,
  MenuUtama.ubahKelas => Icons.swap_vert,
};

/// Dipakai juga di Profil.
String ringkasSegmen(Kepesertaan k) {
  final sampai = k.selesai == null ? 'sekarang' : tanggalPendek(k.selesai!);
  final tempat = k.pemberiKerja == null ? '' : ', ${k.pemberiKerja}';
  return '${k.status.label}$tempat (${tanggalPendek(k.mulai)} – $sampai)';
}
