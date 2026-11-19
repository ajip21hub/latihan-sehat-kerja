import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../ui/sehat_widgets.dart';
import '../../peserta/presentation/sesi_controller.dart';
import '../domain/pengajuan_dana.dart';
import 'dana_controller.dart';

class AjuDanaPage extends ConsumerStatefulWidget {
  const AjuDanaPage({super.key});

  @override
  ConsumerState<AjuDanaPage> createState() => _AjuDanaPageState();
}

class _AjuDanaPageState extends ConsumerState<AjuDanaPage> {
  final _alasan = TextEditingController();
  late JenisAmbil _jenis;
  String? _error;
  bool _sibuk = false;

  @override
  void initState() {
    super.initState();
    final bekerja = ref.read(sesiProvider).value?.peserta.masihBekerja ?? true;
    _jenis = bekerja ? JenisAmbil.sebagian10 : JenisAmbil.seluruhnya;
  }

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
            '10% untuk peserta yang masih bekerja dengan kepesertaan minimal 10 tahun. '
            'Seluruh saldo setelah berhenti bekerja. Di layanan resmi, alasan dan '
            'dokumennya jauh lebih ketat (usia 56, berhenti, PHK, dan seterusnya).',
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
