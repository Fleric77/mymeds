// lib/screens/checkout_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/order_service.dart';
import 'login_screen.dart';
import 'upi_simulator_page.dart';

class CheckoutPage extends StatefulWidget {
  final String selectedMethod;
  final double amount;

  const CheckoutPage(
      {super.key, required this.selectedMethod, required this.amount});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _method = '';
  bool _processing = false;
  final OrderService _orderService = OrderService();

  @override
  void initState() {
    super.initState();
    _method = widget.selectedMethod;
  }

  Widget _buildSummaryRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
              child: Text(label, style: TextStyle(color: Colors.grey[700]))),
          Text(value,
              style: TextStyle(
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
        ],
      ),
    );
  }

  bool _requireLogin() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to continue with payment')),
      );
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
      return false;
    }
    return true;
  }

  Future<void> _handlePayNow() async {
    if (_processing) return;
    if (_method.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method')),
      );
      return;
    }

    if (!_requireLogin()) return;

    setState(() => _processing = true);

    try {
      if (_method == 'UPI') {
        // Navigate to UPI simulator page.
        // The simulator itself will create the order and handle navigation (as implemented).
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UpiSimulatorPage(amount: widget.amount),
          ),
        );

        // After returning from simulator, just show a brief message.
        // (Simulator usually navigates to orders or replacement route.)
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Returned from UPI simulator')),
        );

        // Optionally you could navigate somewhere here if needed, but simulator handles it.
      } else if (_method == 'Card' || _method == 'Wallet') {
        // Simulate card/wallet payment with confirmation dialog
        final confirmed = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Simulate Payment'),
                content: Text(
                    'This will simulate a $_method payment of ₹${widget.amount.toStringAsFixed(2)}. Continue?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Cancel')),
                  ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Simulate')),
                ],
              ),
            ) ??
            false;

        if (!confirmed) {
          // user cancelled
          setState(() => _processing = false);
          return;
        }

        // Create order immediately as "paid" since this is a simulation
        await _orderService.createOrderFromCart(
          total: widget.amount,
          paymentMethod: _method,
          transactionId: 'SIM-${DateTime.now().millisecondsSinceEpoch}',
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment simulated — Order placed')),
        );

        // Return to app main screen (or pop to root)
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else if (_method == 'COD') {
        // Create order with status 'pending' for COD
        await _orderService.createOrderFromCart(
          total: widget.amount,
          paymentMethod: 'COD',
          transactionId: 'COD-${DateTime.now().millisecondsSinceEpoch}',
        );

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Order placed (Cash on Delivery)')),
        );

        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        // Fallback (should not occur)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unsupported payment method')),
        );
      }
    } catch (e) {
      // Show error
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Payment failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).primaryColor;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: primary,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Order summary card
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Bill Summary',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      _buildSummaryRow(
                          'MRP', '₹${widget.amount.toStringAsFixed(2)}'),
                      _buildSummaryRow('Discount', '- ₹0.00'),
                      const Divider(),
                      _buildSummaryRow('Amount to be paid',
                          '₹${widget.amount.toStringAsFixed(2)}',
                          isBold: true),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Payment options (shows selected)
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                  child: Column(
                    children: [
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text('Payment Method',
                              style: TextStyle(fontWeight: FontWeight.bold))),
                      RadioListTile<String>(
                        value: 'UPI',
                        groupValue: _method,
                        onChanged: (v) =>
                            setState(() => _method = v ?? _method),
                        title: const Text('UPI'),
                        subtitle: const Text('Fast and secure UPI payment'),
                      ),
                      RadioListTile<String>(
                        value: 'Card',
                        groupValue: _method,
                        onChanged: (v) =>
                            setState(() => _method = v ?? _method),
                        title: const Text('Credit / Debit card'),
                      ),
                      RadioListTile<String>(
                        value: 'Wallet',
                        groupValue: _method,
                        onChanged: (v) =>
                            setState(() => _method = v ?? _method),
                        title: const Text('Wallets'),
                      ),
                      RadioListTile<String>(
                        value: 'COD',
                        groupValue: _method,
                        onChanged: (v) =>
                            setState(() => _method = v ?? _method),
                        title: const Text('Cash on Delivery'),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Proceed button area
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: _processing ? null : _handlePayNow,
                      child: _processing
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Pay Now',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),
              Text(
                'By placing the order you agree to our Terms & Privacy Policy.',
                style: TextStyle(color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
