import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../orders/data/order_repository.dart';
import '../../auth/data/auth_repository.dart';

class SellerAnalyticsScreen extends ConsumerWidget {
  const SellerAnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;
    if (user == null) return const SizedBox.shrink();

    final ordersAsync = ref.watch(sellerOrdersProvider(user.uid));

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
),        title: const Text('Sales Analytics')),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => const Center(child: Text('Something went wrong. Please try again.')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(child: Text('No orders yet.'));
          }

          final delivered = orders.where((o) => o.status == 'completed').toList();
          final revenue = delivered.fold<double>(0, (sum, o) => sum + o.totalPrice);
          final fulfillmentRate =
              orders.isEmpty ? 0.0 : (delivered.length / orders.length) * 100;

          final productRevenue = <String, double>{};
          for (final o in delivered) {
            productRevenue[o.productName] =
                (productRevenue[o.productName] ?? 0) + o.totalPrice;
          }
          final sortedProducts = productRevenue.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Total Revenue',
                      value: 'Rs. ${revenue.toStringAsFixed(0)}',
                      icon: Icons.currency_rupee,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Total Orders',
                      value: '${orders.length}',
                      icon: Icons.receipt_long,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Delivered',
                      value: '${delivered.length}',
                      icon: Icons.check_circle_outline,
                      color: Colors.purple,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'Fulfillment Rate',
                      value: '${fulfillmentRate.toStringAsFixed(0)}%',
                      icon: Icons.trending_up,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text('Top Products by Revenue', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              if (sortedProducts.isEmpty)
                const Text('No delivered orders yet.')
              else
                ...sortedProducts.take(5).map((entry) {
                  final maxRevenue = sortedProducts.first.value;
                  final fraction = entry.value / maxRevenue;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${entry.key} x Rs. ${entry.value.toStringAsFixed(0)}'),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: fraction,
                            minHeight: 8,
                            backgroundColor: Colors.grey.shade200,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            Text(label, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}




