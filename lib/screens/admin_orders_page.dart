import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminOrdersPage extends StatelessWidget {
  const AdminOrdersPage({super.key});

  static const List<String> kStatuses = [
    'pending',
    'processing',
    'shipped',
    'delivered',
    'cancelled',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Orders (Admin)')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('orders').snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Error: ${snap.error}'));
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No orders yet'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final d = docs[i];
              final data = d.data();
              final orderId = d.id;
              final email = (data['userEmail'] ?? '') as String;
              final subtotal = (data['total'] ?? 0).toString();
              final status = (data['status'] ?? 'pending') as String;

              final ts = data['createdAt'];
              DateTime? placed;
              if (ts is Timestamp) placed = ts.toDate();

              final items = (data['items'] as List<dynamic>? ?? [])
                  .cast<Map<String, dynamic>>();

              return Material(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      builder: (_) => _OrderDetailSheet(
                        orderId: orderId,
                        data: data,
                        onChangeStatus: (newStatus) async {
                          await d.reference.update({
                            'status': newStatus,
                            'updatedAt': FieldValue.serverTimestamp(),
                          });
                        },
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(14.0),
                    child: Row(
                      children: [
                        const Icon(Icons.receipt_long, size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Order $orderId',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              Text(
                                '${items.length} item(s) • ${placed != null ? _fmt(placed) : '-'} \n$email',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('₹$subtotal',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            _StatusChip(status: status),
                          ],
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  static String _fmt(DateTime dt) {
    final d = dt.day.toString().padLeft(2, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final y = dt.year.toString();
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$d/$m/$y $hh:$mm';
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color _bg(BuildContext context) {
    switch (status) {
      case 'processing':
        return Colors.blue.shade100;
      case 'shipped':
        return Colors.deepPurple.shade100;
      case 'delivered':
        return Colors.green.shade100;
      case 'cancelled':
        return Colors.red.shade100;
      default:
        return Colors.orange.shade100; // pending
    }
  }

  Color _fg(BuildContext context) {
    switch (status) {
      case 'processing':
        return Colors.blue.shade900;
      case 'shipped':
        return Colors.deepPurple.shade900;
      case 'delivered':
        return Colors.green.shade900;
      case 'cancelled':
        return Colors.red.shade900;
      default:
        return Colors.orange.shade900;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: _bg(context), borderRadius: BorderRadius.circular(20)),
      child: Text(status.toUpperCase(),
          style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w700, color: _fg(context))),
    );
  }
}

class _OrderDetailSheet extends StatefulWidget {
  final String orderId;
  final Map<String, dynamic> data;
  final Future<void> Function(String newStatus)
      onChangeStatus; // ✅ updated type

  const _OrderDetailSheet({
    required this.orderId,
    required this.data,
    required this.onChangeStatus,
  });

  @override
  State<_OrderDetailSheet> createState() => _OrderDetailSheetState();
}

class _OrderDetailSheetState extends State<_OrderDetailSheet> {
  late String _status = (widget.data['status'] ?? 'pending') as String;

  @override
  Widget build(BuildContext context) {
    final items = (widget.data['items'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final pm = (widget.data['paymentMethod'] ?? '') as String;
    final tx = (widget.data['transactionId'] ?? '') as String;
    final subtotal = widget.data['total'];

    return Padding(
      padding: MediaQuery.of(context).viewInsets,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                      child: Text('Order ${widget.orderId}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16))),
                  DropdownButton<String>(
                    value: _status,
                    items: AdminOrdersPage.kStatuses
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (val) async {
                      if (val == null) return;
                      setState(() => _status = val);
                      await widget.onChangeStatus(val); // ✅ now valid
                    },
                  ),
                ],
              ),
              const Divider(height: 24),
              const Text('Items:',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              ...items.map((it) {
                final name = (it['name'] ?? '') as String;
                final qty = (it['qty'] ?? it['quantity'] ?? 0).toString();
                final price = (it['price'] ?? 0).toString();
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Expanded(child: Text(name)),
                      Text('× $qty'),
                      const SizedBox(width: 12),
                      Text('₹$price'),
                    ],
                  ),
                );
              }),
              const Divider(height: 24),
              Text('Payment method: $pm'),
              if (tx.isNotEmpty) Text('Transaction id: $tx'),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  Text('₹$subtotal',
                      style: const TextStyle(fontWeight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
