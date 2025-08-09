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

// Current User Provider
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});

// Current User Profile Provider
final currentUserProfileProvider = FutureProvider<UserProfile?>((ref) async {
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

// Sign In Method Provider
final signInProvider = Provider((ref) {
  final authService = ref.watch(authServiceProvider);

  return (String email, String password) async {
    try {
      await authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Wrong password provided';
        case 'invalid-email':
          return 'Invalid email address';
        case 'user-disabled':
          return 'This user has been disabled';
        default:
          return e.message ?? 'An error occurred during sign in';
      }
    } catch (e) {
      return 'An unexpected error occurred';
    }
  };
});

// Sign Up Method Provider
final signUpProvider = Provider((ref) {
  final authService = ref.watch(authServiceProvider);

  return (String email, String password, String name) async {
    try {
      await authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'weak-password':
          return 'The password is too weak';
        case 'email-already-in-use':
          return 'An account already exists with this email';
        case 'invalid-email':
          return 'Invalid email address';
        default:
          return e.message ?? 'An error occurred during sign up';
      }
    } catch (e) {
      return 'An unexpected error occurred';
    }
  };
});

// Sign Out Method Provider
final signOutProvider = Provider((ref) {
  final authService = ref.watch(authServiceProvider);

  return () async {
    try {
      await authService.signOut();
    } catch (e) {
      print('Error signing out: $e');
    }
  };
});

// Password Reset Method Provider
final resetPasswordProvider = Provider((ref) {
  final authService = ref.watch(authServiceProvider);

  return (String email) async {
    try {
      await authService.sendPasswordResetEmail(email);
      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'invalid-email':
          return 'Invalid email address';
        default:
          return e.message ?? 'An error occurred sending reset email';
      }
    } catch (e) {
      return 'An unexpected error occurred';
    }
  };
});

// Update Profile Method Provider
final updateProfileProvider = Provider((ref) {
  final authService = ref.watch(authServiceProvider);
  final user = ref.watch(currentUserProvider);

  return (String name) async {
    try {
      if (user == null) return 'No user signed in';

      await authService.updateUserProfile(
        uid: user.uid,
        data: {'name': name},
      );

      // Update Firebase Auth display name
      await user.updateDisplayName(name);

      return null; // Success
    } catch (e) {
      return 'Failed to update profile';
    }
  };
});

// Change Password Method Provider
final changePasswordProvider = Provider((ref) {
  final authService = ref.watch(authServiceProvider);
  final user = ref.watch(currentUserProvider);

  return (String currentPassword, String newPassword) async {
    try {
      if (user == null || user.email == null) {
        return 'No user signed in';
      }

      // Re-authenticate user
      await authService.reauthenticateUser(
        email: user.email!,
        password: currentPassword,
      );

      // Update password
      await authService.updatePassword(newPassword);

      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          return 'Current password is incorrect';
        case 'weak-password':
          return 'New password is too weak';
        default:
          return e.message ?? 'Failed to change password';
      }
    } catch (e) {
      return 'An unexpected error occurred';
    }
  };
});

// Delete Account Method Provider
final deleteAccountProvider = Provider((ref) {
  final authService = ref.watch(authServiceProvider);
  final user = ref.watch(currentUserProvider);

  return (String password) async {
    try {
      if (user == null || user.email == null) {
        return 'No user signed in';
      }

      // Re-authenticate user
      await authService.reauthenticateUser(
        email: user.email!,
        password: password,
      );

      // Delete account
      await authService.deleteAccount();

      return null; // Success
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'wrong-password':
          return 'Password is incorrect';
        case 'requires-recent-login':
          return 'Please sign in again before deleting your account';
        default:
          return e.message ?? 'Failed to delete account';
      }
    } catch (e) {
      return 'An unexpected error occurred';
    }
  };
});
