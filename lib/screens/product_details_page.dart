// lib/screens/product_details_page.dart
import 'package:flutter/material.dart';
import '../services/cart_service.dart';
import 'cart_page.dart';
import 'login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductDetailsPage extends StatefulWidget {
  final Map<String, String?> product;
  final String? docId;

  const ProductDetailsPage({super.key, required this.product, this.docId});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  final CartService _cartService = CartService();
  int _selectedQuantity = 1;
  bool _isAdding = false;

  String _get(String key) => widget.product[key] ?? '';

  Future<void> _addToCart({int qty = 1}) async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to use the cart')));
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    setState(() => _isAdding = true);
    final productMap = Map<String, dynamic>.from(widget.product);
    try {
      await _cartService.updateCartItem(productMap, qty, docId: widget.docId);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Added to cart')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to add to cart: $e')));
      }
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _buyNow() async {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please login to buy')));
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    await _addToCart(qty: _selectedQuantity);
    if (context.mounted) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const CartPage()));
    }
  }

  Widget _rowTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 120,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text(value.isEmpty ? '—' : value)),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = _get('imageUrl');
    final name = _get('name');
    final subtitle = _get('subtitle');
    final price = _get('price');

    final contents = _get('contents');
    final mfg = _get('mfg');
    final exp = _get('exp');
    final sideEffects = _get('sideEffects');
    final description = _get('description');
    final uses = _get('uses');

    return Scaffold(
      appBar: AppBar(title: Text(name.isEmpty ? 'Product' : name)),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // image - constrained so it doesn't blow up
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 340, maxWidth: 900),
              child: AspectRatio(
                aspectRatio: 1.6,
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.contain,
                        errorBuilder: (c, e, s) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                              child: Icon(Icons.broken_image, size: 60)),
                        );
                      })
                    : Container(
                        color: Colors.grey[200],
                        child: const Center(
                            child: Icon(Icons.image_not_supported_outlined,
                                size: 60)),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(name,
              style:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(color: Colors.grey)),
          ],
          const SizedBox(height: 10),
          Text(price,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87)),
          const Divider(height: 20),

          // details block
          Card(
            elevation: 0,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(children: [
                _rowTile('Contents:', contents),
                _rowTile('MFG:', mfg),
                _rowTile('EXP:', exp),
                _rowTile('Side Effects:', sideEffects),
                _rowTile('Uses:', uses),
                const SizedBox(height: 6),
                Align(
                    alignment: Alignment.centerLeft,
                    child: const Text('Description:',
                        style: TextStyle(fontWeight: FontWeight.bold))),
                const SizedBox(height: 6),
                Text(description.isEmpty ? '—' : description),
              ]),
            ),
          ),

          const SizedBox(height: 12),

          // quantity selector and totals
          Row(children: [
            const Text('Quantity:',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: _selectedQuantity > 1
                        ? () => setState(() => _selectedQuantity--)
                        : null,
                  ),
                  Text('$_selectedQuantity',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () => setState(() => _selectedQuantity++),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Builder(builder: (context) {
              double priceNum = 0.0;
              try {
                final s = price.replaceAll(RegExp(r'[^\d.]'), '');
                priceNum = double.tryParse(s) ?? 0.0;
              } catch (_) {}
              final total = (priceNum * _selectedQuantity).toStringAsFixed(2);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text('Total', style: TextStyle(color: Colors.grey)),
                  Text('₹$total',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              );
            }),
          ]),

          const SizedBox(height: 18),

          // action buttons
          Row(children: [
            Expanded(
              child: ElevatedButton(
                onPressed: _isAdding ? null : () async => await _buyNow(),
                child: _isAdding
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Buy Now'),
              ),
            ),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: _isAdding
                  ? null
                  : () async => await _addToCart(qty: _selectedQuantity),
              child: _isAdding
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Add to Cart'),
            ),
          ]),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
