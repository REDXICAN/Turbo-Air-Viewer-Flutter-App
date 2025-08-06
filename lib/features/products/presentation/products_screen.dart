// lib/features/products/presentation/products_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/config/app_config.dart';
import '../../clients/presentation/screens/clients_screen.dart'
    show selectedClientProvider;

// Products provider
final productsProvider =
    FutureProvider.family<List<Product>, String?>((ref, category) async {
  final supabase = Supabase.instance.client;

  var query = supabase.from('products').select();

  if (category != null && category.isNotEmpty) {
    query = query.eq('category', category);
  }

  final response = await query.order('sku');
  return (response as List).map((json) => Product.fromJson(json)).toList();
});

// Search provider
final searchQueryProvider = StateProvider<String>((ref) => '');
final searchResultsProvider = FutureProvider<List<Product>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return [];

  final supabase = Supabase.instance.client;
  final response = await supabase
      .from('products')
      .select()
      .or('sku.ilike.%$query%,product_type.ilike.%$query%,description.ilike.%$query%')
      .limit(20);

  return (response as List).map((json) => Product.fromJson(json)).toList();
});

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String? selectedCategory;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final searchQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: const Color(0xFF20429C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: const Color(0xFF20429C),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by SKU, category or description',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                ref.read(searchQueryProvider.notifier).state = value;
              },
            ),
          ),

          // Content
          Expanded(
            child: searchQuery.isNotEmpty
                ? _buildSearchResults()
                : selectedCategory != null
                    ? _buildCategoryProducts()
                    : _buildCategories(),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Categories',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: AppConfig.categories.length,
            itemBuilder: (context, index) {
              final category = AppConfig.categories.entries.elementAt(index);
              return _buildCategoryCard(category.key, category.value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String name, CategoryInfo info) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          setState(() {
            selectedCategory = name;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                info.icon,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryProducts() {
    final productsAsync = ref.watch(productsProvider(selectedCategory));

    return Column(
      children: [
        // Back button
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  setState(() {
                    selectedCategory = null;
                  });
                },
                icon: const Icon(Icons.arrow_back),
              ),
              const SizedBox(width: 8),
              Text(
                selectedCategory!,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        Expanded(
          child: productsAsync.when(
            data: (products) => _buildProductList(products),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
          ),
        ),
      ],
    );
  }

  Widget _buildSearchResults() {
    final searchResults = ref.watch(searchResultsProvider);

    return searchResults.when(
      data: (products) {
        if (products.isEmpty) {
          return const Center(
            child: Text('No products found'),
          );
        }
        return _buildProductList(products);
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
    );
  }

  Widget _buildProductList(List<Product> products) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildProductItem(product);
      },
    );
  }

  Widget _buildProductItem(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.asset(
              'assets/screenshots/${product.sku}/${product.sku} P.1.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(Icons.image, color: Colors.grey);
              },
            ),
          ),
        ),
        title: Text(
          product.sku,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.productType != null)
              Text(
                product.productType!,
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            Text(
              '\$${product.price?.toStringAsFixed(2) ?? '0.00'}',
              style: const TextStyle(
                color: Color(0xFF20429C),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.add_shopping_cart),
          onPressed: () => _addToCart(product),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product screenshots
                const Text(
                  'Product Images',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildScreenshotThumbnail(
                        'assets/screenshots/${product.sku}/${product.sku} P.1.png',
                        'Page 1',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildScreenshotThumbnail(
                        'assets/screenshots/${product.sku}/${product.sku} P.2.png',
                        'Page 2',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (product.description != null) ...[
                  const Text('Description:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Text(product.description!),
                  const SizedBox(height: 8),
                ],
                _buildSpecRow('Dimensions', product.dimensions),
                _buildSpecRow('Weight', product.weight),
                _buildSpecRow('Voltage', product.voltage),
                _buildSpecRow('Temperature Range', product.temperatureRange),
                _buildSpecRow('Capacity', product.capacity),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _addToCart(product),
                    icon: const Icon(Icons.add_shopping_cart),
                    label: const Text('Add to Cart'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF20429C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScreenshotThumbnail(String imagePath, String label) {
    return GestureDetector(
      onTap: () => _showFullScreenImage(imagePath, label),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.image_not_supported,
                          color: Colors.grey, size: 40),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  );
                },
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(String imagePath, String title) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background (tap to close)
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black.withOpacity(0.9)),
            ),
            // Image container
            Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
                maxHeight: MediaQuery.of(context).size.height * 0.8,
              ),
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 0.5,
                maxScale: 4,
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Image not available',
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            // Close button
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
            ),
            // Title
            Positioned(
              top: 40,
              left: 20,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecRow(String label, String? value) {
    if (value == null || value.isEmpty || value == '-') {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _addToCart(Product product) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please sign in to add items to cart'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Get selected client from provider
      final selectedClient = ref.read(selectedClientProvider);

      if (selectedClient == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a client first'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      // Check if item already in cart for this client
      final existingItem = await supabase
          .from('cart_items')
          .select()
          .eq('user_id', user.id)
          .eq('client_id', selectedClient.id)
          .eq('product_id', product.id)
          .maybeSingle();

      if (existingItem != null) {
        // Update quantity
        await supabase
            .from('cart_items')
            .update({'quantity': existingItem['quantity'] + 1}).eq(
                'id', existingItem['id']);
      } else {
        // Add new item
        await supabase.from('cart_items').insert({
          'user_id': user.id,
          'client_id': selectedClient.id,
          'product_id': product.id,
          'quantity': 1,
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.sku} added to cart'),
            backgroundColor: Colors.green,
            action: SnackBarAction(
              label: 'View Cart',
              textColor: Colors.white,
              onPressed: () {
                // Navigate to cart screen
              },
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// Product model
class Product {
  final String id;
  final String sku;
  final String? category;
  final String? productType;
  final String? description;
  final double? price;
  final String? dimensions;
  final String? weight;
  final String? voltage;
  final String? temperatureRange;
  final String? capacity;

  Product({
    required this.id,
    required this.sku,
    this.category,
    this.productType,
    this.description,
    this.price,
    this.dimensions,
    this.weight,
    this.voltage,
    this.temperatureRange,
    this.capacity,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      sku: json['sku'],
      category: json['category'],
      productType: json['product_type'],
      description: json['description'],
      price: json['price']?.toDouble(),
      dimensions: json['dimensions'],
      weight: json['weight'],
      voltage: json['voltage'],
      temperatureRange: json['temperature_range'],
      capacity: json['capacity'],
    );
  }
}
