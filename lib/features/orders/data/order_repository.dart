import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../../models/order_model.dart';

class OrderRepository {
  final FirebaseFirestore _firestore;

  OrderRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('orders');

  Future<void> placeOrderWithStockCheck(OrderModel order) async {
    final productRef = _firestore.collection('products').doc(order.productId);
    final orderRef = _col.doc(order.id);

    await _firestore.runTransaction((transaction) async {
      final productSnap = await transaction.get(productRef);

      if (!productSnap.exists) {
        throw Exception('Product no longer exists.');
      }

      final product = productSnap.data()!;
      final active = product['isActive'] == true;
      final stock = (product['quantity'] as num?)?.toDouble() ?? 0;
      final currentPrice = (product['price'] as num?)?.toDouble() ?? 0;

      if (!active) {
        throw Exception('This product is no longer available.');
      }

      if (stock < order.quantity) {
        throw Exception('Not enough stock available.');
      }

      if ((currentPrice - order.totalPrice / order.quantity).abs() > 0.01) {
        throw Exception('Product price has changed. Please try again.');
      }

      transaction.update(productRef, {
        'quantity': stock - order.quantity,
        'isActive': stock - order.quantity > 0,
      });

      transaction.set(orderRef, order.toMap());
    });
  }

  Future<void> placeCartOrder({
    required List<OrderModel> orders,
    required String deliveryAddress,
  }) async {
    if (orders.isEmpty) {
      throw Exception('Your cart is empty.');
    }

    if (orders.length > 20) {
      throw Exception('Too many items in cart.');
    }

    final productRefs = <DocumentReference<Map<String, dynamic>>>[];
    final orderRefs = <DocumentReference<Map<String, dynamic>>>[];

    for (final order in orders) {
      productRefs.add(_firestore.collection('products').doc(order.productId));
      orderRefs.add(_col.doc(order.id));
    }

    await _firestore.runTransaction((transaction) async {
      final productSnapshots = <DocumentSnapshot<Map<String, dynamic>>>[];

      for (final ref in productRefs) {
        productSnapshots.add(await transaction.get(ref));
      }

      for (var i = 0; i < orders.length; i++) {
        final order = orders[i];
        final productSnap = productSnapshots[i];

        if (!productSnap.exists) {
          throw Exception('A product in your cart no longer exists.');
        }

        final product = productSnap.data()!;
        final active = product['isActive'] == true;
        final stock = (product['quantity'] as num?)?.toDouble() ?? 0;
        final currentPrice = (product['price'] as num?)?.toDouble() ?? 0;

        if (!active) {
          throw Exception(
            '${product['name'] ?? 'A product'} is no longer available.',
          );
        }

        if (stock < order.quantity) {
          throw Exception(
            'Not enough stock for ${product['name'] ?? 'a product'}.',
          );
        }

        final unitPrice = order.totalPrice / order.quantity;

        if ((currentPrice - unitPrice).abs() > 0.01) {
          throw Exception(
            'Price changed for ${product['name'] ?? 'a product'}.',
          );
        }

        final remainingStock = stock - order.quantity;

        transaction.update(productRefs[i], {
          'quantity': remainingStock,
          'isActive': remainingStock > 0,
        });

        transaction.set(orderRefs[i], order.toMap());
      }
    });
  }

  Future<void> updateStatus({
    required String orderId,
    required String status,
  }) async {
    const allowedStatuses = {
      'placed',
      'accepted',
      'preparing',
      'ready',
      'completed',
      'cancelled',
    };

    if (!allowedStatuses.contains(status)) {
      throw Exception('Invalid order status.');
    }

    await _col.doc(orderId).update({
      'status': status,
    });
  }
  Stream<List<OrderModel>> watchBuyerOrders(String buyerId) {
    return _col
        .where('buyerId', isEqualTo: buyerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList(),
        );
  }

  Stream<List<OrderModel>> watchSellerOrders(String sellerId) {
    return _col
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList(),
        );
  }
}

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(firestoreProvider));
});

final buyerOrdersProvider = StreamProvider.family<List<OrderModel>, String>((
  ref,
  buyerId,
) {
  return ref.watch(orderRepositoryProvider).watchBuyerOrders(buyerId);
});

final sellerOrdersProvider = StreamProvider.family<List<OrderModel>, String>((
  ref,
  sellerId,
) {
  return ref.watch(orderRepositoryProvider).watchSellerOrders(sellerId);
});




