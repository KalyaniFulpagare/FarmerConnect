import 'firestore_date_utils.dart';

class ProductModel {
  final String id;
  final String sellerId;
  final String name;
  final String category;
  final double price;
  final double quantity;
  final String unit;
  final String address;
  final String description;
  final bool isActive;
  final double? latitude;
  final double? longitude;
  final String? imageUrl;
  final DateTime createdAt;

  ProductModel({
    required this.id,
    required this.sellerId,
    required this.name,
    required this.category,
    required this.price,
    required this.quantity,
    required this.unit,
    required this.address,
    required this.description,
    required this.isActive,
    this.latitude,
    this.longitude,
    this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'sellerId': sellerId,
      'name': name,
      'category': category,
      'price': price,
      'quantity': quantity,
      'unit': unit,
      'address': address,
      'description': description,
      'isActive': isActive,
      'latitude': latitude,
      'longitude': longitude,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProductModel.fromMap(
    String id,
    Map<String, dynamic> map,
  ) {
    return ProductModel(
      id: id,
      sellerId: map['sellerId'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed product',
      category: map['category'] as String? ?? 'Other',
      price: (map['price'] as num?)?.toDouble() ?? 0,
      quantity: (map['quantity'] as num?)?.toDouble() ?? 0,
      unit: map['unit'] as String? ?? 'piece',
      address: map['address'] as String? ?? '',
      description: map['description'] as String? ?? '',
      isActive: map['isActive'] as bool? ?? true,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      imageUrl: map['imageUrl'] as String?,
      createdAt: parseFirestoreDate(map['createdAt']),
    );
  }
}



