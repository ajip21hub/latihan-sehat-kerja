import 'peserta.dart';

/// Status login yang dibaca router dan halaman Profil.
///
/// `fromCache` berarti snapshot gagal karena jaringan, lalu data terakhir
/// di storage yang dipakai. Token tidak dihapus.
class AuthSession {
  const AuthSession({required this.peserta, this.fromCache = false});

  final Peserta peserta;
  final bool fromCache;
}
