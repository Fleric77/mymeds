// lib/screens/upi_simulator_page.dart
import 'package:flutter/material.dart';
import '../services/order_service.dart';

class UpiSimulatorPage extends StatefulWidget {
  final double amount;
  final String? merchantUpi; // optional string to show in QR
  const UpiSimulatorPage({super.key, required this.amount, this.merchantUpi});

  @override
  State<UpiSimulatorPage> createState() => _UpiSimulatorPageState();
}

class _UpiSimulatorPageState extends State<UpiSimulatorPage> {
  bool _processing = false;
  final OrderService _orderService = OrderService();

  Future<void> _simulateSuccess() async {
    setState(() => _processing = true);
    try {
      // Create order & clear cart
      final orderId = await _orderService.createOrderFromCart(
        total: widget.amount,
        paymentMethod: 'UPI',
        transactionId: 'SIM-${DateTime.now().millisecondsSinceEpoch}',
      );

      if (!mounted) return;

      // Show confirmation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('✅ Payment successful — Order #$orderId placed')),
      );

      // Return success result to the caller (CheckoutPage or caller can act on this)
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to place order: $e')),
      );
      setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountText = widget.amount.toStringAsFixed(2);
    return Scaffold(
      appBar: AppBar(title: const Text('UPI Payment Simulator')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // QR Container
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 220,
                    height: 220,
                    child: Image.asset(
                      'assets/images/sample_upi_qr.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(child: Text('QR Placeholder')),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Pay ₹$amountText to ${widget.merchantUpi ?? "merchant"}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'This is a simulator.\nPress the button below to simulate a successful UPI payment.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Simulate button
            ElevatedButton(
              onPressed: _processing ? null : _simulateSuccess,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
              child: _processing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Simulate Payment Success'),
            ),

            const SizedBox(height: 12),

            // Cancel button
            TextButton(
              onPressed:
                  _processing ? null : () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}
