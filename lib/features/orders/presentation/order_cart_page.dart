import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/order_model.dart';
import '../../auth/data/auth_repository.dart';
import '../data/cart_provider.dart';
import '../data/order_repository.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key});

  @override
  ConsumerState<CartScreen> createState() => CartScreenState();
}

class CartScreenState extends ConsumerState<CartScreen> {
  bool _isPlacing = false;
  final _addressController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _checkout() async {
    if (_isPlacing) return;

    final cart = ref.read(cartProvider);

    if (cart.isEmpty) {
      _showMessage('Your cart is empty.');
      return;
    }

    final address = _addressController.text.trim();

    if (address.isEmpty) {
      _showMessage('Please enter a delivery address.');
      return;
    }

    setState(() => _isPlacing = true);

    try {
      final user = ref.read(firebaseAuthProvider).currentUser;

      if (user == null) {
        _showMessage('Please sign in to place an order.');
        return;
      }

      final firestore = ref.read(firestoreProvider);
      final orders = <OrderModel>[];

      for (final item in cart) {
        final productRef =
            firestore.collection('products').doc(item.productId);

        final productSnap = await productRef.get();

        if (!productSnap.exists) {
          throw Exception('A product in your cart no longer exists.');
        }

        final product = productSnap.data()!;

        if (product['isActive'] != true) {
          throw Exception(
            '${product['name'] ?? 'A product'} is no longer available.',
          );
        }

        final stock = (product['quantity'] as num?)?.toDouble() ?? 0;

        if (stock < item.quantity) {
          throw Exception(
            'Not enough stock for ${product['name'] ?? 'a product'}.',
          );
        }

        final price = (product['price'] as num?)?.toDouble() ?? 0;

        orders.add(
          OrderModel(
            id: firestore.collection('orders').doc().id,
            buyerId: user.uid,
            sellerId: product['sellerId'] as String,
            productId: item.productId,
            productName: product['name'] as String? ?? 'Product',
            quantity: item.quantity,
            totalPrice: price * item.quantity,
            deliveryAddress: address,
            status: 'placed',
            createdAt: DateTime.now(),
          ),
        );
      }

      await ref.read(orderRepositoryProvider).placeCartOrder(
            orders: orders,
            deliveryAddress: address,
          );

      ref.read(cartProvider.notifier).clear();

      if (!mounted) return;

      _showMessage('Order placed successfully.');
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      var message = e.toString();

      if (message.startsWith('Exception: ')) {
        message = message.substring('Exception: '.length);
      }

      _showMessage(message);
    } finally {
      if (mounted) {
        setState(() => _isPlacing = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message)),
      );
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    final total = cart.fold<double>(
      0,
      (sum, item) => sum + item.product.price * item.quantity,
    );

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
  icon: const Icon(Icons.arrow_back),
  onPressed: () {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  },
),        title: const Text('Cart'),
      ),
      body: SafeArea(
        child: cart.isEmpty
            ? const Center(
                child: Text('Your cart is empty.'),
              )
            : Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Expanded(
                      child: ListView.separated(
                        itemCount: cart.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final item = cart[index];

                          return Card(
                            child: ListTile(
                              title: Text(item.product.name),
                              subtitle: Text(
                                'Rs. ${item.product.price.toStringAsFixed(2)} - ${item.quantity}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      ref
                                          .read(cartProvider.notifier)
                                          .updateQuantity(
                                            item.productId,
                                            item.quantity - 1,
                                          );
                                    },
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Text(
                                    item.quantity.toStringAsFixed(
                                      item.quantity % 1 == 0 ? 0 : 1,
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () {
                                      ref
                                          .read(cartProvider.notifier)
                                          .updateQuantity(
                                            item.productId,
                                            item.quantity + 1,
                                          );
                                    },
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _addressController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Delivery address',
                        hintText: 'Enter your delivery address',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Rs. ${total.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isPlacing ? null : _checkout,
                        child: _isPlacing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Place Order'),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}





