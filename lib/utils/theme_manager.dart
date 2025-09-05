// lib/utils/theme_manager.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ThemeManager {
  static final ValueNotifier<bool> isDark = ValueNotifier<bool>(false);

  /// Load user's theme preference from Firestore if available.
  static Future<void> initFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final prefs = doc.data()?['preferences'] as Map<String, dynamic>?;
      final theme = prefs?['theme'] as String? ?? 'light';
      isDark.value = (theme == 'dark');
    } catch (e) {
      // ignore permission or network errors
    }
  }

  /// Save theme preference and apply immediately
  static Future<void> saveToFirestore(bool dark) async {
    try {
      isDark.value = dark;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'preferences': {'theme': dark ? 'dark' : 'light'}
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore write errors for now
    }
  }
}
