import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'treatment_model.dart';

class TreatmentRepository {
  TreatmentRepository(this._dio);

  final Dio _dio;

  Future<List<Treatment>> listTreatments() async {
    final res = await _dio.get<List<dynamic>>('/treatments');
    return (res.data ?? []).map((e) => Treatment.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final treatmentRepositoryProvider = Provider<TreatmentRepository>((ref) {
  return TreatmentRepository(ref.watch(dioProvider));
});

final treatmentListProvider = FutureProvider.autoDispose<List<Treatment>>((ref) {
  return ref.watch(treatmentRepositoryProvider).listTreatments();
});
