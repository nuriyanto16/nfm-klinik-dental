import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'branch_model.dart';

final List<Branch> _fallbackBranches = [
  const Branch(
    id: '11000000-0000-0000-0000-000000000001',
    name: 'Klinik Soreang Utama',
    slug: 'soreang',
    city: 'Kab. Bandung',
    address: 'Jl. Raya Soreang No. 88, Soreang, Kab. Bandung',
    phone: '022-5891234',
    opensAt: '08:00',
    closesAt: '21:00',
    isActive: true,
  ),
  const Branch(
    id: '11000000-0000-0000-0000-000000000002',
    name: 'Klinik Baleendah',
    slug: 'baleendah',
    city: 'Kab. Bandung',
    address: 'Jl. Raya Baleendah No. 45, Baleendah, Kab. Bandung',
    phone: '022-5895678',
    opensAt: '08:00',
    closesAt: '21:00',
    isActive: true,
  ),
];

class BranchRepository {
  BranchRepository(this._dio);

  final Dio _dio;

  Future<List<Branch>> listBranches() async {
    try {
      final res = await _dio.get<List<dynamic>>('/branches');
      final list = (res.data ?? []).map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList();
      return list.isNotEmpty ? list : _fallbackBranches;
    } catch (_) {
      return _fallbackBranches;
    }
  }
}

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  return BranchRepository(ref.watch(dioProvider));
});

final branchListProvider = FutureProvider.autoDispose<List<Branch>>((ref) {
  return ref.watch(branchRepositoryProvider).listBranches();
});
