import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'payment_model.dart';

class PaymentRepository {
  PaymentRepository(this._dio);

  final Dio _dio;

  /// Scoped to the caller's own `patientId` for the same reason as
  /// `ReservationRepository.listMyReservations` — see that comment.
  Future<List<Payment>> listMyPayments(String patientId) async {
    final res = await _dio.get<List<dynamic>>('/payments', queryParameters: {'patientId': patientId});
    return (res.data ?? []).map((e) => Payment.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(ref.watch(dioProvider));
});

final myPaymentsProvider = FutureProvider.autoDispose.family<List<Payment>, String>((ref, patientId) {
  return ref.watch(paymentRepositoryProvider).listMyPayments(patientId);
});
