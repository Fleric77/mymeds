import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'main_screen.dart';

class AuthGate extends StatelessWidget {
  final bool isModal;
  const AuthGate({super.key, this.isModal = false});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If user is logged in
        if (snapshot.hasData) {
          // If this was presented as a modal, just pop the navigator.
          if (isModal) {
            // A slight delay to allow the UI to settle.
            Future.delayed(Duration.zero, () {
              Navigator.of(context).pop();
            });
            // Return an empty container while it's popping.
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          // If it's the main gate, go to MainScreen (though this case is less likely now).
          return const MainScreen();
        }

        // If user is not logged in, show the login screen.
        return const LoginScreen();
      },
    );
  }
}
