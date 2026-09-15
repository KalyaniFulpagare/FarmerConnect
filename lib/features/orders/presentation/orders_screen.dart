import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/order_repository.dart';
import '../../auth/data/auth_repository.dart';

Color _statusColor(String status) {
  switch (status) {
    case 'placed':
      return Colors.orange;
    case 'confirmed':
      return Colors.blue;
    case 'packed':
      return Colors.purple;
    case 'out_for_delivery':
      return Colors.teal;
    case 'delivered':
      return Colors.green;
    default:
      return Colors.grey;
  }
}

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    if (user == null) return const SizedBox.shrink();

    final ordersAsync = ref.watch(buyerOrdersProvider(user.uid));

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
),        title: const Text('My Orders')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => const Center(child: Text('Something went wrong. Please try again.')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final o = orders[index];
              return Card(
                child: ListTile(
                  title: Text(o.productName),
                  subtitle: Text('${o.quantity} units x Rs. ${o.totalPrice.toStringAsFixed(0)}'),
                  trailing: Chip(
                    label: Text(
                      o.status.replaceAll('_', ' ').toUpperCase(),
                      style: const TextStyle(fontSize: 10, color: Colors.white),
                    ),
                    backgroundColor: _statusColor(o.status),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}



