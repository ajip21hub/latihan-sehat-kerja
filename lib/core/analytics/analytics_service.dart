import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service untuk melacak event dan funnel analisis aplikasi ke Firebase Analytics.
class AnalyticsService {
  AnalyticsService({this._analytics});

  final FirebaseAnalytics? _analytics;

  /// Helper untuk kirim event ke Firebase Analytics dengan fallback debug console.
  Future<void> logEvent(String name, [Map<String, Object>? parameters]) async {
    final eventParams = <String, Object>{
      if (kDebugMode) 'debug_mode': 1,
      ...?parameters,
    };
    debugPrint('[Analytics] Log Event: $name, Parameters: $eventParams');
    try {
      await _analytics?.logEvent(name: name, parameters: eventParams);
    } catch (e) {
      debugPrint(
        '[Analytics] Warning: Gagal kirim event $name ke Firebase: $e',
      );
    }
  }

  /// 1. Berapa banyak user klik tombol "Ajukan layanan kesehatan" di Beranda
  Future<void> logKlikAjukanLayanan() async {
    await logEvent('klik_ajukan_layanan_kesehatan', {
      'lokasi': 'beranda',
      'waktu': DateTime.now().toIso8601String(),
    });
  }

  /// 2. Berapa user yang sudah mengisi formulir pengajuan layanan
  Future<void> logFormLayananTerisi({
    required String jenisLayanan,
    required int faskesLength,
    required int keluhanLength,
  }) async {
    await logEvent('isi_form_layanan_kesehatan', {
      'jenis_layanan': jenisLayanan,
      'faskes_length': faskesLength,
      'keluhan_length': keluhanLength,
    });
  }

  /// 3. Berapa user yang klik tombol "Kirim pengajuan"
  Future<void> logKlikKirimPengajuan({
    required String jenisLayanan,
    required bool isValid,
  }) async {
    await logEvent('klik_kirim_pengajuan_layanan', {
      'jenis_layanan': jenisLayanan,
      'is_valid': isValid,
    });
  }

  /// Event pelengkap: pengajuan berhasil dikirim (final conversion)
  Future<void> logKirimPengajuanSukses({required String jenisLayanan}) async {
    await logEvent('kirim_pengajuan_layanan_sukses', {
      'jenis_layanan': jenisLayanan,
    });
  }
}

/// Provider Riverpod untuk AnalyticsService
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  FirebaseAnalytics? analytics;
  try {
    analytics = FirebaseAnalytics.instance;
  } catch (_) {
    // Firebase belum diinisialisasi atau berjalan di environment test/offline
  }
  return AnalyticsService(analytics: analytics);
});

/// Observer untuk melacak perpindahan halaman (screen views) di GoRouter
final analyticsObserverProvider = Provider<FirebaseAnalyticsObserver?>((ref) {
  try {
    return FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance);
  } catch (_) {
    return null;
  }
});
