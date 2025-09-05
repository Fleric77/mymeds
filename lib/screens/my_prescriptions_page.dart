import 'package:flutter/material.dart';

class MyPrescriptionsPage extends StatelessWidget {
  const MyPrescriptionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Prescriptions')),
      body: const Center(child: Text('This is the My Prescriptions Page')),
    );
  }
}
