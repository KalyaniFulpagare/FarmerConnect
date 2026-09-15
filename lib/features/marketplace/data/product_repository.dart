import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../models/product_model.dart';
import '../../auth/data/auth_repository.dart';

class ProductRepository {
  final FirebaseFirestore _firestore;
  ProductRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> get _col =>
      _firestore.collection('products');

  Future<void> createProduct(ProductModel product) {
    return _col.doc(product.id).set(product.toMap());
  }

  Future<void> updateProduct(ProductModel product) {
    return _col.doc(product.id).update(product.toMap());
  }

  Future<void> deleteProduct(String productId) {
    return _col.doc(productId).delete();
  }

  Future<void> toggleActive(String productId, bool isActive) {
    return _col.doc(productId).update({'isActive': isActive});
  }

  Stream<List<ProductModel>> watchSellerProducts(String sellerId) {
    return _col
        .where('sellerId', isEqualTo: sellerId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<List<ProductModel>> watchActiveProducts() {
    return _col
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ProductModel.fromMap(doc.id, doc.data()))
            .toList());
  }

  Stream<ProductModel?> watchProduct(String productId) {
    return _col.doc(productId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ProductModel.fromMap(doc.id, doc.data()!);
    });
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(firestoreProvider));
});

final sellerProductsProvider = StreamProvider.family<List<ProductModel>, String>((ref, sellerId) {
  return ref.watch(productRepositoryProvider).watchSellerProducts(sellerId);
});

final activeProductsProvider = StreamProvider<List<ProductModel>>((ref) {
  return ref.watch(productRepositoryProvider).watchActiveProducts();
});

final singleProductProvider = StreamProvider.family<ProductModel?, String>((ref, productId) {
  return ref.watch(productRepositoryProvider).watchProduct(productId);
});


