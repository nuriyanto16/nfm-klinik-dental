import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'doctor_model.dart';

class DoctorRepository {
  DoctorRepository(this._dio);

  final Dio _dio;

  Future<List<Doctor>> listDoctors() async {
    final res = await _dio.get<List<dynamic>>('/doctors');
    return (res.data ?? []).map((e) => Doctor.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<DoctorDetail> getDoctor(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/doctors/$id');
    return DoctorDetail.fromJson(res.data!);
  }
}

final doctorRepositoryProvider = Provider<DoctorRepository>((ref) {
  return DoctorRepository(ref.watch(dioProvider));
});

final doctorListProvider = FutureProvider.autoDispose<List<Doctor>>((ref) {
  return ref.watch(doctorRepositoryProvider).listDoctors();
});

final doctorDetailProvider = FutureProvider.autoDispose.family<DoctorDetail, String>((ref, id) {
  return ref.watch(doctorRepositoryProvider).getDoctor(id);
});
