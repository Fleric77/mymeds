// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/my_orders_page.dart';
import 'screens/admin_orders_page.dart';
import 'utils/theme_manager.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // init theme pref from Firestore (swallows errors)
  await ThemeManager.initFromFirestore();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ThemeManager.isDark,
      builder: (context, isDark, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          title: 'My Meds',
          theme: ThemeData(
            brightness: Brightness.light,
            primarySwatch: Colors.blue,
            primaryColor: const Color(0xFF2D6A9E),
            scaffoldBackgroundColor: Colors.grey[100],
            fontFamily: 'Inter',
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              elevation: 0.5,
              iconTheme: IconThemeData(color: Color(0xFF333333)),
              titleTextStyle: TextStyle(
                color: Color(0xFF333333),
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A9E),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            primarySwatch: Colors.blue,
            fontFamily: 'Inter',
            scaffoldBackgroundColor: Colors.grey[900],
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF111111),
              elevation: 0.5,
              iconTheme: IconThemeData(color: Colors.white70),
              titleTextStyle: TextStyle(
                color: Colors.white70,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                fontFamily: 'Inter',
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2D6A9E),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
          themeMode: isDark ? ThemeMode.dark : ThemeMode.light,

          // Start with SplashScreen
          home: const SplashScreen(),

          // ✅ Added named routes
          routes: {
            '/myOrders': (_) => const MyOrdersPage(),
            '/adminOrders': (_) => const AdminOrdersPage(),
          },
        );
      },
    );
  }
}
