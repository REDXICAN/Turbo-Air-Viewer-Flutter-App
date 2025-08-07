import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get userId => _auth.currentUser?.uid;

  // ============ PRODUCTS ============
  Stream<List<Map<String, dynamic>>> getProducts({String? category}) {
    Query query = _db.collection('products');

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    return query.orderBy('sku').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<Map<String, dynamic>?> getProduct(String productId) async {
    final doc = await _db.collection('products').doc(productId).get();
    if (doc.exists) {
      final data = doc.data()!;
      data['id'] = doc.id;
      return data;
    }
    return null;
  }

  // ============ CLIENTS ============
  Stream<List<Map<String, dynamic>>> getClients() {
    if (userId == null) return Stream.value([]);

    return _db
        .collection('clients')
        .where('user_id', isEqualTo: userId)
        .orderBy('company')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<String> addClient(Map<String, dynamic> clientData) async {
    clientData['user_id'] = userId;
    clientData['created_at'] = FieldValue.serverTimestamp();
    clientData['updated_at'] = FieldValue.serverTimestamp();

    final docRef = await _db.collection('clients').add(clientData);
    return docRef.id;
  }

  Future<void> updateClient(String clientId, Map<String, dynamic> data) async {
    data['updated_at'] = FieldValue.serverTimestamp();
    await _db.collection('clients').doc(clientId).update(data);
  }

  Future<void> deleteClient(String clientId) async {
    await _db.collection('clients').doc(clientId).delete();
  }

  // ============ CART ============
  Stream<List<Map<String, dynamic>>> getCartItems() {
    if (userId == null) return Stream.value([]);

    return _db
        .collection('cart_items')
        .where('user_id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) async {
      final items = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        // Fetch product details
        if (data['product_id'] != null) {
          final product = await getProduct(data['product_id']);
          data['product'] = product;
        }

        items.add(data);
      }

      return items;
    }).asyncExpand((future) => Stream.fromFuture(future));
  }

  Future<void> addToCart({
    required String productId,
    required String? clientId,
    int quantity = 1,
  }) async {
    if (userId == null) throw Exception('User not authenticated');

    // Check if item already exists
    final existing = await _db
        .collection('cart_items')
        .where('user_id', isEqualTo: userId)
        .where('product_id', isEqualTo: productId)
        .where('client_id', isEqualTo: clientId)
        .get();

    if (existing.docs.isNotEmpty) {
      // Update quantity
      final doc = existing.docs.first;
      await doc.reference.update({
        'quantity': (doc.data()['quantity'] ?? 0) + quantity,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } else {
      // Add new item
      await _db.collection('cart_items').add({
        'user_id': userId,
        'product_id': productId,
        'client_id': clientId,
        'quantity': quantity,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> updateCartItemQuantity(String cartItemId, int quantity) async {
    if (quantity <= 0) {
      await _db.collection('cart_items').doc(cartItemId).delete();
    } else {
      await _db.collection('cart_items').doc(cartItemId).update({
        'quantity': quantity,
        'updated_at': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> clearCart() async {
    if (userId == null) return;

    final batch = _db.batch();
    final items = await _db
        .collection('cart_items')
        .where('user_id', isEqualTo: userId)
        .get();

    for (var doc in items.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
  }

  // ============ QUOTES ============
  Stream<List<Map<String, dynamic>>> getQuotes() {
    if (userId == null) return Stream.value([]);

    return _db
        .collection('quotes')
        .where('user_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) async {
      final quotes = <Map<String, dynamic>>[];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        data['id'] = doc.id;

        // Fetch client details
        if (data['client_id'] != null) {
          final clientDoc =
              await _db.collection('clients').doc(data['client_id']).get();
          if (clientDoc.exists) {
            data['client'] = clientDoc.data();
            data['client']['id'] = clientDoc.id;
          }
        }

        // Fetch quote items
        final itemsSnapshot = await _db
            .collection('quote_items')
            .where('quote_id', isEqualTo: doc.id)
            .get();

        final items = <Map<String, dynamic>>[];
        for (var itemDoc in itemsSnapshot.docs) {
          final itemData = itemDoc.data();
          itemData['id'] = itemDoc.id;

          // Fetch product details
          if (itemData['product_id'] != null) {
            final product = await getProduct(itemData['product_id']);
            itemData['product'] = product;
          }

          items.add(itemData);
        }

        data['quote_items'] = items;
        quotes.add(data);
      }

      return quotes;
    }).asyncExpand((future) => Stream.fromFuture(future));
  }

  Future<String> createQuote({
    required String clientId,
    required List<Map<String, dynamic>> items,
    required double subtotal,
    required double taxRate,
    required double taxAmount,
    required double totalAmount,
  }) async {
    if (userId == null) throw Exception('User not authenticated');

    // Generate quote number
    final quoteNumber = 'Q${DateTime.now().millisecondsSinceEpoch}';

    // Create quote document
    final quoteRef = await _db.collection('quotes').add({
      'user_id': userId,
      'client_id': clientId,
      'quote_number': quoteNumber,
      'subtotal': subtotal,
      'tax_rate': taxRate,
      'tax_amount': taxAmount,
      'total_amount': totalAmount,
      'status': 'draft',
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });

    // Add quote items
    final batch = _db.batch();
    for (var item in items) {
      final itemRef = _db.collection('quote_items').doc();
      batch.set(itemRef, {
        'quote_id': quoteRef.id,
        'product_id': item['product_id'],
        'quantity': item['quantity'],
        'unit_price': item['unit_price'],
        'total_price': item['total_price'],
        'created_at': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();

    return quoteRef.id;
  }

  Future<void> updateQuoteStatus(String quoteId, String status) async {
    await _db.collection('quotes').doc(quoteId).update({
      'status': status,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteQuote(String quoteId) async {
    // Delete quote items first
    final items = await _db
        .collection('quote_items')
        .where('quote_id', isEqualTo: quoteId)
        .get();

    final batch = _db.batch();
    for (var doc in items.docs) {
      batch.delete(doc.reference);
    }

    // Delete quote
    batch.delete(_db.collection('quotes').doc(quoteId));
    await batch.commit();
  }

  // ============ SEARCH ============
  Future<List<Map<String, dynamic>>> searchProducts(String query) async {
    if (query.isEmpty) return [];

    // Note: Firestore doesn't support full-text search natively
    // For production, consider using Algolia or Elasticsearch
    // This is a simple implementation that searches by SKU prefix

    final snapshot = await _db
        .collection('products')
        .where('sku', isGreaterThanOrEqualTo: query.toUpperCase())
        .where('sku', isLessThan: '${query.toUpperCase()}\uf8ff')
        .limit(20)
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id;
      return data;
    }).toList();
  }

  // ============ UTILITIES ============
  Future<int> getCount(String collection, {Map<String, dynamic>? where}) async {
    Query query = _db.collection(collection);

    if (where != null) {
      where.forEach((field, value) {
        query = query.where(field, isEqualTo: value);
      });
    }

    final snapshot = await query.count().get();
    return snapshot.count ?? 0;
  }
}
