import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/price_history_repository.dart';

class PriceTrendCard extends ConsumerWidget {
  final String category;

  const PriceTrendCard({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(priceHistoryProvider(category));

    return historyAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (entries) {
        if (entries.length < 2) {
          return const SizedBox.shrink();
        }

        final repo = ref.read(priceHistoryRepositoryProvider);
        final result = repo.computeTrend(entries);

        IconData icon;
        Color color;
        String label;

        switch (result.direction) {
          case 'rising':
            icon = Icons.trending_up;
            color = Colors.red;
            label = 'Prices trending up';
            break;
          case 'falling':
            icon = Icons.trending_down;
            color = Colors.green;
            label = 'Prices trending down';
            break;
          default:
            icon = Icons.trending_flat;
            color = Colors.grey;
            label = 'Prices stable';
        }

        return Card(
          color: color.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      if (result.predictedPrice != null)
                        Text(
                          'Trend estimate: Rs. ${result.predictedPrice!.toStringAsFixed(0)} next avg',
                          style: const TextStyle(fontSize: 12),
                        )
                      else
                        const Text(
                          'Not enough data for an estimate',
                          style: TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}



