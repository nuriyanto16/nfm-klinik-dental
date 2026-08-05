import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Base URL for `core-api`. Override at build/run time with
/// `--dart-define=API_BASE_URL=https://api.ninadentalcare.com/api/v1`.
const _defaultApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://43.133.150.102:8092/api/v1',
);

final dioProvider = Provider<Dio>((ref) {
  return Dio(
    BaseOptions(
      baseUrl: _defaultApiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  );
});

Future<void> postActivityLog(
  Dio dio, {
  required String category,
  required String action,
  required String description,
  required String userName,
  String? userEmail,
  Map<String, dynamic>? details,
}) async {
  try {
    await dio.post('/activity-logs', data: {
      'scope': 'mobile',
      'category': category,
      'action': action,
      'description': description,
      'userName': userName,
      'userRole': 'Pasien Mobile',
      'userEmail': userEmail,
      'status': 'SUCCESS',
      'severity': 'INFO',
      'details': details,
    });
  } catch (_) {
    // silent fail
  }
}
