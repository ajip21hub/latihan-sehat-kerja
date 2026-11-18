import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../ui/sehat_theme.dart';
import '../domain/onboarding_item.dart';
import 'onboarding_controller.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key, this.isViewOnly = false});

  final bool isViewOnly;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _halamanSekarang = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _lanjut() {
    if (_halamanSekarang < daftarOnboarding.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _selesai();
    }
  }

  Future<void> _selesai() async {
    if (widget.isViewOnly) {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go('/beranda');
      }
      return;
    }
    await ref.read(onboardingProvider.notifier).selesaikan();
  }

  @override
  Widget build(BuildContext context) {
    final total = daftarOnboarding.length;
    final adalahHalamanTerakhir = _halamanSekarang == total - 1;

    return Scaffold(
      backgroundColor: SehatWarna.paper,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: SehatWarna.ink,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'SK',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'SehatKerja',
                            style: TextStyle(
                              color: SehatWarna.ink,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      if (widget.isViewOnly)
                        IconButton(
                          icon: const Icon(Icons.close, color: SehatWarna.ink),
                          tooltip: 'Tutup',
                          onPressed: _selesai,
                        )
                      else if (!adalahHalamanTerakhir)
                        TextButton(
                          onPressed: _selesai,
                          style: TextButton.styleFrom(
                            foregroundColor: SehatWarna.inkSoft,
                          ),
                          child: const Text('Lewati'),
                        )
                      else
                        const SizedBox(width: 48),
                    ],
                  ),

                  // Carousel
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      itemCount: total,
                      onPageChanged: (index) {
                        setState(() => _halamanSekarang = index);
                      },
                      itemBuilder: (context, index) {
                        final item = daftarOnboarding[index];
                        return _SlideContent(item: item);
                      },
                    ),
                  ),

                  // Indikator halaman
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(total, (index) {
                      final aktif = index == _halamanSekarang;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: aktif ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: aktif ? SehatWarna.ink : SehatWarna.line,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Tombol aksi bawah
                  if (adalahHalamanTerakhir)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _selesai,
                        child: Text(
                          widget.isViewOnly ? 'Tutup Panduan' : 'Mulai Sekarang',
                        ),
                      ),
                    )
                  else
                    Row(
                      children: [
                        if (!widget.isViewOnly) ...[
                          Expanded(
                            child: OutlinedButton(
                              onPressed: _selesai,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: SehatWarna.line),
                                foregroundColor: SehatWarna.inkSoft,
                              ),
                              child: const Text('Lewati'),
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Expanded(
                          flex: widget.isViewOnly ? 1 : 2,
                          child: FilledButton(
                            onPressed: _lanjut,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Lanjut'),
                                SizedBox(width: 6),
                                Icon(Icons.arrow_forward, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SlideContent extends StatelessWidget {
  const _SlideContent({required this.item});

  final OnboardingItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 104,
            height: 104,
            decoration: BoxDecoration(
              color: const Color(0xFFE5F2EC),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD5E4DF), width: 2),
            ),
            child: Icon(item.icon, size: 48, color: SehatWarna.ink),
          ),
          const SizedBox(height: 28),
          if (item.badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFE5F2EC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                item.badge!,
                style: const TextStyle(
                  color: SehatWarna.ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          Text(
            item.judul,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: SehatWarna.ink,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            item.deskripsi,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: SehatWarna.inkSoft,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
