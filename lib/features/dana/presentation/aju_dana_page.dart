import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../ui/sehat_widgets.dart';
import '../domain/pengajuan_dana.dart';
import 'dana_controller.dart';

class AjuDanaPage extends ConsumerStatefulWidget {
  const AjuDanaPage({super.key});

  @override
  ConsumerState<AjuDanaPage> createState() => _AjuDanaPageState();
}

class _AjuDanaPageState extends ConsumerState<AjuDanaPage> {
  final _alasan = TextEditingController();
  JenisAmbil _jenis = JenisAmbil.sebagian10;
  String? _error;
  bool _sibuk = false;

  @override
  void dispose() {
    _alasan.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ambil dana')),
      body: SehatScroll(
        children: [
          const Catatan(
            'Aturan latihan, disederhanakan dari ketentuan yang beredar di kanal publik: '
            '10% hanya bila kepesertaan sudah 10 tahun. Pengambilan seluruh saldo di sini '
            'cukup dengan alasan. Di layanan resmi, alasan dan dokumennya jauh lebih ketat '
            '(usia 56, berhenti, PHK, dan seterusnya).',
          ),
          const SizedBox(height: 16),
          SegmentedButton<JenisAmbil>(
            segments: const [
              ButtonSegment(value: JenisAmbil.sebagian10, label: Text('10%')),
              ButtonSegment(
                value: JenisAmbil.seluruhnya,
                label: Text('Seluruhnya'),
              ),
            ],
            selected: {_jenis},
            onSelectionChanged: (value) => setState(() => _jenis = value.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _alasan,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(labelText: 'Alasan'),
          ),
          if (_error != null) PesanError(_error!),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _sibuk ? null : _kirim,
            child: Text(_sibuk ? 'Mengirim...' : 'Kirim'),
          ),
        ],
      ),
    );
  }

  Future<void> _kirim() async {
    setState(() {
      _sibuk = true;
      _error = null;
    });
    final error = await ref
        .read(danaProvider.notifier)
        .ajukan(jenis: _jenis, alasan: _alasan.text);
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
