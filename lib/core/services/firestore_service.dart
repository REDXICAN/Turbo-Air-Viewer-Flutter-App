// In lib/core/services/firestore_service.dart
// Find and update the getProducts method:

Stream<List<Map<String, dynamic>>> getProducts({String? category}) {
  Query<Map<String, dynamic>> query = _firestore.collection('products');

  if (category != null && category.isNotEmpty) {
    // FIX: Ensure no trailing space in field name
    query = query.where('category',
        isEqualTo: category); // ← Make sure it's 'category' not 'category '
  }

  return query.snapshots().map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  });
}

// Also check searchProducts method if it exists:
Future<List<Map<String, dynamic>>> searchProducts(String searchTerm) async {
  final searchTermLower = searchTerm.toLowerCase();

  try {
    // Search by SKU (exact match)
    final skuQuery = await _firestore
        .collection('products')
        .where('sku', isEqualTo: searchTerm.toUpperCase())
        .get();

    if (skuQuery.docs.isNotEmpty) {
      return skuQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    }

    // Search by category (case-insensitive)
    final categoryQuery = await _firestore
        .collection('products')
        .where('category',
            isEqualTo: searchTerm
                .toUpperCase()) // ← Make sure it's 'category' not 'category '
        .get();

    if (categoryQuery.docs.isNotEmpty) {
      return categoryQuery.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    }

    // For description search, you might need to get all products and filter locally
    // Or implement a proper search solution like Algolia
    final allProducts = await _firestore.collection('products').get();

    final filteredProducts = allProducts.docs.where((doc) {
      final data = doc.data();
      final description = (data['description'] ?? '').toString().toLowerCase();
      final productType = (data['product_type'] ?? '').toString().toLowerCase();
      final sku = (data['sku'] ?? '').toString().toLowerCase();

      return description.contains(searchTermLower) ||
          productType.contains(searchTermLower) ||
          sku.contains(searchTermLower);
    }).map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();

    return filteredProducts;
  } catch (e) {
    print('Error searching products: $e');
    return [];
  }
}
