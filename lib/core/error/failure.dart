import 'package:dio/dio.dart';

/// Error domain. `sealed` memaksa UI menangani setiap kasus.
sealed class Failure implements Exception {
  const Failure(this.message);
  final String message;

  @override
  String toString() => message;
}

final class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Tidak ada koneksi internet']);
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Sesi berakhir, silakan masuk lagi',
  ]);
}

final class ServerFailure extends Failure {
  const ServerFailure(super.message, {this.statusCode});
  final int? statusCode;
}

final class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'Terjadi kesalahan tak terduga']);
}

/// Mengubah [DioException] menjadi [Failure] yang ramah UI.
Failure mapDioError(Object error) {
  if (error is Failure) return error;
  if (error is! DioException) return const UnknownFailure();
  return switch (error.type) {
    DioExceptionType.connectionError ||
    DioExceptionType.connectionTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.sendTimeout => const NetworkFailure(),
    DioExceptionType.cancel => const UnknownFailure('Permintaan dibatalkan'),
    DioExceptionType.badResponse when error.response?.statusCode == 401 =>
      const UnauthorizedFailure(),
    DioExceptionType.badResponse => ServerFailure(
      _serverMessage(error) ?? 'Server error',
      statusCode: error.response?.statusCode,
    ),
    _ => const UnknownFailure(),
  };
}

String? _serverMessage(DioException error) {
  final data = error.response?.data;
  if (data is Map && data['message'] != null) return data['message'].toString();
  return null;
}
