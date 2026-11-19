import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../ui/sehat_theme.dart';
import '../../../ui/sehat_widgets.dart';
import 'sesi_controller.dart';

class LoginPage extends ConsumerStatefulWidget {
  const LoginPage({super.key});

  @override
  ConsumerState<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends ConsumerState<LoginPage> {
  final _nomor = TextEditingController();
  final _sandi = TextEditingController();
  String? _error;
  bool _sibuk = false;

  @override
  void dispose() {
    _nomor.dispose();
    _sandi.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 36,
                    height: 36,
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
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Latihan SehatKerja',
                    style: Theme.of(context).textTheme.headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w600, height: 1.1),
                  ),
                  const SizedBox(height: 8),
                  const Catatan(
                    'Bukan aplikasi BPJS. Data peserta, kelas rawat, '
                    'pengajuan layanan, dan saldo JHT di sini hanya contoh belajar.',
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _nomor,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Nomor peserta',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _sandi,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Sandi'),
                    onSubmitted: (_) => _masuk(),
                  ),
                  if (_error != null) PesanError(_error!),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _sibuk ? null : _masuk,
                    child: Text(_sibuk ? 'Memeriksa...' : 'Masuk'),
                  ),
                  const SizedBox(height: 16),
                  const Catatan(
                    'Sandi semua akun: belajar.\n'
                    '0001 dibayar perusahaan, 0002 mandiri, '
                    '0003 dulu perusahaan lalu mandiri.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _masuk() async {
    setState(() {
      _sibuk = true;
      _error = null;
    });
    final error = await ref
        .read(sesiProvider.notifier)
        .masuk(_nomor.text, _sandi.text);
    if (!mounted) return;
    setState(() {
      _sibuk = false;
      _error = error;
    });
  }
}
