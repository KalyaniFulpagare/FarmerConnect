import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../models/product_model.dart';

class CartItem {
  final String productId;
  final double quantity;
  final ProductModel product;

  CartItem({
    required this.productId,
    required this.quantity,
    required this.product,
  });

  CartItem copyWith({
    String? productId,
    double? quantity,
    ProductModel? product,
  }) {
    return CartItem(
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      product: product ?? this.product,
    );
  }
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addItem(ProductModel product, double quantity) {
    final existingIndex =
        state.indexWhere((item) => item.productId == product.id);

    if (existingIndex >= 0) {
      final updated = [...state];
      final existing = updated[existingIndex];

      updated[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
        product: product,
      );

      state = updated;
    } else {
      state = [
        ...state,
        CartItem(
          productId: product.id,
          quantity: quantity,
          product: product,
        ),
      ];
    }
  }

  void updateQuantity(String productId, double quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final updated = [...state];
    final index = updated.indexWhere((item) => item.productId == productId);

    if (index >= 0) {
      updated[index] = updated[index].copyWith(quantity: quantity);
      state = updated;
    }
  }

  void removeItem(String productId) {
    state = state.where((item) => item.productId != productId).toList();
  }

  void clear() {
    state = [];
  }

  double get total =>
      state.fold(0, (sum, item) => sum + (item.product.price * item.quantity));
}

final cartProvider =
    StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});



