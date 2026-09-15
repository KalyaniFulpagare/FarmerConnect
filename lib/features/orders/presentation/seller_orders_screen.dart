import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/order_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../../models/order_model.dart';

class SellerOrdersScreen extends ConsumerWidget {
  const SellerOrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sellerId = FirebaseAuth.instance.currentUser?.uid;

    if (sellerId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Seller Orders')),
        body: const Center(child: Text('Please log in again.')),
      );
    }

    final ordersAsync = ref.watch(sellerOrdersProvider(sellerId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Seller Orders'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48),
                const SizedBox(height: 12),
                const Text(
                  'Could not load orders.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Text(error.toString(), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () {
                    ref.invalidate(sellerOrdersProvider(sellerId));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (orders) {
          if (orders.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(sellerOrdersProvider(sellerId));
              },
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 180),
                  Icon(Icons.receipt_long_outlined, size: 64),
                  SizedBox(height: 16),
                  Center(
                    child: Text(
                      'No orders yet.',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  Center(child: Text('Orders from buyers will appear here.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(sellerOrdersProvider(sellerId));
            },
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: orders.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _SellerOrderCard(order: orders[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _SellerOrderCard extends ConsumerWidget {
  final OrderModel order;

  const _SellerOrderCard({required this.order});

  Stream<double?> _remainingQuantityStream(WidgetRef ref) {
    return ref
        .read(firestoreProvider)
        .collection('products')
        .doc(order.productId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            return null;
          }

          return (snapshot.data()?['quantity'] as num?)?.toDouble() ?? 0;
        });
  }

  Color _statusColor(BuildContext context) {
    switch (order.status.toLowerCase()) {
      case 'placed':
      case 'pending':
        return Colors.orange;

      case 'accepted':
        return Colors.blue;

      case 'preparing':
        return Colors.deepPurple;

      case 'ready':
        return Colors.teal;

      case 'completed':
        return Colors.green;

      case 'cancelled':
      case 'canceled':
        return Colors.red;

      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  String _nextStatus() {
    switch (order.status.toLowerCase()) {
      case 'placed':
      case 'pending':
        return 'accepted';

      case 'accepted':
        return 'preparing';

      case 'preparing':
        return 'ready';

      case 'ready':
        return 'completed';

      default:
        return '';
    }
  }

  String _nextLabel() {
    switch (order.status.toLowerCase()) {
      case 'placed':
      case 'pending':
        return 'Accept Order';

      case 'accepted':
        return 'Start Preparing';

      case 'preparing':
        return 'Mark Ready';

      case 'ready':
        return 'Complete Order';

      default:
        return '';
    }
  }

  String _formatQuantity(double value) {
    if (value % 1 == 0) {
      return value.toInt().toString();
    }

    return value.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(context);
    final nextStatus = _nextStatus();
    final nextLabel = _nextLabel();

    final canCancel = [
      'placed',
      'pending',
      'accepted',
      'preparing',
    ].contains(order.status.toLowerCase());

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    order.productName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            StreamBuilder<double?>(
              stream: _remainingQuantityStream(ref),
              builder: (context, snapshot) {
                final remaining = snapshot.data;

                return Column(
                  children: [
                    _InfoRow(
                      icon: Icons.shopping_basket_outlined,
                      label: 'Ordered quantity',
                      value: '${order.quantity}',
                    ),
                    const SizedBox(height: 8),
                    _InfoRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'Remaining quantity',
                      value: snapshot.connectionState == ConnectionState.waiting
                          ? 'Loading...'
                          : remaining == null
                          ? 'Unavailable'
                          : _formatQuantity(remaining),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 8),

            _InfoRow(
              icon: Icons.currency_rupee,
              label: 'Order total',
              value: 'Rs. ${order.totalPrice.toStringAsFixed(2)}',
            ),

            const SizedBox(height: 8),

            _InfoRow(
              icon: Icons.location_on_outlined,
              label: 'Delivery address',
              value: order.deliveryAddress,
            ),

            const SizedBox(height: 8),

            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Order date',
              value: _formatDate(order.createdAt),
            ),

            if (nextStatus.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () async {
                    try {
                      await ref
                          .read(orderRepositoryProvider)
                          .updateStatus(orderId: order.id, status: nextStatus);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Order marked as ${nextStatus.toUpperCase()}.',
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not update order: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(nextLabel),
                ),
              ),
            ],

            if (canCancel) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await ref
                          .read(orderRepositoryProvider)
                          .updateStatus(orderId: order.id, status: 'cancelled');

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order cancelled.')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not cancel order: $e')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.close),
                  label: const Text('Cancel Order'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();

    final hour = date.hour == 0
        ? 12
        : date.hour > 12
        ? date.hour - 12
        : date.hour;

    final minute = date.minute.toString().padLeft(2, '0');
    final period = date.hour >= 12 ? 'PM' : 'AM';

    return '$day/$month/$year, $hour:$minute $period';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 19, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: DefaultTextStyle.of(context).style,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
