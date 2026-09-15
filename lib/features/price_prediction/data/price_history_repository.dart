import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/price_history_model.dart';
import '../../auth/data/auth_repository.dart';

class PriceHistoryRepository {
  final FirebaseFirestore _firestore;

  PriceHistoryRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _entries(
    String category,
  ) {
    return _firestore
        .collection('price_history')
        .doc(category.toLowerCase())
        .collection('entries');
  }

  Stream<List<PriceHistoryEntry>> watchHistory(String category) {
    return _entries(category)
        .orderBy('date', descending: false)
        .limit(90)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(
                (d) => PriceHistoryEntry.fromMap(d.data()),
              )
              .toList(),
        );
  }

  TrendResult computeTrend(List<PriceHistoryEntry> entries) {
    if (entries.isEmpty) {
      return TrendResult(
        direction: 'stable',
        predictedPrice: null,
      );
    }

    if (entries.length == 1) {
      return TrendResult(
        direction: 'stable',
        predictedPrice: entries.first.avgPrice,
      );
    }

    final split = entries.length ~/ 2;

    final firstHalf = entries.take(split).toList();
    final secondHalf = entries.skip(split).toList();

    final firstAverage =
        firstHalf.map((e) => e.avgPrice).reduce((a, b) => a + b) /
            firstHalf.length;

    final secondAverage =
        secondHalf.map((e) => e.avgPrice).reduce((a, b) => a + b) /
            secondHalf.length;

    final difference = secondAverage - firstAverage;

    String direction;
    if (difference > 1) {
      direction = 'rising';
    } else if (difference < -1) {
      direction = 'falling';
    } else {
      direction = 'stable';
    }

    final predictedPrice =
        secondAverage + (difference / secondHalf.length);

    return TrendResult(
      direction: direction,
      predictedPrice: predictedPrice,
    );
  }
}

class TrendResult {
  final String direction;
  final double? predictedPrice;

  TrendResult({
    required this.direction,
    required this.predictedPrice,
  });
}

final priceHistoryRepositoryProvider =
    Provider<PriceHistoryRepository>((ref) {
  return PriceHistoryRepository(
    ref.watch(firestoreProvider),
  );
});

final priceHistoryProvider =
    StreamProvider.family<List<PriceHistoryEntry>, String>(
  (ref, category) {
    return ref
        .watch(priceHistoryRepositoryProvider)
        .watchHistory(category);
  },
);



