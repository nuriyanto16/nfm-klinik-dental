import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'treatment_model.dart';

final List<Treatment> _fallbackTreatments = [
  const Treatment(
    id: '41000000-0000-0000-0000-000000000001',
    name: 'Scaling 6-in-1 Super Clean',
    categoryName: 'Pencegahan',
    price: 199000.0,
    durationMinutes: 30,
    isActive: true,
  ),
  const Treatment(
    id: '41000000-0000-0000-0000-000000000002',
    name: 'Fluoridasi Gigi Anak & Dewasa',
    categoryName: 'Pencegahan',
    price: 150000.0,
    durationMinutes: 20,
    isActive: true,
  ),
  const Treatment(
    id: '41000000-0000-0000-0000-000000000003',
    name: 'Penambalan Gigi Komposit Estetis',
    categoryName: 'Restorasi',
    price: 350000.0,
    durationMinutes: 45,
    isActive: true,
  ),
  const Treatment(
    id: '41000000-0000-0000-0000-000000000004',
    name: 'Pemasangan Behel Metal Premium',
    categoryName: 'Ortodonti',
    price: 4500000.0,
    durationMinutes: 60,
    isActive: true,
  ),
  const Treatment(
    id: '41000000-0000-0000-0000-000000000005',
    name: 'Bleaching Instant Whitening 60 Menit',
    categoryName: 'Estetika',
    price: 1850000.0,
    durationMinutes: 60,
    isActive: true,
  ),
];

class TreatmentRepository {
  TreatmentRepository(this._dio);

  final Dio _dio;

  Future<List<Treatment>> listTreatments() async {
    try {
      final res = await _dio.get<List<dynamic>>('/treatments');
      final list = (res.data ?? []).map((e) => Treatment.fromJson(e as Map<String, dynamic>)).toList();
      return list.isNotEmpty ? list : _fallbackTreatments;
    } catch (_) {
      return _fallbackTreatments;
    }
  }
}

final treatmentRepositoryProvider = Provider<TreatmentRepository>((ref) {
  return TreatmentRepository(ref.watch(dioProvider));
});

final treatmentListProvider = FutureProvider.autoDispose<List<Treatment>>((ref) {
  return ref.watch(treatmentRepositoryProvider).listTreatments();
});
