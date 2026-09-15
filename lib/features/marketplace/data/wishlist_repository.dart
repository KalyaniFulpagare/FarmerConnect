import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../auth/data/auth_repository.dart';

class WishlistRepository {
  final FirebaseFirestore _firestore;
  WishlistRepository(this._firestore);

  DocumentReference<Map<String, dynamic>> _doc(String userId) =>
      _firestore.collection('wishlists').doc(userId);

  Stream<List<String>> watchWishlist(String userId) {
    return _doc(userId).snapshots().map((snap) {
      if (!snap.exists) return <String>[];
      final data = snap.data();
      final list = data?['products'] as List<dynamic>?;
      return list?.map((e) => e.toString()).toList() ?? <String>[];
    });
  }

  Future<void> toggleWishlist(String userId, String productId, bool add) async {
    final docRef = _doc(userId);
    final snap = await docRef.get();
    if (!snap.exists) {
      await docRef.set({'products': add ? [productId] : []});
      return;
    }
    if (add) {
      await docRef.update({
        'products': FieldValue.arrayUnion([productId]),
      });
    } else {
      await docRef.update({
        'products': FieldValue.arrayRemove([productId]),
      });
    }
  }
}

final wishlistRepositoryProvider = Provider<WishlistRepository>((ref) {
  return WishlistRepository(ref.watch(firestoreProvider));
});

final wishlistProvider = StreamProvider.family<List<String>, String>((ref, userId) {
  return ref.watch(wishlistRepositoryProvider).watchWishlist(userId);
});


