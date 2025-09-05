// lib/screens/categories_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cart_service.dart';
import 'login_screen.dart';
import 'product_details_page.dart';

class CategoriesPage extends StatefulWidget {
  /// If [categoryName] is null => show "All Categories" with products grouped.
  /// If non-null => show items for that category in a vertical list.
  const CategoriesPage({super.key, this.categoryName});

  final String? categoryName;

  @override
  State<CategoriesPage> createState() => _CategoriesPageState();
}

class _CategoriesPageState extends State<CategoriesPage> {
  final CartService _cartService = CartService();

  /// quantities keyed by normalized product name -> quantity
  final Map<String, int> _quantities = {};

  StreamSubscription? _cartSub;

  /// Health categories metadata (display name + local asset path)
  final List<Map<String, String>> _healthCategories = [
    {'name': 'Thyroid', 'asset': 'assets/images/Thyroid.jpg'},
    {'name': 'Consult Doctor', 'asset': 'assets/images/Consult Doctor.jpg'},
    {'name': 'Heart Care', 'asset': 'assets/images/Heart.jpg'},
    {'name': 'Bone Health', 'asset': 'assets/images/Bone Health.jpg'},
    {'name': 'Vitamins', 'asset': 'assets/images/Vitamins.jpg'},
    {'name': 'Diabetes', 'asset': 'assets/images/Diabetes.jpeg'},
    {
      'name': 'Fitness Supplements',
      'asset': 'assets/images/Fitness Supplements.jpg'
    },
    {
      'name': 'Hair & Skin Care',
      'asset': 'assets/images/Hair and Skin Care.jpg'
    },
  ];

  /// Local dataset for items; add your 13 products here (category -> list of items).
  final Map<String, List<Map<String, String>>> itemsByCategory = {
    'Thyroid': [
      {
        'name': 'Thyroid Support',
        'price': '₹499',
        'image': 'assets/images/thyroid_support.jpg'
      },
      {
        'name': 'Thyroid Tablets',
        'price': '₹399',
        'image': 'assets/images/thyroid_tablets.jpg'
      },
    ],
    'Consult Doctor': [
      {
        'name': 'Cardiologist',
        'price': '₹199',
        'availability': 'in 20 mins',
        'image': 'assets/images/cardiologist.jpg'
      },
      {
        'name': 'Neurologist',
        'price': '₹299',
        'availability': 'in 20 mins',
        'image': 'assets/images/neurologist.jpg'
      },
      {
        'name': 'Psychiatrist',
        'price': '₹399',
        'availability': 'in 20 mins',
        'image': 'assets/images/psychiatrist.jpg'
      },
      {
        'name': 'Orthopedic Surgeon',
        'price': '₹499',
        'availability': 'in 20 mins',
        'image': 'assets/images/orthopedic_surgeon.jpg'
      },
    ],
    'Heart Care': [
      {
        'name': 'Heart Care Syrup',
        'price': '₹299',
        'image': 'assets/images/heart_syrup.jpg'
      },
      {
        'name': 'Cardio Tablets',
        'price': '₹349',
        'image': 'assets/images/cardio_tablets.jpg'
      },
    ],
    'Bone Health': [
      {
        'name': 'Calcium + Vit D',
        'price': '₹250',
        'image': 'assets/images/calcium_vitd.jpg'
      },
    ],
    'Vitamins': [
      {
        'name': 'Multivitamin',
        'price': '₹199',
        'image': 'assets/images/multivitamin.jpg'
      },
    ],
    'Diabetes': [
      {
        'name': 'Diabetes Checker',
        'price': '₹1,200',
        'image': 'assets/images/diabetes_checker.jpg'
      },
      {
        'name': 'GlucoTabs',
        'price': '₹450',
        'image': 'assets/images/glucotabs.jpg'
      },
      {
        'name': 'Sugar Control Capsules',
        'price': '₹350',
        'image': 'assets/images/sugar_control_capsules.jpg'
      },
    ],
    'Fitness Supplements': [
      {
        'name': 'Protein Powder',
        'price': '₹999',
        'image': 'assets/images/protein_powder.jpg'
      },
    ],
    'Hair & Skin Care': [
      {
        'name': 'Dandruff Shampoo',
        'price': '₹350',
        'image': 'assets/images/dandruff_shampoo.jpg'
      },
      {
        'name': 'Skin Tone Lotion',
        'price': '₹499',
        'image': 'assets/images/skin_tone_lotion.jpg'
      },
      {
        'name': 'Hair Growth Serum',
        'price': '₹699',
        'image': 'assets/images/hair_growth_serum.jpg'
      },
    ],
  };

  @override
  void initState() {
    super.initState();
    // subscribe to cart stream to keep quantities in sync with Firestore
    _cartSub = _cartService.getCartStream().listen((snapshot) {
      final Map<String, int> fresh = {};
      for (var doc in snapshot.docs) {
        final data = (doc.data() as Map<String, dynamic>);
        final rawName = (data['name'] as String?) ?? doc.id;
        final normalized =
            (data['normalizedName'] as String?) ?? rawName.trim().toLowerCase();

        final qtyRaw = data['quantity'];
        int qty;
        if (qtyRaw is int) {
          qty = qtyRaw;
        } else {
          qty = int.tryParse(qtyRaw?.toString() ?? '') ?? 0;
        }

        if (qty > 0) fresh[normalized] = qty;
      }

      if (!mounted) return;
      setState(() {
        _quantities
          ..clear()
          ..addAll(fresh);
      });
    }, onError: (e) {
      // ignore: avoid_print
      print('Cart stream error in CategoriesPage: $e');
    });
  }

  @override
  void dispose() {
    _cartSub?.cancel();
    super.dispose();
  }

  String _keyForName(String raw) => raw.trim().toLowerCase();

  bool _requireLogin() {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to use the cart')),
      );
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return true;
    }
    return false;
  }

  Map<String, String?> _buildProductMapFromItem(
      Map<String, String> item, String categoryName) {
    return {
      'name': item['name'],
      'subtitle': categoryName,
      'price': item['price'],
      'imageUrl': item['image'],
      'normalizedName': (item['name'] ?? '').trim().toLowerCase(),
    };
  }

  Future<void> _addToCart(Map<String, String> item, String categoryName) async {
    if (_requireLogin()) return;
    final rawName = item['name']!;
    final key = _keyForName(rawName);

    setState(() {
      _quantities[key] = 1;
    });

    try {
      await _cartService.updateCartItem(
          _buildProductMapFromItem(item, categoryName).cast<String, dynamic>(),
          1);
    } catch (e) {
      setState(() => _quantities.remove(key));
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to add item: $e')));
    }
  }

  Future<void> _increment(Map<String, String> item, String categoryName) async {
    if (_requireLogin()) return;
    final rawName = item['name']!;
    final key = _keyForName(rawName);
    final current = _quantities[key] ?? 0;
    final next = current + 1;

    setState(() => _quantities[key] = next);

    try {
      await _cartService.updateCartItem(
          _buildProductMapFromItem(item, categoryName).cast<String, dynamic>(),
          next);
    } catch (e) {
      setState(() => _quantities[key] = current);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update quantity: $e')));
    }
  }

  Future<void> _decrement(Map<String, String> item, String categoryName) async {
    if (_requireLogin()) return;
    final rawName = item['name']!;
    final key = _keyForName(rawName);
    final current = _quantities[key] ?? 0;
    final next = (current > 1) ? current - 1 : 0;

    if (next > 0) {
      setState(() => _quantities[key] = next);
    } else {
      setState(() => _quantities.remove(key));
    }

    try {
      await _cartService.updateCartItem(
          _buildProductMapFromItem(item, categoryName).cast<String, dynamic>(),
          next);
    } catch (e) {
      setState(() {
        if (current > 0) {
          _quantities[key] = current;
        } else {
          _quantities.remove(key);
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update quantity: $e')));
    }
  }

  Widget _buildCategoryCard(Map<String, String> cat) {
    final name = cat['name'] ?? '';
    final asset = cat['asset'] ?? '';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => CategoriesPage(categoryName: name)));
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
          ),
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: SizedBox(
                  height: 80,
                  width: double.infinity,
                  child: asset.isNotEmpty
                      ? Image.asset(asset, fit: BoxFit.cover,
                          errorBuilder: (context, err, stack) {
                          return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                  Icons.image_not_supported_outlined));
                        })
                      : Container(
                          color: Colors.grey[200],
                          child:
                              const Icon(Icons.image_not_supported_outlined)),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(name,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHorizontalProductCard(
      Map<String, String> item, String categoryName) {
    final name = item['name'] ?? '';
    final image = item['image'] ?? '';
    final price = item['price'] ?? '';
    final key = _keyForName(name);
    final quantity = _quantities[key] ?? 0;

    return SizedBox(
      width: 220,
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            final productMap = _buildProductMapFromItem(item, categoryName)
                .cast<String, String?>();
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => ProductDetailsPage(product: productMap)));
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: SizedBox(
                  // increased image height so total card fits into container
                  height: 140,
                  width: double.infinity,
                  child: image.isNotEmpty
                      ? Image.asset(image, fit: BoxFit.cover,
                          errorBuilder: (c, e, s) {
                          return Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                  Icons.image_not_supported_outlined));
                        })
                      : Container(color: Colors.grey[200]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Text(price,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.green)),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: quantity == 0
                            ? OutlinedButton(
                                onPressed: () => _addToCart(item, categoryName),
                                child: const Text('ADD'))
                            : Container(
                                decoration: BoxDecoration(
                                    border:
                                        Border.all(color: Colors.blue.shade800),
                                    borderRadius: BorderRadius.circular(8)),
                                child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                          icon: const Icon(Icons.remove,
                                              size: 16),
                                          color: Colors.blue.shade800,
                                          onPressed: () =>
                                              _decrement(item, categoryName)),
                                      Text('$quantity',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      IconButton(
                                          icon: const Icon(Icons.add, size: 16),
                                          color: Colors.blue.shade800,
                                          onPressed: () =>
                                              _increment(item, categoryName)),
                                    ]),
                              ),
                      ),
                    ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategorySection(
      String categoryName, List<Map<String, String>> products) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(categoryName,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                TextButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  CategoriesPage(categoryName: categoryName)));
                    },
                    child: const Text('View All'))
              ],
            )),
        // increased height from 220 -> 260 to avoid overflow
        SizedBox(
          height: 290,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            scrollDirection: Axis.horizontal,
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = products[index];
              return _buildHorizontalProductCard(item, categoryName);
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCategoryItemsList(BuildContext context, String categoryName) {
    final items = itemsByCategory[categoryName] ?? [];
    if (items.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('No products found in "$categoryName".',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text('We don\'t have items for this category yet.'),
            const SizedBox(height: 16),
            ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Back')),
          ]),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final name = item['name'] ?? '';
        final image = item['image'] ?? '';
        final price = item['price'] ?? '';
        final key = _keyForName(name);
        final quantity = _quantities[key] ?? 0;

        return Card(
          color: Colors.grey.shade50,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200)),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: image.isNotEmpty
                      ? Image.asset(image,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => Container(
                              color: Colors.grey[200],
                              child: const Icon(
                                  Icons.image_not_supported_outlined)))
                      : Container(color: Colors.grey[200]),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: () {
                    final productMap =
                        _buildProductMapFromItem(item, categoryName)
                            .cast<String, String?>();
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailsPage(product: productMap)));
                  },
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(name,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 6),
                        Text(price,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.green)),
                        if ((item['availability'] ?? '').isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(item['availability'] ?? '',
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey)),
                        ],
                      ]),
                ),
              ),
              const SizedBox(width: 12),
              quantity == 0
                  ? OutlinedButton(
                      onPressed: () => _addToCart(item, categoryName),
                      child: const Text('ADD'))
                  : Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.blue.shade800),
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        IconButton(
                            icon: const Icon(Icons.remove, size: 16),
                            color: Colors.blue.shade800,
                            onPressed: () => _decrement(item, categoryName)),
                        Text('$quantity',
                            style:
                                const TextStyle(fontWeight: FontWeight.bold)),
                        IconButton(
                            icon: const Icon(Icons.add, size: 16),
                            color: Colors.blue.shade800,
                            onPressed: () => _increment(item, categoryName)),
                      ]),
                    ),
            ]),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Treat null, empty, "all categories", or unknown keys as the "All Categories" view.
    final raw = widget.categoryName?.trim() ?? '';
    final isAllCategories = raw.isEmpty ||
        raw.toLowerCase() == 'all categories' ||
        !itemsByCategory.containsKey(raw);

    return Scaffold(
      appBar: AppBar(
          title:
              Text(isAllCategories ? 'All Categories' : widget.categoryName!)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: isAllCategories
              ? _buildAllCategoriesView(context)
              : _buildCategoryItemsList(context, widget.categoryName!),
        ),
      ),
    );
  }

  Widget _buildAllCategoriesView(BuildContext context) {
    final categories = itemsByCategory.keys.toList();
    if (categories.isEmpty) {
      return const Center(child: Text('No categories available.'));
    }

    return ListView(
      // Add bottom padding so last horizontal section never clashes with edge
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        // health cards row — increased height to 140 so label + image fits
        SizedBox(
          height: 140,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            scrollDirection: Axis.horizontal,
            itemCount: _healthCategories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, idx) {
              final cat = _healthCategories[idx];
              return _buildCategoryCard(cat);
            },
          ),
        ),
        const SizedBox(height: 8),

        // List each category + its horizontal product list
        ...categories.map((catName) {
          final products = itemsByCategory[catName] ?? [];
          return _buildCategorySection(catName, products);
        }).toList(),
      ],
    );
  }
}
