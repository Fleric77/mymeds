// lib/screens/cart_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/cart_service.dart';
import 'checkout_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final CartService _cartService = CartService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _cartService.getCartStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
                child: Text('Your cart is empty.',
                    style: TextStyle(fontSize: 18, color: Colors.grey)));
          }

          double totalPrice = 0;
          for (var doc in docs) {
            final data = doc.data();
            final priceString = (data['price'] as String?)
                    ?.replaceAll('₹', '')
                    .replaceAll(',', '') ??
                '0';
            final price = double.tryParse(priceString) ?? 0.0;
            final qty = (data['quantity'] is int)
                ? data['quantity'] as int
                : int.tryParse('${data['quantity']}') ?? 0;
            totalPrice += price * qty;
          }

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: docs.map((document) {
                    final data = document.data();
                    final int quantity = (data['quantity'] is int)
                        ? data['quantity'] as int
                        : int.tryParse('${data['quantity']}') ?? 0;
                    final docId = document.id;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            // image
                            if (data['imageUrl'] != null &&
                                data['imageUrl'] is String &&
                                (data['imageUrl'] as String).isNotEmpty)
                              Image.network(
                                data['imageUrl'] as String,
                                width: 60,
                                height: 60,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons
                                            .image_not_supported_outlined)),
                              )
                            else
                              Container(
                                  width: 60,
                                  height: 60,
                                  color: Colors.grey[200]),

                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['name'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 4),
                                    Text(data['price'] ?? '',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16)),
                                  ]),
                            ),
                            Container(
                              decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8)),
                              child: Row(children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  onPressed: () async {
                                    final newQty = quantity - 1;
                                    try {
                                      await _cartService.updateCartItem(
                                          Map<String, dynamic>.from(data),
                                          newQty,
                                          docId: docId);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  'Failed to update cart: $e')));
                                    }
                                  },
                                ),
                                Text('$quantity',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  onPressed: () async {
                                    final newQty = quantity + 1;
                                    try {
                                      await _cartService.updateCartItem(
                                          Map<String, dynamic>.from(data),
                                          newQty,
                                          docId: docId);
                                    } catch (e) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(SnackBar(
                                              content: Text(
                                                  'Failed to update cart: $e')));
                                    }
                                  },
                                ),
                              ]),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              // bottom area: total + proceed
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06), blurRadius: 6)
                    ]),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Price:',
                              style: TextStyle(color: Colors.grey)),
                          Text('₹${totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.bold)),
                        ]),
                    ElevatedButton(
                      onPressed: () {
                        // open checkout bottom sheet
                        _openCheckoutSheet(context, totalPrice);
                      },
                      child: const Text('Proceed to Checkout'),
                    )
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  void _openCheckoutSheet(BuildContext context, double total) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String selected = 'UPI';
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.45,
          minChildSize: 0.25,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(16))),
              child: StatefulBuilder(builder: (context, setStateSB) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                              color: Colors.grey[300],
                              borderRadius: BorderRadius.circular(4))),
                      const SizedBox(height: 12),
                      const Text('Proceed to Pay',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            RadioListTile<String>(
                              value: 'UPI',
                              groupValue: selected,
                              onChanged: (v) => setStateSB(() => selected = v!),
                              title: const Text('UPI'),
                              secondary: const Icon(
                                  Icons.account_balance_wallet_outlined),
                            ),
                            RadioListTile<String>(
                              value: 'Card',
                              groupValue: selected,
                              onChanged: (v) => setStateSB(() => selected = v!),
                              title: const Text('Credit/Debit Card'),
                              secondary: const Icon(Icons.credit_card_outlined),
                            ),
                            RadioListTile<String>(
                              value: 'Wallet',
                              groupValue: selected,
                              onChanged: (v) => setStateSB(() => selected = v!),
                              title: const Text('Wallets'),
                              secondary:
                                  const Icon(Icons.account_balance_wallet),
                            ),
                            RadioListTile<String>(
                              value: 'COD',
                              groupValue: selected,
                              onChanged: (v) => setStateSB(() => selected = v!),
                              title: const Text('Cash on Delivery'),
                              secondary:
                                  const Icon(Icons.local_shipping_outlined),
                            ),
                            const SizedBox(height: 18),
                            Text('Total to pay: ₹${total.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pop(); // close sheet
                              // For now we navigate to a placeholder CheckoutPage - implement real flow later
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => CheckoutPage(
                                      selectedMethod: selected, amount: total),
                                ),
                              );
                            },
                            child: const Text('Proceed'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: const Text('Cancel')),
                      ])
                    ],
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }
}
