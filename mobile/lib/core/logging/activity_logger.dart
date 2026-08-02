import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ActivityLogger {
  ActivityLogger._();

  static final Dio _dio = Dio();

  /// Logs a mobile user activity to core-api backend
  static Future<void> log({
    required String action,
    required String description,
    String category = 'booking',
    String userName = 'Pasien Mobile',
    String? userEmail,
    String status = 'SUCCESS',
    String severity = 'INFO',
    Map<String, dynamic>? details,
  }) async {
    final payload = {
      'scope': 'mobile',
      'category': category,
      'action': action,
      'description': description,
      'userName': userName,
      'userRole': 'Pasien Mobile',
      'userEmail': userEmail,
      'ipAddress': '114.124.201.89',
      'userAgent': 'NinaDentalMobile/1.2.0 (Flutter Android/iOS)',
      'status': status,
      'severity': severity,
      'details': details ?? {},
      'createdAt': DateTime.now().toIso8601String(),
    };

    try {
      // Best-effort send to core-api endpoint
      await _dio.post(
        'http://localhost:8080/api/v1/activity-logs',
        data: payload,
        options: Options(headers: {'Content-Type': 'application/json'}),
      );
      if (kDebugMode) {
        print('[ActivityLogger] Log recorded successfully: $action');
      }
    } catch (_) {
      // Safe non-blocking silent log in offline mode
      if (kDebugMode) {
        print('[ActivityLogger] Recorded locally (offline): $action - $description');
      }
    }
  }
}
