import 'package:flutter/material.dart';

import '../features/layanan/domain/pengajuan_layanan.dart';
import '../features/peserta/domain/peserta.dart';
import 'sehat_theme.dart';

class Lembaran extends StatelessWidget {
  const Lembaran({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SehatWarna.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SehatWarna.line),
      ),
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16),
        child: child,
      ),
    );
  }
}

class SehatScroll extends StatelessWidget {
  const SehatScroll({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 640),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: children,
        ),
      ),
    );
  }
}

class Uang extends StatelessWidget {
  const Uang(this.teks, {super.key, this.size = 32});

  final String teks;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      teks,
      style: TextStyle(
        fontSize: size,
        height: 1.1,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.6,
        color: SehatWarna.ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

class BarisNilai extends StatelessWidget {
  const BarisNilai(this.label, this.nilai, {super.key, this.tebal = false});

  final String label;
  final String nilai;
  final bool tebal;

  @override
  Widget build(BuildContext context) {
    final gaya = TextStyle(
      fontWeight: tebal ? FontWeight.w600 : FontWeight.w400,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: SehatWarna.inkSoft),
            ),
          ),
          Text(nilai, style: gaya),
        ],
      ),
    );
  }
}

class Catatan extends StatelessWidget {
  const Catatan(this.teks, {super.key});

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Text(
      teks,
      style: const TextStyle(color: SehatWarna.inkSoft, height: 1.4),
    );
  }
}

class PitaLuring extends StatelessWidget {
  const PitaLuring(this.pesan, {super.key});

  final String pesan;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4C98A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.cloud_off, size: 18, color: Color(0xFF8A5A12)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sesi dari data tersimpan',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  pesan,
                  style: const TextStyle(
                    color: SehatWarna.inkSoft,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PesanError extends StatelessWidget {
  const PesanError(this.teks, {super.key});

  final String teks;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        teks,
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          height: 1.35,
        ),
      ),
    );
  }
}

class KartuPeserta extends StatelessWidget {
  const KartuPeserta({super.key, required this.peserta});

  final Peserta peserta;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: SehatWarna.ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Kartu peserta latihan',
                style: TextStyle(color: Color(0xFFD5E4DF), fontSize: 13),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E564E),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  peserta.aktif ? 'Aktif' : 'Tidak aktif',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            peserta.nama,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            peserta.nomor,
            style: const TextStyle(
              color: Color(0xFFD5E4DF),
              fontSize: 16,
              letterSpacing: 1.4,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0xFF2E564E)),
          const SizedBox(height: 12),
          Text(
            peserta.kelas.label,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 2),
          Text(
            peserta.faskes,
            style: const TextStyle(color: Color(0xFFD5E4DF), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class StatusChip extends StatelessWidget {
  const StatusChip(this.status, {super.key});

  final StatusPengajuan status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      StatusPengajuan.diajukan => (
        const Color(0xFFFFF6E8),
        const Color(0xFF8A5A12),
      ),
      StatusPengajuan.diproses => (
        const Color(0xFFE8F1FA),
        const Color(0xFF1D4E89),
      ),
      StatusPengajuan.disetujui => (
        const Color(0xFFE5F2EC),
        const Color(0xFF1B3A34),
      ),
      StatusPengajuan.ditolak => (
        const Color(0xFFF8E8E6),
        const Color(0xFF9B2C2C),
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

String tanggalPendek(DateTime tanggal) {
  final lokal = tanggal.toLocal();
  final d = lokal.day.toString().padLeft(2, '0');
  final m = lokal.month.toString().padLeft(2, '0');
  return '$d/$m/${lokal.year}';
}
