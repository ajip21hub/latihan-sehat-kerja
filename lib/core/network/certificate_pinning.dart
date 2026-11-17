import 'package:crypto/crypto.dart';

/// Sidik jari dan daftar pin. Adapter HTTP ada di berkas io/stub,
/// karena web tidak bisa mengimpor `dart:io`.
///
/// Selalu siapkan minimal dua pin (aktif + cadangan). Sertifikat
/// dirotasi berkala; pin tunggal membuat app lama putus total.
/// Backend latihan memakai HTTP, jadi daftar pin dikosongkan.
Set<String> parsePins(String raw) => raw
    .split(',')
    .map((p) => p.trim().toLowerCase().replaceAll(':', ''))
    .where((p) => p.isNotEmpty)
    .toSet();

String sha256Fingerprint(List<int> der) => sha256.convert(der).toString();
