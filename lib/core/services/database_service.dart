import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Products Collection
  CollectionReference get products => _db.collection('products');
  CollectionReference get clients => _db.collection('clients');
  CollectionReference get quotes => _db.collection('quotes');
  CollectionReference get users => _db.collection('users');

  // Get all products
  Stream<QuerySnapshot> getProducts() {
    return products.orderBy('name').snapshots();
  }

  // Add product
  Future<void> addProduct(Map<String, dynamic> productData) {
    return products.add({
      ...productData,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // Update product
  Future<void> updateProduct(String id, Map<String, dynamic> data) {
    return products.doc(id).update(data);
  }

  // Delete product
  Future<void> deleteProduct(String id) {
    return products.doc(id).delete();
  }

  // Get user's cart items
  Stream<QuerySnapshot> getCartItems(String userId) {
    return users.doc(userId).collection('cart').snapshots();
  }
}
