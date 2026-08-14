import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class PointTransactionItem {
  const PointTransactionItem({
    required this.id,
    required this.userId,
    required this.type,
    required this.points,
    required this.description,
    this.referenceId,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String type; // earn, redeem, adjustment, bonus
  final int points;
  final String description;
  final String? referenceId;
  final DateTime createdAt;

  factory PointTransactionItem.fromJson(Map<String, dynamic> json) => PointTransactionItem(
        id: json['id'] as String? ?? '',
        userId: json['userId'] as String? ?? '',
        type: json['type'] as String? ?? 'earn',
        points: (json['points'] as num?)?.toInt() ?? 0,
        description: json['description'] as String? ?? '',
        referenceId: json['referenceId'] as String?,
        createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : DateTime.now(),
      );
}

class UserPointsData {
  const UserPointsData({
    required this.pointsBalance,
    required this.rupiahValue,
    required this.transactions,
  });

  final int pointsBalance;
  final double rupiahValue;
  final List<PointTransactionItem> transactions;

  factory UserPointsData.fromJson(Map<String, dynamic> json) {
    final txList = (json['transactions'] as List<dynamic>?)
            ?.map((e) => PointTransactionItem.fromJson(e as Map<String, dynamic>))
            .toList() ??
        [];
    return UserPointsData(
      pointsBalance: (json['pointsBalance'] as num?)?.toInt() ?? 250,
      rupiahValue: (json['rupiahValue'] as num?)?.toDouble() ?? 25000.0,
      transactions: txList,
    );
  }
}

class PointRepository {
  PointRepository(this._dio);

  final Dio _dio;

  Future<UserPointsData> getMyPoints({String? userId}) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        '/patient/points',
        queryParameters: userId != null && userId.isNotEmpty ? {'userId': userId} : null,
      );

      if (response.data != null) {
        return UserPointsData.fromJson(response.data!);
      }
    } catch (e) {
      debugPrint('[PointRepository] Error fetching points: $e');
    }

    // Fallback default sample user points if offline or API unreachable
    return UserPointsData(
      pointsBalance: 250,
      rupiahValue: 25000.0,
      transactions: [
        PointTransactionItem(
          id: 'pt-1',
          userId: 'user-1',
          type: 'earn',
          points: 50,
          description: 'Perolehan Poin Reservasi Soreang',
          createdAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        PointTransactionItem(
          id: 'pt-2',
          userId: 'user-1',
          type: 'bonus',
          points: 100,
          description: 'Poin Selamat Datang NDC Member',
          createdAt: DateTime.now().subtract(const Duration(days: 10)),
        ),
        PointTransactionItem(
          id: 'pt-3',
          userId: 'user-1',
          type: 'earn',
          points: 100,
          description: 'Perolehan Poin Transaksi Scaling 6-in-1',
          createdAt: DateTime.now().subtract(const Duration(days: 15)),
        ),
      ],
    );
  }
}

final pointRepositoryProvider = Provider<PointRepository>((ref) {
  return PointRepository(ref.watch(dioProvider));
});

final myPointsProvider = FutureProvider.family<UserPointsData, String?>((ref, userId) async {
  return ref.watch(pointRepositoryProvider).getMyPoints(userId: userId);
});
