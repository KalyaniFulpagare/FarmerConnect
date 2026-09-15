import 'firestore_date_utils.dart';

class PriceHistoryEntry {
  final String category;
  final double avgPrice;
  final DateTime date;

  PriceHistoryEntry({
    required this.category,
    required this.avgPrice,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'category': category,
      'avgPrice': avgPrice,
      'date': date.toIso8601String(),
    };
  }

  factory PriceHistoryEntry.fromMap(
    Map<String, dynamic> map,
  ) {
    return PriceHistoryEntry(
      category: map['category'] as String? ?? '',
      avgPrice: (map['avgPrice'] as num?)?.toDouble() ?? 0,
      date: parseFirestoreDate(map['date']),
    );
  }
}



