// lib/features/auth/presentation/providers/auth_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/models/models.dart';

// Auth Service Provider
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

  final snapshot = await FirebaseFirestore.instance
      .collection('clients')
      .where('user_id', isEqualTo: user.uid)
      .get();

  return snapshot.docs.length;
});

// Total Quotes Provider
final totalQuotesProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return 0;

  final snapshot = await FirebaseFirestore.instance
      .collection('quotes')
      .where('user_id', isEqualTo: user.uid)
      .get();

  return snapshot.docs.length;
});

// Total Products Provider
final totalProductsProvider = FutureProvider<int>((ref) async {
  final snapshot =
      await FirebaseFirestore.instance.collection('products').get();

  return snapshot.docs.length;
});

// Recent Quotes Provider
final recentQuotesProvider = StreamProvider<List<Quote>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);

  return FirebaseFirestore.instance
      .collection('quotes')
      .where('user_id', isEqualTo: user.uid)
      .orderBy('created_at', descending: true)
      .limit(10)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Quote.fromJson({...doc.data(), 'id': doc.id}))
          .toList());
});
