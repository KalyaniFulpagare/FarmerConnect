import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/notification_model.dart';
import '../../auth/data/auth_repository.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('notifications');

  Future<void> markRead(String notificationId) {
    return _col.doc(notificationId).update({'isRead': true});
  }

  Stream<List<NotificationModel>> watchNotifications(String userId) {
    return _col
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => NotificationModel.fromMap(d.id, d.data()))
              .toList(),
        );
  }
}

final notificationRepositoryProvider =
    Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(firestoreProvider));
});

final notificationsProvider =
    StreamProvider.family<List<NotificationModel>, String>((ref, userId) {
  return ref.watch(notificationRepositoryProvider).watchNotifications(userId);
});



