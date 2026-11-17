import 'package:flutter/material.dart';

import '../../../ui/sehat_theme.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'SK',
              style: TextStyle(
                color: SehatWarna.ink,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 16),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(height: 12),
            Text('Memeriksa sesi...'),
          ],
        ),
      ),
    );
  }
}
