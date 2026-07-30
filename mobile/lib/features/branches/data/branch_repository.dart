import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import 'branch_model.dart';

class BranchRepository {
  BranchRepository(this._dio);

  final Dio _dio;

  Future<List<Branch>> listBranches() async {
    final res = await _dio.get<List<dynamic>>('/branches');
    return (res.data ?? []).map((e) => Branch.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final branchRepositoryProvider = Provider<BranchRepository>((ref) {
  return BranchRepository(ref.watch(dioProvider));
});

final branchListProvider = FutureProvider.autoDispose<List<Branch>>((ref) {
  return ref.watch(branchRepositoryProvider).listBranches();
});
