// lib/utils/language_manager.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LanguageManager {
  // Notifier so UI can react to changes
  static final ValueNotifier<String> locale = ValueNotifier<String>('English');

  // Translations - extend keys as needed
  static final Map<String, Map<String, String>> _translations = {
    'English': {
      'my_meds': 'My Meds',
      'search_hint': 'Search for medicines & products...',
      'profile': 'My Profile',
      'not_logged_in': 'You are not logged in.',
      'login_signup': 'Login / Sign Up',
      'user': 'User',
      'no_email': 'No Email',
      'personal_details': 'Personal Details',
      'payment_methods': 'Payment Methods',
      'saved_addresses': 'Saved Addresses',
      'language': 'Language',
      'contact_support': 'Contact Support',
      'feedback': 'Feedback',
      'privacy_terms': 'Privacy Policy / Terms & Services',
      'wishlist': 'Wishlist',
      'about': 'About Us / App Info',
      'theme': 'Theme (Light / Dark)',
      'please_login': 'Please login to manage this.',
      'no_payment_methods': 'No payment methods added.',
      'no_addresses': 'No saved addresses.',
      'add_payment': 'Add Payment Method',
      'card_number': 'Card number',
      'enter_number': 'Enter number',
      'name_on_card': 'Name on card',
      'add': 'Add',
      'save': 'Save',
      'saved': 'Saved',
      'full_name': 'Full name',
      'enter_name': 'Enter name',
      'phone': 'Phone',
      'language_saved': 'Language saved',
      'support_sent': 'Support request submitted',
      'thanks_feedback': 'Thanks for your feedback',
      'your_feedback': 'Your feedback',
      'send': 'Send',
      'about_text': 'About our app...',
      'dark_mode': 'Dark Mode',
      'theme_saved': 'Theme saved',
      'delete_account': 'Delete Account',
      'delete_account_confirm':
          'This will permanently delete your account and data. Are you sure?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'account_deleted': 'Account deleted.',
      'reauth_required': 'Re-authentication required',
      'reauth_message':
          'For security, please re-login before deleting account.',
      'ok': 'OK',
    },
    'Hindi': {
      'my_meds': 'मेरी दवाइयाँ',
      'search_hint': 'दवाइयाँ और उत्पाद खोजें...',
      'profile': 'मेरा प्रोफ़ाइल',
      'not_logged_in': 'आप लॉग इन नहीं हैं।',
      'login_signup': 'लॉगिन / साइन अप',
      'user': 'उपयोगकर्ता',
      'no_email': 'ईमेल उपलब्ध नहीं',
      'personal_details': 'व्यक्तिगत विवरण',
      'payment_methods': 'भुगतान विधियाँ',
      'saved_addresses': 'सहेजे गए पते',
      'language': 'भाषा',
      'contact_support': 'संपर्क सहायता',
      'feedback': 'प्रतिक्रिया',
      'privacy_terms': 'गोपनीयता नीति / नियम और शर्तें',
      'wishlist': 'इच्छा-सूची',
      'about': 'हमारे बारे में',
      'theme': 'थीम (लाइट / डार्क)',
      'please_login': 'कृपया प्रबंधित करने के लिए लॉगिन करें।',
      'no_payment_methods': 'कोई भुगतान विधि नहीं जोड़ी गई।',
      'no_addresses': 'कोई पता सहेजा नहीं गया।',
      'add_payment': 'भुगतान विधि जोड़ें',
      'card_number': 'कार्ड नंबर',
      'enter_number': 'नंबर दर्ज करें',
      'name_on_card': 'कार्ड पर नाम',
      'add': 'जोड़ें',
      'save': 'सहेजें',
      'saved': 'सहेजा गया',
      'full_name': 'पूरा नाम',
      'enter_name': 'नाम दर्ज करें',
      'phone': 'फ़ोन',
      'language_saved': 'भाषा सहेजी गई',
      'support_sent': 'सहायता अनुरोध भेजा गया',
      'thanks_feedback': 'आपकी प्रतिक्रिया के लिए धन्यवाद',
      'your_feedback': 'आपकी प्रतिक्रिया',
      'send': 'भेजें',
      'about_text': 'हमारे ऐप के बारे में...',
      'dark_mode': 'डार्क मोड',
      'theme_saved': 'थीम सहेजी गई',
      'delete_account': 'खाता हटाएं',
      'delete_account_confirm':
          'यह आपके खाते और डेटा को स्थायी रूप से हटा देगा। क्या आप सुनिश्चित हैं?',
      'cancel': 'रद्द करें',
      'delete': 'हटाएं',
      'account_deleted': 'खाता हटा दिया गया।',
      'reauth_required': 'पुनः प्रमाणीकरण आवश्यक है',
      'reauth_message':
          'सुरक्षा के लिए, कृपया खाते को हटाने से पहले फिर से लॉगिन करें।',
      'ok': 'ठीक है',
    },
  };

  /// Safe translate: returns key if translation missing (so missing keys are visible)
  static String translate(String key) {
    final lang = locale.value;
    final map = _translations[lang] ?? _translations['English']!;
    return map[key] ?? key;
  }

  /// Initialize from Firestore if user logged in.
  static Future<void> initFromFirestore() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final prefs = doc.data()?['preferences'] as Map<String, dynamic>?;
      final language = prefs?['language'] as String? ?? 'English';
      locale.value = language;
    } catch (e) {
      // ignore errors (e.g., permission denied) during init
      // debugPrint('Language init failed: $e');
    }
  }

  /// Save selected language to Firestore (and update notifier)
  static Future<void> saveToFirestore(String language) async {
    try {
      locale.value = language;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'preferences': {'language': language}
      }, SetOptions(merge: true));
    } catch (e) {
      // ignore save errors for now
      // debugPrint('Language save failed: $e');
    }
  }
}
