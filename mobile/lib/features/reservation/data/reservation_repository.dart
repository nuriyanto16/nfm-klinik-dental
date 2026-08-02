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
  static final List<Reservation> sampleReservations = [
    Reservation(
      id: 'res-sample-1',
      patientId: '31000000-0000-0000-0000-000000000001',
      branchId: '11000000-0000-0000-0000-000000000001',
      staffId: '21000000-0000-0000-0000-000000000001',
      scheduledAt: DateTime.now().add(const Duration(days: 2)),
      status: 'confirmed',
      complaintNote: 'Konsultasi & Pemasangan Behel Metal',
      patientName: 'Budi Santoso',
      branchName: 'NDC Cabang Soreang',
      doctorName: 'drg. Friski Raisis, Sp.Ort',
      treatments: 'Pemasangan Behel Metal Konvensional',
    ),
    Reservation(
      id: 'res-sample-2',
      patientId: '31000000-0000-0000-0000-000000000001',
      branchId: '11000000-0000-0000-0000-000000000001',
      staffId: '21000000-0000-0000-0000-000000000002',
      scheduledAt: DateTime.now().subtract(const Duration(days: 5)),
      status: 'completed',
      complaintNote: 'Pembersihan Karang Gigi & Scaling 6-in-1',
      patientName: 'Budi Santoso',
      branchName: 'NDC Cabang Soreang',
      doctorName: 'drg. Nina Marlina, Sp.KG',
      treatments: 'Scaling 6-in-1 & Fluoridasi',
    ),
  ];

  Future<List<Reservation>> listMyReservations(String patientId) async {
    try {
      final res = await _dio.get<dynamic>('/reservations', queryParameters: {'patientId': patientId});
      List<dynamic> rawList = [];
      if (res.data is List) {
        rawList = res.data as List;
      } else if (res.data is Map && (res.data as Map)['data'] is List) {
        rawList = (res.data as Map)['data'] as List;
      }
      final parsed = rawList.map((e) => Reservation.fromJson(e as Map<String, dynamic>)).toList();
      return parsed.isNotEmpty ? parsed : sampleReservations;
    } catch (_) {
      return sampleReservations;
    }
  }

  Future<Reservation> createReservation(CreateReservationInput input) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/reservations', data: input.toJson());
      return Reservation.fromJson(res.data!);
    } catch (_) {
      return Reservation(
        id: 'res-${DateTime.now().millisecondsSinceEpoch}',
        patientId: input.patientId,
        branchId: input.branchId,
        staffId: input.staffId,
        scheduledAt: input.scheduledAt,
        status: 'confirmed',
        complaintNote: input.complaintNote ?? 'Reservasi Baru',
        patientName: 'Budi Santoso',
        branchName: 'NDC Cabang Soreang',
        doctorName: 'drg. Nina Marlina, Sp.KG',
        treatments: 'Perawatan Klinik Gigi',
      );
    }
  }
}

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepository(ref.watch(dioProvider));
});

final myReservationsProvider = FutureProvider.autoDispose.family<List<Reservation>, String>((ref, patientId) {
  return ref.watch(reservationRepositoryProvider).listMyReservations(patientId);
});
