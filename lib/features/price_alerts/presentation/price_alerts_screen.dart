import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/price_alert_repository.dart';
import '../../auth/data/auth_repository.dart';

class PriceAlertsScreen extends ConsumerStatefulWidget {
  const PriceAlertsScreen({super.key});

  @override
  ConsumerState<PriceAlertsScreen> createState() => _PriceAlertsScreenState();
}

class _PriceAlertsScreenState extends ConsumerState<PriceAlertsScreen> {
  final _categoryController = TextEditingController();
  final _targetPriceController = TextEditingController();

  @override
  void dispose() {
    _categoryController.dispose();
    _targetPriceController.dispose();
    super.dispose();
  }

  Future<void> _createAlert() async {
    final user = ref.read(authServiceProvider).currentUser;
    if (user == null) return;
    final category = _categoryController.text.trim();
    final target = double.tryParse(_targetPriceController.text);
    if (category.isEmpty || target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid category and target price')),
      );
      return;
    }
    await ref.read(priceAlertRepositoryProvider).createAlert(
          userId: user.uid,
          category: category,
          targetPrice: target,
        );
    _categoryController.clear();
    _targetPriceController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authServiceProvider).currentUser;
    if (user == null) return const SizedBox.shrink();

    final alertsAsync = ref.watch(userAlertsProvider(user.uid));

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
),        title: const Text('My Price Alerts')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _categoryController,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _targetPriceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Target ?f???,?s?,?',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _createAlert,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Expanded(
            child: alertsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => const Center(child: Text('Something went wrong. Please try again.')),
              data: (alerts) {
                if (alerts.isEmpty) {
                  return const Center(child: Text('No alerts set. Add one above.'));
                }
                return ListView.builder(
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    final a = alerts[index];
                    return ListTile(
                      leading: Icon(
                        a.notificationSent ? Icons.check_circle : Icons.notifications_active_outlined,
                        color: a.notificationSent ? Colors.green : Colors.orange,
                      ),
                      title: Text(a.category),
                      subtitle: Text('Alert when price ?f???,???,? ?f???,?s?,?${a.targetPrice.toStringAsFixed(0)}'
                          '${a.notificationSent ? " (triggered)" : ""}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () =>
                            ref.read(priceAlertRepositoryProvider).deleteAlert(a.id),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



