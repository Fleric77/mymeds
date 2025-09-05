// lib/screens/profile_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import 'auth_gate.dart';
import 'main_screen.dart';
import '../utils/theme_manager.dart';
import 'package:flutter/services.dart'; // for Clipboard

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: _currentUser == null ? _buildLoggedOutView() : _buildLoggedInView(),
    );
  }

  Widget _buildLoggedOutView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('You are not logged in.',
              style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AuthGate(isModal: true),
                ),
              );
            },
            child: const Text('Login / Sign Up'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoggedInView() {
    final uid = _currentUser!.uid;

    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
      builder: (context, snapshot) {
        // loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        String displayName = _currentUser?.displayName ?? 'User';
        String email = _currentUser?.email ?? 'No Email';

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data();
          if (data != null) {
            final nameFromDb = data['name'];
            final emailFromDb = data['email'];
            if (nameFromDb is String && nameFromDb.trim().isNotEmpty) {
              displayName = nameFromDb.trim();
            }
            if (emailFromDb is String && emailFromDb.trim().isNotEmpty) {
              email = emailFromDb.trim();
            }
          }
        }

        return _buildProfileContent(displayName, email);
      },
    );
  }

  Widget _buildProfileContent(String name, String email) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: const Color(0xFF2D6A9E),
                child: const Icon(Icons.person, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              Text(email,
                  style: const TextStyle(fontSize: 16, color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Options list - removed Language, Wishlist, Feedback
        _buildProfileOption(context, 'Personal Details', Icons.person_outline,
            () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PersonalDetailsPage()),
          );
        }),
        _buildProfileOption(
            context, 'Payment Methods', Icons.credit_card_outlined, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PaymentMethodsPage()),
          );
        }),
        _buildProfileOption(
            context, 'Saved Addresses', Icons.location_on_outlined, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SavedAddressesPage()),
          );
        }),
        _buildProfileOption(
            context, 'Contact Support', Icons.headset_mic_outlined, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ContactSupportPage()),
          );
        }),
        _buildProfileOption(
            context, 'Privacy Policy / Terms', Icons.shield_outlined, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()),
          );
        }),
        _buildProfileOption(context, 'About / App info', Icons.info_outline,
            () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AboutPage()),
          );
        }),
        _buildProfileOption(
            context, 'Theme (Light/Dark)', Icons.color_lens_outlined, () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ThemePage()),
          );
        }),
        const Divider(height: 32),

        // Logout
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Logout', style: TextStyle(color: Colors.red)),
          onTap: () async {
            await AuthService().signOut();
            if (context.mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => const MainScreen()),
                (route) => false,
              );
            }
          },
        ),

        // Delete Account
        ListTile(
          leading: const Icon(Icons.delete_outline, color: Colors.redAccent),
          title: const Text('Delete Account',
              style: TextStyle(color: Colors.redAccent)),
          onTap: _confirmDeleteAccount,
        ),
      ],
    );
  }

  Widget _buildProfileOption(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return Card(
      elevation: 0.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[700]),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete account'),
            content: const Text(
                'Are you sure you want to permanently delete your account? This action cannot be undone. You may need to re-login before deletion (for security).'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text('Delete',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await user.delete();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Account deleted successfully.')));
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainScreen()),
          (route) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (context.mounted) {
        final message = e.code == 'requires-recent-login'
            ? 'To delete your account you must re-login. Please sign in again and try.'
            : 'Failed to delete account: ${e.message ?? e.code}';
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Could not delete account'),
            content: Text(message),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK')),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to delete account: $e'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('OK')),
            ],
          ),
        );
      }
    }
  }
}

/// -----------------
/// Placeholder pages for profile options
/// Replace these placeholders with your real implementation screens.
/// -----------------

class PersonalDetailsPage extends StatefulWidget {
  const PersonalDetailsPage({super.key});
  @override
  State<PersonalDetailsPage> createState() => _PersonalDetailsPageState();
}

class _PersonalDetailsPageState extends State<PersonalDetailsPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  String _gender = 'Prefer not to say';
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadFromFirestore();
  }

  Future<void> _loadFromFirestore() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data();
    if (data != null) {
      _nameCtrl.text = (data['name'] as String?) ?? '';
      _phoneCtrl.text = (data['phone'] as String?) ?? '';
      _gender = (data['gender'] as String?) ?? _gender;
      if (mounted) setState(() {});
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _loading = true);
    try {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': _nameCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'gender': _gender,
      }, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(labelText: 'Full name'),
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      decoration: const InputDecoration(labelText: 'Phone'),
                      keyboardType: TextInputType.phone,
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Enter phone' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _gender,
                      items: const [
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(
                            value: 'Female', child: Text('Female')),
                        DropdownMenuItem(
                            value: 'Prefer not to say',
                            child: Text('Prefer not to say')),
                      ],
                      onChanged: (v) => setState(() => _gender = v ?? _gender),
                      decoration: const InputDecoration(labelText: 'Gender'),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(onPressed: _save, child: const Text('Save')),
                  ],
                ),
              ),
      ),
    );
  }
}

class PaymentMethodsPage extends StatefulWidget {
  const PaymentMethodsPage({super.key});
  @override
  State<PaymentMethodsPage> createState() => _PaymentMethodsPageState();
}

class _PaymentMethodsPageState extends State<PaymentMethodsPage> {
  final _formKey = GlobalKey<FormState>();
  final _cardName = TextEditingController();
  final _cardLast4 = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _cardName.dispose();
    _cardLast4.dispose();
    super.dispose();
  }

  Future<void> _savePayment() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _loading = true);
    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('paymentMethods');
      await ref.add({
        'nameOnCard': _cardName.text.trim(),
        'last4': _cardLast4.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment method saved')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Methods')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _cardName,
                      decoration:
                          const InputDecoration(labelText: 'Name on card'),
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Enter name' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cardLast4,
                      decoration:
                          const InputDecoration(labelText: 'Last 4 digits'),
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if ((v ?? '').trim().length != 4)
                          return 'Enter last 4 digits';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: _savePayment, child: const Text('Save')),
                  ],
                ),
              ),
      ),
    );
  }
}

class SavedAddressesPage extends StatefulWidget {
  const SavedAddressesPage({super.key});
  @override
  State<SavedAddressesPage> createState() => _SavedAddressesPageState();
}

class _SavedAddressesPageState extends State<SavedAddressesPage> {
  final _formKey = GlobalKey<FormState>();
  final _label = TextEditingController();
  final _address = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _label.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please login')));
      return;
    }
    setState(() => _loading = true);
    try {
      final ref = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses');
      await ref.add({
        'label': _label.text.trim(),
        'address': _address.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Address saved')));
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Saved Addresses')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _label,
                      decoration:
                          const InputDecoration(labelText: 'Label (Home/Work)'),
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Enter label' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address,
                      decoration:
                          const InputDecoration(labelText: 'Full address'),
                      minLines: 2,
                      maxLines: 4,
                      validator: (v) =>
                          (v ?? '').trim().isEmpty ? 'Enter address' : null,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        onPressed: _saveAddress,
                        child: const Text('Save Address')),
                  ],
                ),
              ),
      ),
    );
  }
}

class ContactSupportPage extends StatelessWidget {
  const ContactSupportPage({super.key});

  static const _email = 'majorprojectapp2025@gmail.com';
  static const _phone = '+919409727758';

  Future<void> _copyToClipboard(BuildContext ctx, String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (ctx.mounted) {
      ScaffoldMessenger.of(ctx)
          .showSnackBar(const SnackBar(content: Text('Copied to clipboard')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact Support')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Need help?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.email_outlined),
              title: const Text('Email us'),
              subtitle: Text(_email),
              onTap: () => _copyToClipboard(context, _email),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () => _copyToClipboard(context, _email),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.phone_outlined),
              title: const Text('Call us'),
              subtitle: Text(_phone),
              onTap: () => _copyToClipboard(context, _phone),
              trailing: IconButton(
                icon: const Icon(Icons.copy),
                onPressed: () => _copyToClipboard(context, _phone),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
                'You can copy the email/phone and use your device to contact us.'),
          ],
        ),
      ),
    );
  }
}

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});
  @override
  Widget build(BuildContext context) {
    final sample = '''
Privacy Policy / Terms & Services

This is placeholder text. Replace with your real policy text.

1) We do not store sensitive payment details.
2) Personal data is stored in Firestore under users/{uid}.
3) Please consult local laws for privacy compliance.
''';
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(child: Text(sample)),
      ),
    );
  }
}

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About')),
      body: const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('About the app / company (replace with real content)'),
      ),
    );
  }
}

/// ThemePage - uses ThemeManager to persist choice (Firestore)
class ThemePage extends StatefulWidget {
  const ThemePage({super.key});
  @override
  State<ThemePage> createState() => _ThemePageState();
}

class _ThemePageState extends State<ThemePage> {
  bool _darkMode = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // read current value from ThemeManager
    _darkMode = ThemeManager.isDark.value;
    if (mounted)
      setState(() {
        _loading = false;
      });
  }

  Future<void> _save() async {
    await ThemeManager.saveToFirestore(_darkMode);
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Theme saved')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      // removed "const" here because AppBar/other children are not const
      return Scaffold(
        appBar: AppBar(title: Text('Theme')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Theme')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Appearance',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dark mode', style: TextStyle(fontSize: 16)),
                  Switch.adaptive(
                    value: _darkMode,
                    onChanged: (v) => setState(() => _darkMode = v),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('Toggle dark mode. Press Save to persist your choice.',
                  style: TextStyle(color: Colors.grey)),
              const Spacer(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(12.0),
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _save,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Save', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: _load,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                child: const Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
