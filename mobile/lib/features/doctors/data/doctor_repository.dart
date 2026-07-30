import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'doctor_model.dart';

final List<Doctor> _fallbackDoctors = [
  const Doctor(
    id: '21000000-0000-0000-0000-000000000001',
    fullName: 'drg. Friski Raisis, Sp.Ort',
    specialization: 'Spesialis Ortodonti',
    photoUrl: 'https://images.unsplash.com/photo-1622253692010-333f2da6031d?w=800',
  ),
  const Doctor(
    id: '21000000-0000-0000-0000-000000000002',
    fullName: 'drg. Siti Aminah',
    specialization: 'Dokter Gigi Umum',
    photoUrl: 'https://images.unsplash.com/photo-1594824813571-24a69c100c3f?w=800',
  ),
  const Doctor(
    id: '21000000-0000-0000-0000-000000000003',
    fullName: 'drg. Budi Santoso, Sp.KGA',
    specialization: 'Spesialis Gigi Anak',
    photoUrl: 'https://images.unsplash.com/photo-1537368910025-700350fe46c7?w=800',
  ),
];

class DoctorRepository {
  DoctorRepository(this._dio);

  final Dio _dio;

  Future<List<Doctor>> listDoctors() async {
    try {
      final res = await _dio.get<List<dynamic>>('/doctors');
      final list = (res.data ?? []).map((e) => Doctor.fromJson(e as Map<String, dynamic>)).toList();
      return list.isNotEmpty ? list : _fallbackDoctors;
    } catch (_) {
      return _fallbackDoctors;
    }
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
