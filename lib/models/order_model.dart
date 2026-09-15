import 'firestore_date_utils.dart';

class OrderModel {
  final String id;
  final String buyerId;
  final String sellerId;
  final String productId;
  final String productName;
  final double quantity;
  final double totalPrice;
  final String status;
  final String deliveryAddress;
  final DateTime createdAt;

  OrderModel({
    required this.id,
    required this.buyerId,
    required this.sellerId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalPrice,
    required this.status,
    required this.deliveryAddress,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'buyerId': buyerId,
      'sellerId': sellerId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'status': status,
      'deliveryAddress': deliveryAddress,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory OrderModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return OrderModel(
      id: id,
      buyerId: map['buyerId'] as String? ?? '',
      sellerId: map['sellerId'] as String? ?? '',
      productId: map['productId'] as String? ?? '',
      productName: map['productName'] as String? ?? '',
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      totalPrice: (map['totalPrice'] as num?)?.toDouble() ?? 0,
      status: map['status'] as String? ?? 'placed',
      deliveryAddress: map['deliveryAddress'] as String? ?? '',
      createdAt: parseFirestoreDate(map['createdAt']),
    );
  }
}



