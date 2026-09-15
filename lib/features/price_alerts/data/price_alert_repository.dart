import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/price_alert_model.dart';
import '../../auth/data/auth_repository.dart';

class PriceAlertRepository {
  final FirebaseFirestore _firestore;

  PriceAlertRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('price_alerts');

  Future<void> createAlert({
    required String userId,
    required String category,
    required double targetPrice,
  }) {
    final docRef = _col.doc();

    return docRef.set(
      PriceAlertModel(
        id: docRef.id,
        userId: userId,
        category: category,
        targetPrice: targetPrice,
        isActive: true,
        notificationSent: false,
        createdAt: DateTime.now(),
      ).toMap(),
    );
  }

  Future<void> deleteAlert(String alertId) {
    return _col.doc(alertId).delete();
  }

  Stream<List<PriceAlertModel>> watchUserAlerts(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => PriceAlertModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }
}

final priceAlertRepositoryProvider =
    Provider<PriceAlertRepository>((ref) {
  return PriceAlertRepository(ref.watch(firestoreProvider));
});

final userAlertsProvider =
    StreamProvider.family<List<PriceAlertModel>, String>((ref, userId) {
  return ref.watch(priceAlertRepositoryProvider).watchUserAlerts(userId);
});



