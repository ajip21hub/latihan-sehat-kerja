/// Konfigurasi yang ditanam saat compile lewat
/// `--dart-define-from-file=config/dev.json`.
///
/// Semua nilai di sini bisa diekstrak dari binary. Jangan taruh secret
/// server (password, API secret, kunci pembayaran) di file config.
abstract final class Env {
  static const flavor = String.fromEnvironment('FLAVOR', defaultValue: 'dev');

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8787',
  );

  /// Sidik jari SHA-256 sertifikat, dipisah koma. Kosong = pinning mati.
  /// Backend latihan memakai HTTP, jadi pin dibiarkan kosong.
  static const certSha256Pins = String.fromEnvironment('CERT_SHA256_PINS');

  static bool get isDev => flavor == 'dev';
  static bool get pinningEnabled => certSha256Pins.trim().isNotEmpty;
}
