import 'package:flutter_riverpod/flutter_riverpod.dart';

class UsedVouchersNotifier extends StateNotifier<Set<String>> {
  UsedVouchersNotifier() : super({'NDCUSED1'});

  void markUsed(String code) {
    state = {...state, code.toUpperCase()};
  }

  bool isUsed(String code) {
    return state.contains(code.toUpperCase());
  }
}

final usedVouchersProvider = StateNotifierProvider<UsedVouchersNotifier, Set<String>>((ref) {
  return UsedVouchersNotifier();
});
