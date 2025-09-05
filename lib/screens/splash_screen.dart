import 'package:flutter/material.dart';
import 'dart:async';
import 'main_screen.dart'; // This is your main screen with the bottom navigation

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // We will wait for 3 seconds on this screen, then navigate to the MainScreen.
    Timer(const Duration(seconds: 3), () {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Your Logo Icon
            const Icon(
              Icons.local_hospital_rounded,
              size: 120.0,
              color: Colors.teal,
            ),
            const SizedBox(height: 24),

            // Your App Name
            const Text(
              'My Meds',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),

            // Your Tagline
            const Text(
              'Caring For Your Future',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
