/// Menghapus token dan sandi dari baris log Dio.
///
/// Log debug bisa bocor lewat `adb logcat`, rekaman layar, atau
/// paste ke chat. Header `Authorization` tidak boleh utuh.
String redactSecrets(String raw) {
  final hiddenBearer = raw.replaceAll(RegExp(r'Bearer\s+\S+'), 'Bearer ***');
  return hiddenBearer.replaceAllMapped(
    RegExp(r'"(password|sandi|refreshToken|accessToken)"\s*:\s*"[^"]*"'),
    (match) => '"${match[1]}":"***"',
  );
}
