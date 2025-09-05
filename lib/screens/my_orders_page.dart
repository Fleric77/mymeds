// lib/screens/my_orders_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/order_service.dart';
import 'login_screen.dart';

class MyOrdersPage extends StatefulWidget {
  const MyOrdersPage({super.key});

  static const routeName = '/myOrders';

  @override
  State<MyOrdersPage> createState() => _MyOrdersPageState();
}

class _MyOrdersPageState extends State<MyOrdersPage> {
  User? get _user => FirebaseAuth.instance.currentUser;
  final OrderService _orderService = OrderService();

  // 👇 change this to your admin email
  static const adminEmail = "admin@gmail.com";

  bool get isAdmin => _user?.email?.toLowerCase() == adminEmail.toLowerCase();

  Stream<QuerySnapshot<Map<String, dynamic>>>? _ordersStream() {
    if (_user == null) return null;

    if (isAdmin) {
      // Admin → show all orders
      return _orderService.getAllOrders();
    } else {
      // Normal user → only their orders
      return _orderService.getUserOrders(_user!.uid);
    }
  }

  String _formatDate(dynamic ts) {
    try {
      DateTime dt;
      if (ts is Timestamp) {
        dt = ts.toDate();
      } else if (ts is DateTime) {
        dt = ts;
      } else {
        return 'Unknown';
      }
      final local = dt.toLocal();
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      return '${local.day}/${local.month}/${local.year} $hh:$mm';
    } catch (_) {
      return 'Unknown';
    }
  }

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'paid':
      case 'completed':
      case 'delivered':
        return Colors.green;
      case 'shipped':
      case 'processing':
        return Colors.blue;
      case 'pending':
        return Colors.orange;
      case 'cancelled':
      case 'canceled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Future<void> _showOrderDetails(BuildContext context,
      QueryDocumentSnapshot<Map<String, dynamic>> doc) async {
    final data = doc.data();
    final items =
        (data['items'] is List) ? List.from(data['items']) : <dynamic>[];
    final totalRaw = data['total'];
    final double total = (totalRaw is num)
        ? totalRaw.toDouble()
        : double.tryParse('$totalRaw') ?? 0.0;
    final status = (data['status'] ?? 'pending').toString();
    final paymentMethod = (data['paymentMethod'] ?? '').toString();
    final txn = (data['transactionId'] ?? '').toString();
    final createdAt = data['createdAt'];

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (bc) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Wrap(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Order ${doc.id.substring(0, 8)}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Chip(
                      label: Text(status.toUpperCase()),
                      backgroundColor: _statusColor(status).withOpacity(0.12),
                      avatar: Icon(Icons.local_shipping,
                          size: 18, color: _statusColor(status)),
                    )
                  ],
                ),
                const SizedBox(height: 12),
                Text('Placed: ${_formatDate(createdAt)}',
                    style: TextStyle(color: Colors.grey[700])),
                const Divider(),
                const SizedBox(height: 8),
                const Text('Items:',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...items.map((it) {
                  final name = (it is Map && it['name'] != null)
                      ? it['name'].toString()
                      : (it.toString());
                  final qty = (it is Map && it['quantity'] != null)
                      ? '${it['quantity']}'
                      : '1';
                  final priceRaw =
                      (it is Map && it['price'] != null) ? it['price'] : '';
                  final priceStr = priceRaw.toString();
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Qty: $qty'),
                    trailing: Text(priceStr),
                  );
                }).toList(),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Payment method:',
                        style: TextStyle(color: Colors.grey)),
                    Text(paymentMethod),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Transaction id:',
                        style: TextStyle(color: Colors.grey)),
                    Expanded(
                        child: Text(txn,
                            textAlign: TextAlign.right,
                            overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('₹${total.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),

                // 👇 only admins can update order status
                if (isAdmin) ...[
                  const Text("Update Status:",
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final s in ['pending', 'processing', 'delivered'])
                        ElevatedButton(
                          onPressed: () async {
                            await _orderService.updateOrderStatus(doc.id, s);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _statusColor(s),
                          ),
                          child: Text(s.toUpperCase()),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const SizedBox(
                    width: double.infinity,
                    child: Center(child: Text('Close')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final stream = _ordersStream();

    if (_user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Orders')),
        body: Center(
          child: ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
            child: const Text('Login to view orders'),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isAdmin ? 'All Orders (Admin)' : 'My Orders'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Failed to load orders: ${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No orders found'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data();
              final totalRaw = data['total'];
              final double total = (totalRaw is num)
                  ? totalRaw.toDouble()
                  : double.tryParse('$totalRaw') ?? 0.0;
              final createdAt = data['createdAt'];
              final status = (data['status'] ?? 'pending').toString();
              final title = 'Order ${doc.id.substring(0, 8)}';

              return Card(
                child: ListTile(
                  leading:
                      Icon(Icons.receipt_long, color: _statusColor(status)),
                  title: Text(title),
                  subtitle: Text(
                      '${_formatDate(createdAt)} • Status: ${status.toUpperCase()}'),
                  trailing: Text('₹${total.toStringAsFixed(2)}'),
                  onTap: () => _showOrderDetails(context, doc),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
