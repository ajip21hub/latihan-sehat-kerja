import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

import 'certificate_pinning.dart';

bool isPinned(X509Certificate? cert, Set<String> pins) =>
    cert != null && pins.contains(sha256Fingerprint(cert.der));

/// `null` = adapter bawaan (pinning nonaktif, enak untuk debug proxy).
HttpClientAdapter? pinnedHttpClientAdapter(Set<String> pins) {
  if (pins.isEmpty) return null;
  return IOHttpClientAdapter(
    validateCertificate: (cert, host, port) => isPinned(cert, pins),
  );
}
