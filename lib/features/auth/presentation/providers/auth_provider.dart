import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/models/models.dart';

// Auth Service Provider - CORRECTED
final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

// Firestore Service Provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

// Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// Current User Profile Provider
final currentUserProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return null;

  final authService = ref.watch(authServiceProvider);
  final profileData = await authService.getUserProfile(user.uid);

  if (profileData == null) return null;

  return UserProfile.fromJson(profileData);
});

// Cart Item Count Provider
final cartItemCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(0);

  return FirebaseFirestore.instance
      .collection('cart_items')
      .where('user_id', isEqualTo: user.uid)
      .snapshots()
      .map((snapshot) => snapshot.docs.length);
});

// Total Clients Provider
final totalClientsProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return 0;

  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService
      .getCount('clients', where: {'user_id': user.uid});
});

// Total Quotes Provider
final totalQuotesProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return 0;

  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService
      .getCount('quotes', where: {'user_id': user.uid});
});

// Total Products Provider
final totalProductsProvider = FutureProvider<int>((ref) async {
  final firestoreService = ref.watch(firestoreServiceProvider);
  return await firestoreService.getCount('products');
});

// Recent Quotes Provider
final recentQuotesProvider = StreamProvider<List<Quote>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('quotes')
      .where('user_id', isEqualTo: user.uid)
      .orderBy('created_at', descending: true)
      .limit(5)
      .snapshots()
      .asyncMap((snapshot) async {
    final quotes = <Quote>[];

    for (var doc in snapshot.docs) {
      final data = doc.data();
      data['id'] = doc.id;

      // Fetch client details
      if (data['client_id'] != null) {
        final clientDoc = await FirebaseFirestore.instance
            .collection('clients')
            .doc(data['client_id'])
            .get();
        if (clientDoc.exists) {
          data['clients'] = clientDoc.data();
        }
      }

      // Fetch quote items
      final itemsSnapshot = await FirebaseFirestore.instance
          .collection('quote_items')
          .where('quote_id', isEqualTo: doc.id)
          .get();

      data['quote_items'] = itemsSnapshot.docs.map((itemDoc) {
        final itemData = itemDoc.data();
        itemData['id'] = itemDoc.id;
        return itemData;
      }).toList();

      quotes.add(Quote.fromJson(data));
    }

    return quotes;
  });
});

// Recent Searches Provider
final recentSearchesProvider = FutureProvider<List<String>>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return [];

  final snapshot = await FirebaseFirestore.instance
      .collection('search_history')
      .where('user_id', isEqualTo: user.uid)
      .orderBy('created_at', descending: true)
      .limit(10)
      .get();

  return snapshot.docs
      .map((doc) => doc.data()['search_term'] as String)
      .toList();
});

// Add Search to History
Future<void> addSearchToHistory(String userId, String searchTerm) async {
  await FirebaseFirestore.instance.collection('search_history').add({
    'user_id': userId,
    'search_term': searchTerm,
    'created_at': FieldValue.serverTimestamp(),
  });

  // Clean old searches (keep only last 50)
  final oldSearches = await FirebaseFirestore.instance
      .collection('search_history')
      .where('user_id', isEqualTo: userId)
      .orderBy('created_at', descending: true)
      .limit(100)
      .get();

  if (oldSearches.docs.length > 50) {
    final batch = FirebaseFirestore.instance.batch();
    for (int i = 50; i < oldSearches.docs.length; i++) {
      batch.delete(oldSearches.docs[i].reference);
    }
    await batch.commit();
  }
}
