// lib/screens/main_screen.dart
import 'package:flutter/material.dart';
import 'home_page.dart';
import 'categories_page.dart';
import 'my_orders_page.dart';
import 'profile_page.dart';
import 'auth_gate.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Keep pages and bottom nav items in-sync (4 items)
  static final List<Widget> _pages = <Widget>[
    const HomePage(),
    const CategoriesPage(categoryName: 'All Categories'),
    const MyOrdersPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    // Protect Orders and Profile (indices 2 and 3)
    final protectedIndices = <int>[2, 3];

    if (FirebaseAuth.instance.currentUser == null &&
        protectedIndices.contains(index)) {
      // open auth gate (modal)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AuthGate(isModal: true)),
      );
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // show the selected page
      body: Center(child: _pages.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_outlined),
            activeIcon: Icon(Icons.grid_view_rounded),
            label: 'Categories',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping_outlined),
            activeIcon: Icon(Icons.local_shipping),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        elevation: 6.0,
      ),
    );
  }
}
