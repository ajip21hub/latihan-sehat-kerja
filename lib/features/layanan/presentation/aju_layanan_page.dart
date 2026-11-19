import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/analytics/analytics_service.dart';
import '../../../ui/sehat_widgets.dart';
import '../domain/pengajuan_layanan.dart';
import 'layanan_controller.dart';

class AjuLayananPage extends ConsumerStatefulWidget {
  const AjuLayananPage({super.key});

  @override
  ConsumerState<AjuLayananPage> createState() => _AjuLayananPageState();
}

class _AjuLayananPageState extends ConsumerState<AjuLayananPage> {
  final _faskes = TextEditingController();
  final _keluhan = TextEditingController();
  JenisLayanan _jenis = JenisLayanan.rawatJalan;
  String? _error;
  bool _sibuk = false;
  bool _formFilledTracked = false;

  @override
  void initState() {
    super.initState();
    _faskes.addListener(_cekFormTerisi);
    _keluhan.addListener(_cekFormTerisi);
  }

  void _cekFormTerisi() {
    if (_formFilledTracked) return;
    final faskes = _faskes.text.trim();
    final keluhan = _keluhan.text.trim();
    if (faskes.isNotEmpty && keluhan.length >= 5) {
      _formFilledTracked = true;
      ref.read(analyticsServiceProvider).logFormLayananTerisi(
            jenisLayanan: _jenis.name,
            faskesLength: faskes.length,
            keluhanLength: keluhan.length,
          );
    }
  }

  @override
  void dispose() {
    _faskes.removeListener(_cekFormTerisi);
    _keluhan.removeListener(_cekFormTerisi);
    _faskes.dispose();
    _keluhan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengajuan layanan')),
      body: SehatScroll(
        children: [
          const Catatan(
            'Di aplikasi resmi, pengajuan ini biasanya lewat faskes. '
            'Di latihan ini kamu mencatat sendiri supaya alur statusnya kelihatan.',
          ),
          const SizedBox(height: 16),
          SegmentedButton<JenisLayanan>(
            segments: const [
              ButtonSegment(
                value: JenisLayanan.rawatJalan,
                label: Text('Rawat jalan'),
              ),
              ButtonSegment(
                value: JenisLayanan.rawatInap,
                label: Text('Rawat inap'),
              ),
            ],
            selected: {_jenis},
            onSelectionChanged: (value) => setState(() => _jenis = value.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _faskes,
            decoration: const InputDecoration(labelText: 'Faskes'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _keluhan,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Keluhan'),
          ),
          if (_error != null) PesanError(_error!),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _sibuk ? null : _kirim,
            child: Text(_sibuk ? 'Mengirim...' : 'Kirim pengajuan'),
          ),
        ],
      ),
    );
  }

  Future<void> _kirim() async {
    final isValid =
        _faskes.text.trim().isNotEmpty && _keluhan.text.trim().length >= 5;

    // 3. Tracking klik tombol kirim pengajuan
    ref.read(analyticsServiceProvider).logKlikKirimPengajuan(
          jenisLayanan: _jenis.name,
          isValid: isValid,
        );

    if (!isValid) {
      setState(() => _error = 'Isi faskes dan keluhan, minimal 5 huruf.');
      return;
    }
    setState(() {
      _sibuk = true;
      _error = null;
    });
    final error = await ref
        .read(layananProvider.notifier)
        .ajukan(jenis: _jenis, faskes: _faskes.text, keluhan: _keluhan.text);
    if (!mounted) return;
    if (error == null) {
      ref.read(analyticsServiceProvider).logKirimPengajuanSukses(
            jenisLayanan: _jenis.name,
          );
      context.pop();
      return;
    }
    setState(() {
      _sibuk = false;
      _error = error;
    });
  }
}
