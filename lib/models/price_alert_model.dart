import 'firestore_date_utils.dart';

class PriceAlertModel {
  final String id;
  final String userId;
  final String category;
  final double targetPrice;
  final bool isActive;
  final bool notificationSent;
  final DateTime createdAt;

  PriceAlertModel({
    required this.id,
    required this.userId,
    required this.category,
    required this.targetPrice,
    required this.isActive,
    required this.notificationSent,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'category': category,
      'targetPrice': targetPrice,
      'isActive': isActive,
      'notificationSent': notificationSent,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory PriceAlertModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return PriceAlertModel(
      id: id,
      userId: map['userId'] as String? ?? '',
      category: map['category'] as String? ?? '',
      targetPrice: (map['targetPrice'] as num?)?.toDouble() ?? 0,
      isActive: map['isActive'] as bool? ?? true,
      notificationSent: map['notificationSent'] as bool? ?? false,
      createdAt: parseFirestoreDate(map['createdAt']),
    );
  }
}



