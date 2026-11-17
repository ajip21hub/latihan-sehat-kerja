import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  @override
  void dispose() {
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
    if (_faskes.text.trim().isEmpty || _keluhan.text.trim().length < 5) {
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
      context.pop();
      return;
    }
    setState(() {
      _sibuk = false;
      _error = error;
    });
  }
}
