import 'package:dio/dio.dart';

/// Web tidak punya `dart:io`, jadi pinning tidak dipasang.
/// Chrome tetap memakai trust store bawaan browser.
HttpClientAdapter? pinnedHttpClientAdapter(Set<String> pins) => null;
