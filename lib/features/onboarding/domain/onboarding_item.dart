import 'package:flutter/material.dart';

class OnboardingItem {
  const OnboardingItem({
    required this.judul,
    required this.deskripsi,
    required this.icon,
    this.badge,
  });

  final String judul;
  final String deskripsi;
  final IconData icon;
  final String? badge;
}

const daftarOnboarding = [
  OnboardingItem(
    judul: 'Layanan Kesehatan Terpadu',
    deskripsi:
        'Akses informasi faskes tingkat pertama, golongan kelas rawat, dan '
        'kemudahan pengajuan rawat jalan maupun rawat inap dalam satu aplikasi.',
    icon: Icons.health_and_safety_outlined,
    badge: 'Kesehatan',
  ),
  OnboardingItem(
    judul: 'Pantau Saldo Jaminan Hari Tua',
    deskripsi:
        'Transparansi rincian tabungan JHT (iuran peserta, pemberi kerja, '
        'dan pengembangan) serta simulasi pengajuan pencairan dana yang jelas.',
    icon: Icons.savings_outlined,
    badge: 'Ketenagakerjaan',
  ),
  OnboardingItem(
    judul: 'Akses Mandiri & Siaga Offline',
    deskripsi:
        'Tetap bisa membaca artikel edukasi dan membuat pengajuan meski tanpa sinyal. '
        'Antrean transaksi otomatis disinkronkan saat kembali terhubung.',
    icon: Icons.offline_pin_outlined,
    badge: 'Offline-First',
  ),
];
