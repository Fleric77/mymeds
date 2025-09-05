// lib/services/order_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  final _db = FirebaseFirestore.instance;

  /// Create an order from the current user's cart items.
  /// Returns created orderId.
  Future<String> createOrderFromCart({
    required double total,
    required String paymentMethod,
    String? transactionId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Not signed in');

    final userId = user.uid;

    // 1. Fetch cart items
    final cartSnap =
        await _db.collection('carts').doc(userId).collection('items').get();

    if (cartSnap.docs.isEmpty) {
      throw Exception('Cart is empty');
    }

    final items = cartSnap.docs.map((d) {
      final data = d.data();
      return {
        'productId': d.id,
        'name': data['name'] ?? '',
        'price': (data['price'] is num)
            ? data['price']
            : double.tryParse(data['price'].toString()) ?? 0.0,
        'quantity': data['quantity'] ?? 1,
        'imageUrl': data['imageUrl'] ?? '',
        'subtitle': data['subtitle'] ?? '',
        'meta': data, // keep raw info if needed
      };
    }).toList();

    // 2. Build order data
    final now = FieldValue.serverTimestamp();
    final orderData = {
      'userId': userId,
      'userEmail': user.email,
      'items': items,
      'total': total,
      'paymentMethod': paymentMethod,
      'status': 'pending', // ✅ initially pending
      'transactionId': transactionId ??
          'SIM-${DateTime.now().millisecondsSinceEpoch}', // default sim ID
      'createdAt': now,
      'updatedAt': now,
    };

    // 3. Create order doc
    final orderRef = await _db.collection('orders').add(orderData);

    // 4. Clear cart
    final batch = _db.batch();
    for (final doc in cartSnap.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();

    return orderRef.id;
  }

  /// Admin: update order status
  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _db.collection('orders').doc(orderId).update({
      'status': newStatus,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get user orders (for MyOrders page)
  Stream<QuerySnapshot<Map<String, dynamic>>> getUserOrders(String userId) {
    return _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// ✅ Get all orders (for Admin panel) but only if current user is admin
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllOrders() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Not signed in');
    }

    // 👇 change this to your real admin email
    const adminEmail = "admin@gmail.com";

    if (user.email != adminEmail) {
      throw Exception("Not authorized: only admin can view all orders.");
    }

    return _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
