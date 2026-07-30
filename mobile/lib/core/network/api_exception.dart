import 'package:dio/dio.dart';

/// Extracts a human-readable message from a failed API call, mirroring
/// `admin/app/composables/useApiMutate.ts`'s `apiErrorMessage` so both apps
/// surface backend validation errors (fiber.NewError bodies: `{"message": "..."}`)
/// the same way instead of a raw stack trace.
String apiErrorMessage(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['message'] is String) {
      return data['message'] as String;
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Koneksi ke server timeout. Periksa jaringan Anda.';
      case DioExceptionType.connectionError:
        return 'Tidak bisa terhubung ke server. Periksa jaringan Anda.';
      default:
        return error.message ?? 'Terjadi kesalahan tak terduga.';
    }
  }
  return error.toString();
}
