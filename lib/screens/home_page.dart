// lib/screens/home_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'categories_page.dart';
import 'cart_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/cart_service.dart';
import 'login_screen.dart';
import 'product_details_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CartService _cartService = CartService();
  final Map<String, int> _cart = {}; // keyed by normalizedName

  int _currentCarouselIndex = 0;

  // Search related
  final TextEditingController _searchController = TextEditingController();
  Timer? _searchDebounce;
  bool _isSearching = false;
  List<Map<String, String?>> _searchResults = [];

  // Product lists (class-level)
  final List<Map<String, String?>> dailyDeals = [
    {
      'name': 'Shelcal 500mg',
      'subtitle': 'Strip of 15 Tablets',
      'price': '₹118.95',
      'originalPrice': '₹158.60',
      'discount': '25%',
      'imageUrl':
          'https://m.media-amazon.com/images/I/71WwuFUMOJL._UF1000,1000_QL80_.jpg'
    },
    {
      'name': 'Abzorb Powder',
      'subtitle': '100gm Dusting Powder',
      'price': '₹136.00',
      'originalPrice': '₹160.00',
      'discount': '15%',
      'imageUrl': 'https://m.media-amazon.com/images/I/61U2ttle1PL.jpg'
    },
    {
      'name': 'Becozyme C Forte',
      'subtitle': 'Strip of 20 Tablets',
      'price': '₹45.00',
      'originalPrice': '₹50.00',
      'discount': '10%',
      'imageUrl':
          'https://images.apollo247.in/pub/media/catalog/product/b/e/bec0369_4.png'
    },
    {
      'name': 'Dolo 650',
      'subtitle': 'Strip of 15',
      'price': '₹30',
      'originalPrice': null,
      'discount': null,
      'imageUrl':
          'https://images.apollo247.in/pub/media/catalog/product/d/o/dol0026_1-.jpg'
    },
    {
      'name': 'Himalaya Ophthacare',
      'subtitle': '10ml Bottle',
      'price': '₹100',
      'originalPrice': null,
      'discount': null,
      'imageUrl':
          'https://himalayawellness.in/cdn/shop/products/OPHTHACARE-DROPS-10ML.jpg'
    },
  ];

  final List<Map<String, String?>> trendingProducts = [
    {
      'name': 'Zincovit Tablets',
      'subtitle': 'Strip of 15',
      'price': '₹110',
      'originalPrice': null,
      'discount': null,
      'imageUrl':
          'https://images.apollo247.in/pub/media/catalog/product/Z/I/ZIN0036_1_1.jpg'
    },
    {
      'name': 'Vicks Cough Syrup',
      'subtitle': '100ml Bottle',
      'price': '₹50',
      'originalPrice': null,
      'discount': null,
      'imageUrl':
          'https://m.media-amazon.com/images/I/61DYD3i7WrL._UF1000,1000_QL80_.jpg'
    },
    {
      'name': 'Dolo 650',
      'subtitle': 'Strip of 15',
      'price': '₹30',
      'originalPrice': null,
      'discount': null,
      'imageUrl':
          'https://images.apollo247.in/pub/media/catalog/product/d/o/dol0026_1-.jpg'
    },
    {
      'name': 'Shelcal 500mg',
      'subtitle': 'Strip of 15 Tablets',
      'price': '₹118.95',
      'originalPrice': '₹158.60',
      'discount': '25%',
      'imageUrl':
          'https://m.media-amazon.com/images/I/71WwuFUMOJL._UF1000,1000_QL80_.jpg'
    },
    {
      'name': 'Abzorb Powder',
      'subtitle': '100gm Dusting Powder',
      'price': '₹136.00',
      'originalPrice': '₹160.00',
      'discount': '15%',
      'imageUrl': 'https://m.media-amazon.com/images/I/71D4oAY-WZL.jpg'
    },
  ];

  final List<Map<String, String?>> newArrivals = [
    {
      'name': 'Himalaya Ophthacare',
      'subtitle': '10ml Bottle',
      'price': '₹100',
      'originalPrice': null,
      'discount': null,
      'imageUrl':
          'https://himalayawellness.in/cdn/shop/products/OPHTHACARE-DROPS-10ML.jpg'
    },
    {
      'name': 'Vicks Cough Syrup',
      'subtitle': '100ml Bottle',
      'price': '₹50',
      'originalPrice': null,
      'discount': null,
      'imageUrl':
          'https://m.media-amazon.com/images/I/61DYD3i7WrL._UF1000,1000_QL80_.jpg'
    },
    {
      'name': 'Becozyme C Forte',
      'subtitle': 'Strip of 20 Tablets',
      'price': '₹45.00',
      'originalPrice': '₹50.00',
      'discount': '10%',
      'imageUrl':
          'https://images.apollo247.in/pub/media/catalog/product/b/e/bec0369_4.png'
    },
    {
      'name': 'Shelcal 500mg',
      'subtitle': 'Strip of 15 Tablets',
      'price': '₹118.95',
      'originalPrice': '₹158.60',
      'discount': '25%',
      'imageUrl':
          'https://m.media-amazon.com/images/I/71WwuFUMOJL._UF1000,1000_QL80_.jpg'
    },
    {
      'name': 'Zincovit Tablets',
      'subtitle': 'Strip of 15',
      'price': '₹110',
      'originalPrice': null,
      'discount': null,
      'imageUrl':
          'https://images.apollo247.in/pub/media/catalog/product/Z/I/ZIN0036_1_1.jpg'
    },
  ];

  List<Map<String, String?>> get _allProducts =>
      [...dailyDeals, ...trendingProducts, ...newArrivals];

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _cartSubscription;

  @override
  void initState() {
    super.initState();

    // Listen to auth state changes so we subscribe/unsubscribe to the correct cart stream
    FirebaseAuth.instance.authStateChanges().listen((user) {
      _cartSubscription?.cancel();
      _cart.clear();

      if (user == null) {
        if (!mounted) return;
        setState(() {});
        return;
      }

      _cartSubscription = _cartService.getCartStream().listen((snapshot) {
        final Map<String, int> fresh = {};
        for (var doc in snapshot.docs) {
          final data = doc.data();
          final rawName = (data['name'] ?? doc.id).toString();
          final normalized = (data['normalizedName'] ?? rawName)
              .toString()
              .trim()
              .toLowerCase();
          final qtyRaw = data['quantity'];
          final int qty = qtyRaw is int ? qtyRaw : int.tryParse('$qtyRaw') ?? 0;
          if (qty > 0) fresh[normalized] = qty;
        }
        if (!mounted) return;
        setState(() {
          _cart
            ..clear()
            ..addAll(fresh);
        });
      }, onError: (e) {
        // ignore: avoid_print
        print('Cart stream error: $e');
      });
    });

    _searchController.addListener(() {
      final q = _searchController.text;
      _searchDebounce?.cancel();
      _searchDebounce = Timer(const Duration(milliseconds: 300), () {
        _handleSearchChanged(q);
      });
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _cartSubscription?.cancel();
    super.dispose();
  }

  String _normalizedKey(String raw) => raw.trim().toLowerCase();

  bool _ensureLoggedIn() {
    if (FirebaseAuth.instance.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login to use the cart')));
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      return false;
    }
    return true;
  }

  Future<void> _addToCart(Map<String, String?> product) async {
    if (!_ensureLoggedIn()) return;

    final name = product['name'] ?? '';
    final key = _normalizedKey(name);
    final previous = _cart[key] ?? 0;

    setState(() => _cart[key] = 1);

    try {
      await _cartService.updateCartItem(Map<String, dynamic>.from(product), 1);
    } catch (e) {
      setState(() {
        if (previous == 0) {
          _cart.remove(key);
        } else {
          _cart[key] = previous;
        }
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to add: $e')));
    }
  }

  Future<void> _incrementQuantity(Map<String, String?> product) async {
    if (!_ensureLoggedIn()) return;

    final name = product['name'] ?? '';
    final key = _normalizedKey(name);
    final current = _cart[key] ?? 0;
    final next = current + 1;

    setState(() => _cart[key] = next);

    try {
      await _cartService.updateCartItem(
          Map<String, dynamic>.from(product), next);
    } catch (e) {
      setState(() => _cart[key] = current);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  Future<void> _decrementQuantity(Map<String, String?> product) async {
    if (!_ensureLoggedIn()) return;

    final name = product['name'] ?? '';
    final key = _normalizedKey(name);
    final current = _cart[key] ?? 0;
    final next = current > 1 ? current - 1 : 0;

    if (next > 0) {
      setState(() => _cart[key] = next);
    } else {
      setState(() => _cart.remove(key));
    }

    try {
      await _cartService.updateCartItem(
          Map<String, dynamic>.from(product), next);
    } catch (e) {
      setState(() {
        if (current > 0) {
          _cart[key] = current;
        } else {
          _cart.remove(key);
        }
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Failed to update: $e')));
    }
  }

  void _handleSearchChanged(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }
    final results = _allProducts.where((p) {
      final name = (p['name'] ?? '').toLowerCase();
      final subtitle = (p['subtitle'] ?? '').toLowerCase();
      final price = (p['price'] ?? '').toLowerCase();
      return name.contains(q) || subtitle.contains(q) || price.contains(q);
    }).toList();

    setState(() {
      _isSearching = true;
      _searchResults = results;
    });
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Text(title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildAddButton(VoidCallback onAdd) {
    return OutlinedButton(
      onPressed: onAdd,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.blue.shade800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: const Text('ADD'),
    );
  }

  Widget _buildQuantityStepper(
      int quantity, VoidCallback onIncrement, VoidCallback onDecrement) {
    return Container(
      decoration: BoxDecoration(
          border: Border.all(color: Colors.blue.shade800),
          borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
            icon: const Icon(Icons.remove, size: 16),
            onPressed: onDecrement,
            color: Colors.blue.shade800),
        Text('$quantity', style: const TextStyle(fontWeight: FontWeight.bold)),
        IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: onIncrement,
            color: Colors.blue.shade800),
      ]),
    );
  }

  Widget _buildProductCardTap({
    required Map<String, String?> product,
    required int quantity,
  }) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailsPage(product: product),
          ),
        );
      },
      child: _buildProductCard(
          name: product['name'] ?? '',
          subtitle: product['subtitle'] ?? '',
          price: product['price'] ?? '',
          originalPrice: product['originalPrice'],
          discount: product['discount'],
          imageUrl: product['imageUrl'] ?? '',
          quantity: quantity,
          onAdd: () => _addToCart(product),
          onIncrement: () => _incrementQuantity(product),
          onDecrement: () => _decrementQuantity(product)),
    );
  }

  Widget _buildProductCard({
    required String name,
    required String subtitle,
    required String price,
    String? originalPrice,
    String? discount,
    required String imageUrl,
    required int quantity,
    required VoidCallback onAdd,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
  }) {
    // Make inner layout flexible so it adapts to tile height
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image area - limit height so it doesn't push the card too tall
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              // image height is relative so it behaves better across devices
              height: 140,
              width: double.infinity,
              child: Image.network(
                imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey[200],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      color: Colors.grey,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Flexible content area
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(subtitle,
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 6),
                    Row(children: [
                      Text(price,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 14)),
                      if (originalPrice != null) const SizedBox(width: 8),
                      if (originalPrice != null)
                        Text(originalPrice,
                            style: const TextStyle(
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough)),
                    ]),
                    if (discount != null)
                      Padding(
                          padding: const EdgeInsets.only(top: 2.0),
                          child: Text('$discount OFF',
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12))),
                    const Spacer(),
                    Align(
                        alignment: Alignment.bottomRight,
                        child: quantity == 0
                            ? _buildAddButton(onAdd)
                            : _buildQuantityStepper(
                                quantity, onIncrement, onDecrement)),
                  ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductCarousel(
      String title, List<Map<String, String?>> products, int gridColumns) {
    // We'll compute a sensible childAspectRatio based on width so the tile height scales well.
    return Builder(builder: (context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final isLargeScreen = screenWidth > 800;

      // Feel free to tweak these two numbers if you still see small overflow.
      // Lower childAspectRatio -> taller tiles; higher -> shorter tiles.
      final double childAspectRatio = isLargeScreen ? 0.78 : 0.60;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle(title),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            itemCount: products.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridColumns,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: childAspectRatio,
            ),
            itemBuilder: (context, index) {
              final product = products[index];
              final productName = product['name'] ?? '';
              final qty = _cart[_normalizedKey(productName)] ?? 0;

              return _buildProductCardTap(product: product, quantity: qty);
            },
          )
        ],
      );
    });
  }

  Widget _buildHealthConcernCards(BuildContext context) {
    final List<Map<String, String>> healthConcerns = [
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.start,
          children: healthConcerns.map((concern) {
            // Use MouseRegion + InkWell to show clickable cursor on web and ripple effect
            return MouseRegion(
              cursor: SystemMouseCursors.click,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              CategoriesPage(categoryName: concern['name']!)));
                },
                child: Container(
                    width: MediaQuery.of(context).size.width < 600 ? 100 : 120,
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(12)),
                              child: Image.asset(concern['asset']!,
                                  height: 80,
                                  width: double.infinity,
                                  fit: BoxFit.cover)),
                          const SizedBox(height: 6),
                          Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6.0),
                              child: Text(concern['name']!,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis)),
                        ])),
              ),
            );
          }).toList()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bannerAssets = [
      'assets/images/banner_animation.gif',
      'assets/images/banner_1.jpg',
      'assets/images/banner_2.jpg',
      'assets/images/banner_3.jpg',
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isLargeScreen = screenWidth > 800;
    final bannerHeight = isLargeScreen ? screenHeight * 0.4 : 200.0;
    int gridColumns = isLargeScreen ? 5 : 2;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Meds'),
        actions: [
          Builder(
            builder: (context) {
              final int totalQty =
                  _cart.values.fold<int>(0, (sum, q) => sum + q);
              final String? displayCount =
                  totalQty == 0 ? null : (totalQty > 10 ? '10+' : '$totalQty');

              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined),
                    onPressed: () {
                      if (FirebaseAuth.instance.currentUser == null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const LoginScreen()),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CartPage()),
                        );
                      }
                    },
                  ),
                  if (displayCount != null)
                    Positioned(
                      right: 4,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Text(
                          displayCount,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 84.0), // avoid bottom clipping
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for medicines, brands, etc.',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _handleSearchChanged('');
                        },
                      )
                    : IconButton(
                        icon: const Icon(Icons.camera_alt_outlined),
                        onPressed: () {},
                      ),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),

          if (_isSearching) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text('Search results (${_searchResults.length})',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _searchResults.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: gridColumns,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: isLargeScreen ? 0.78 : 0.60,
                ),
                itemBuilder: (context, index) {
                  final p = _searchResults[index];
                  final name = p['name'] ?? '';
                  final qty = _cart[_normalizedKey(name)] ?? 0;
                  return _buildProductCardTap(product: p, quantity: qty);
                },
              ),
            ),
            const SizedBox(height: 24),
          ] else ...[
            // carousel
            CarouselSlider(
              options: CarouselOptions(
                height: bannerHeight,
                viewportFraction: 1.0,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4),
                enlargeCenterPage: false,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentCarouselIndex = index;
                  });
                },
              ),
              items: bannerAssets.map((assetPath) {
                return Center(
                  child: Container(
                    width: double.infinity,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16.0),
                      child: Image.asset(
                        assetPath,
                        fit: BoxFit.contain,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            _buildSectionTitle('Shop by Health Concern'),
            const SizedBox(height: 16),
            _buildHealthConcernCards(context),
            const SizedBox(height: 24),
            _buildProductCarousel('Daily Deals', dailyDeals, gridColumns),
            const SizedBox(height: 24),
            _buildProductCarousel(
                'Trending for You', trendingProducts, gridColumns),
            const SizedBox(height: 24),
            _buildProductCarousel('New Arrivals', newArrivals, gridColumns),
            const SizedBox(height: 24),
          ],
        ],
      ),
    );
  }
}
