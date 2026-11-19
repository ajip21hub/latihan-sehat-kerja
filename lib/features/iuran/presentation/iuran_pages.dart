import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/format.dart';
import '../../../ui/sehat_theme.dart';
import '../../../ui/sehat_widgets.dart';
import '../../peserta/domain/peserta.dart';
import '../../peserta/presentation/pita_antrean.dart';
import '../../peserta/presentation/sesi_controller.dart';
import '../domain/iuran.dart';
import 'iuran_controller.dart';

/// Menu 2 (role A).
class IuranPerusahaanPage extends ConsumerWidget {
  const IuranPerusahaanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final daftar = ref.watch(iuranProvider).perusahaan;
    return Scaffold(
      appBar: AppBar(title: const Text('Iuran perusahaan')),
      body: SehatScroll(
        children: [
          const Catatan(
            'Potongan pekerja diambil dari gaji. Porsi pemberi kerja dibayar '
            'perusahaan. Keduanya masuk ke saldo JHT.',
          ),
          const SizedBox(height: 12),
          if (daftar.isEmpty) const Catatan('Belum ada data iuran perusahaan.'),
          for (final item in daftar) ...[
            Lembaran(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  BarisNilai(
                    labelPeriode(item.periode),
                    rupiah(item.total),
                    tebal: true,
                  ),
                  const Divider(height: 1),
                  BarisNilai('Potongan pekerja', rupiah(item.potonganPekerja)),
                  BarisNilai(
                    'Porsi pemberi kerja',
                    rupiah(item.porsiPemberiKerja),
                  ),
                  BarisNilai('Pemberi kerja', item.pemberiKerja),
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

/// Menu 6 (role B).
class TagihanPage extends ConsumerWidget {
  const TagihanPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final belum = ref.watch(iuranProvider).belumLunas;
    return Scaffold(
      appBar: AppBar(title: const Text('Tagihan iuran')),
      body: SehatScroll(
        children: [
          const PitaAntrean(),
          if (belum.isEmpty)
            const Catatan('Tidak ada tagihan. Semua iuran sudah lunas.'),
          for (final t in belum) ...[
            _KartuTagihan(
              t,
              aksi: t.bisaDibayar
                  ? FilledButton(
                      onPressed: () => context.push('/iuran/bayar?id=${t.id}'),
                      child: const Text('Bayar'),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// Menu 7 (role B). Tanpa `tagihanId`, tagihan tertua yang belum dibayar.
class BayarIuranPage extends ConsumerStatefulWidget {
  const BayarIuranPage({super.key, this.tagihanId});

  final String? tagihanId;

  @override
  ConsumerState<BayarIuranPage> createState() => _BayarIuranPageState();
}

class _BayarIuranPageState extends ConsumerState<BayarIuranPage> {
  bool _sibuk = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final peserta = ref.watch(sesiProvider).value?.peserta;
    final semua = ref.watch(iuranProvider).tagihan;
    if (peserta == null) return const SizedBox.shrink();
    final pilihan = _pilih(semua);
    return Scaffold(
      appBar: AppBar(title: const Text('Bayar iuran')),
      body: SehatScroll(
        children: [
          if (pilihan == null)
            const Catatan('Tidak ada tagihan yang menunggu pembayaran.')
          else ...[
            _KartuTagihan(pilihan),
            const SizedBox(height: 12),
            Lembaran(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BarisNilai(
                'Virtual account latihan',
                '8808${peserta.nomor}',
              ),
            ),
            const SizedBox(height: 10),
            const Catatan(
              'Simulasi. Tidak ada uang yang berpindah. Kalau server mati, '
              'pembayaran masuk antrean dan dikirim nanti.',
            ),
            if (_error != null) PesanError(_error!),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _sibuk || !pilihan.bisaDibayar
                  ? null
                  : () => _bayar(pilihan),
              child: Text(
                _sibuk ? 'Mengirim...' : 'Bayar ${rupiah(pilihan.nominal)}',
              ),
            ),
          ],
        ],
      ),
    );
  }

  TagihanIuran? _pilih(List<TagihanIuran> semua) {
    final id = widget.tagihanId;
    if (id != null) {
      for (final t in semua) {
        if (t.id == id) return t;
      }
    }
    final belum = semua.where((t) => t.bisaDibayar).toList()
      ..sort((a, b) => a.periode.compareTo(b.periode));
    return belum.firstOrNull;
  }

  Future<void> _bayar(TagihanIuran tagihan) async {
    setState(() {
      _sibuk = true;
      _error = null;
    });
    final error = await ref.read(iuranProvider.notifier).bayar(tagihan);
    if (!mounted) return;
    if (error == null) {
      _selesai(
        context,
        'Pembayaran ${labelPeriode(tagihan.periode)} terkirim.',
      );
      return;
    }
    setState(() {
      _sibuk = false;
      _error = error;
    });
  }
}

/// Menu 8 (role B).
class RiwayatBayarPage extends ConsumerWidget {
  const RiwayatBayarPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lunas = ref.watch(iuranProvider).lunas;
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat bayar')),
      body: SehatScroll(
        children: [
          if (lunas.isEmpty) const Catatan('Belum ada pembayaran mandiri.'),
          for (final t in lunas) ...[
            _KartuTagihan(t),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

/// Menu 9 (role B). Peserta mandiri memilih kelas sendiri.
class UbahKelasPage extends ConsumerStatefulWidget {
  const UbahKelasPage({super.key});

  @override
  ConsumerState<UbahKelasPage> createState() => _UbahKelasPageState();
}

class _UbahKelasPageState extends ConsumerState<UbahKelasPage> {
  KelasRawat? _tujuan;
  bool _sibuk = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final peserta = ref.watch(sesiProvider).value?.peserta;
    if (peserta == null) return const SizedBox.shrink();
    final tujuan = _tujuan ?? peserta.kelas;
    return Scaffold(
      appBar: AppBar(title: const Text('Ubah kelas rawat')),
      body: SehatScroll(
        children: [
          const PitaAntrean(),
          Catatan('Kelas sekarang: ${peserta.kelas.label}'),
          const SizedBox(height: 12),
          SegmentedButton<KelasRawat>(
            segments: [
              for (final k in KelasRawat.values)
                ButtonSegment(value: k, label: Text(k.label)),
            ],
            selected: {tujuan},
            onSelectionChanged: (v) => setState(() => _tujuan = v.first),
          ),
          const SizedBox(height: 12),
          Lembaran(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: BarisNilai(
              'Iuran per bulan',
              rupiah(tarifMandiri(tujuan)),
              tebal: true,
            ),
          ),
          const SizedBox(height: 10),
          const Catatan(
            'Tarif contoh. Kelas baru berlaku untuk tagihan bulan berikutnya. '
            'Tagihan yang belum lunas harus dibayar dulu.',
          ),
          if (_error != null) PesanError(_error!),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _sibuk ? null : () => _kirim(tujuan),
            child: Text(_sibuk ? 'Mengirim...' : 'Simpan kelas'),
          ),
        ],
      ),
    );
  }

  Future<void> _kirim(KelasRawat tujuan) async {
    setState(() {
      _sibuk = true;
      _error = null;
    });
    final error = await ref.read(iuranProvider.notifier).ubahKelas(tujuan);
    if (!mounted) return;
    if (error == null) {
      _selesai(context, 'Permintaan ubah ke ${tujuan.label} terkirim.');
      return;
    }
    setState(() {
      _sibuk = false;
      _error = error;
    });
  }
}

void _selesai(BuildContext context, String pesan) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(pesan)));
  if (context.canPop()) {
    context.pop();
  } else {
    context.go('/beranda');
  }
}

class _KartuTagihan extends StatelessWidget {
  const _KartuTagihan(this.tagihan, {this.aksi});

  final TagihanIuran tagihan;
  final Widget? aksi;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tagihan.status) {
      StatusTagihan.belumBayar => (
        const Color(0xFFF8E8E6),
        const Color(0xFF9B2C2C),
      ),
      StatusTagihan.menunggu => (
        const Color(0xFFFFF6E8),
        const Color(0xFF8A5A12),
      ),
      StatusTagihan.lunas => (const Color(0xFFE5F2EC), SehatWarna.ink),
    };
    return Lembaran(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  labelPeriode(tagihan.periode),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  tagihan.status.label,
                  style: TextStyle(
                    color: fg,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Uang(rupiah(tagihan.nominal), size: 20),
          const SizedBox(height: 4),
          Catatan(
            tagihan.dibayar == null
                ? tagihan.kelas.label
                : '${tagihan.kelas.label} · dibayar ${tanggalPendek(tagihan.dibayar!)}',
          ),
          if (aksi != null) ...[const SizedBox(height: 12), aksi!],
        ],
      ),
    );
  }
}
