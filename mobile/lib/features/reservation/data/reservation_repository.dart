import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'reservation_model.dart';

class CreateReservationInput {
  const CreateReservationInput({
    required this.patientId,
    required this.branchId,
    required this.staffId,
    required this.scheduledAt,
    this.complaintNote,
    required this.treatmentIds,
  });

  final String patientId;
  final String branchId;
  final String staffId;
  final DateTime scheduledAt;
  final String? complaintNote;
  final List<String> treatmentIds;

  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'branchId': branchId,
        'staffId': staffId,
        'scheduledAt': scheduledAt.toUtc().toIso8601String(),
        'complaintNote': complaintNote,
        'treatmentIds': treatmentIds,
      };
}

class ReservationRepository {
  ReservationRepository(this._dio);

  final Dio _dio;

  /// Always scoped to the caller's own `patientId` — the mobile app never
  /// fetches the unfiltered list (that would leak every other patient's
  /// reservations to a public, unauthenticated client).
  Future<List<Reservation>> listMyReservations(String patientId) async {
    final res = await _dio.get<List<dynamic>>('/reservations', queryParameters: {'patientId': patientId});
    return (res.data ?? []).map((e) => Reservation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Reservation> createReservation(CreateReservationInput input) async {
    final res = await _dio.post<Map<String, dynamic>>('/reservations', data: input.toJson());
    return Reservation.fromJson(res.data!);
  }
}

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepository(ref.watch(dioProvider));
});

final myReservationsProvider = FutureProvider.autoDispose.family<List<Reservation>, String>((ref, patientId) {
  return ref.watch(reservationRepositoryProvider).listMyReservations(patientId);
});
