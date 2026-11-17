import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sehat_kerja/app.dart';
import 'package:sehat_kerja/core/storage/token_storage.dart';

void main() {
  testWidgets('belum masuk menampilkan halaman latihan', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tokenStorageProvider.overrideWithValue(
            TokenStorage(MemoryKeyValueStore()),
          ),
        ],
        child: const SehatKerjaApp(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Latihan SehatKerja'), findsOneWidget);
    expect(find.text('Masuk'), findsOneWidget);
  });
}
