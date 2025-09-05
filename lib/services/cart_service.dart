// lib/services/cart_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? getUserId() => _auth.currentUser?.uid;

  Stream<QuerySnapshot<Map<String, dynamic>>> getCartStream() {
    final userId = getUserId();
    if (userId == null) {
      return const Stream.empty();
    }
    return _firestore
        .collection('carts')
        .doc(userId)
        .collection('items')
        .snapshots();
  }

  /// Update or delete a cart item.
  /// If [docId] is passed, that Firestore document is targeted. Otherwise we
  /// derive a normalized id from product['name'].
  Future<void> updateCartItem(
    Map<String, dynamic> product,
    int newQuantity, {
    String? docId,
  }) async {
    final userId = getUserId();
    if (userId == null) {
      throw FirebaseAuthException(
        code: 'not-logged-in',
        message: 'User must be logged in to update cart',
      );
    }

    final rawName = (product['name'] ?? '').toString();
    if (rawName.trim().isEmpty && (docId == null || docId.trim().isEmpty)) {
      throw ArgumentError('Either product.name or docId must be provided');
    }

    final id = (docId != null && docId.trim().isNotEmpty)
        ? docId
        : rawName.trim().toLowerCase();

    final cartItemRef =
        _firestore.collection('carts').doc(userId).collection('items').doc(id);

    if (newQuantity > 0) {
      final payload = <String, dynamic>{
        'name': rawName,
        'normalizedName': rawName.trim().toLowerCase(),
        'subtitle': product['subtitle'] ?? '',
        'price': product['price'] ?? '',
        'imageUrl': product['imageUrl'] ?? '',
        'quantity': newQuantity,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await cartItemRef.set(payload, SetOptions(merge: true));
    } else {
      // delete when qty is zero or less
      await cartItemRef.delete();
    }
  }
}
