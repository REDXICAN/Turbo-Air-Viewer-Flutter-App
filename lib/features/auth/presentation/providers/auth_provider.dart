// lib/features/auth/presentation/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/services/firebase_auth_service.dart';
import '../../../../core/services/realtime_database_service.dart';
import '../../../../core/services/hybrid_database_service.dart';
import '../../../../core/models/models.dart';

// Auth Service Provider
final authServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

// Realtime Database Service Provider
final databaseServiceProvider = Provider<RealtimeDatabaseService>((ref) {
  return RealtimeDatabaseService();
});

// Hybrid Database Service Provider (for Firestore + Realtime)
final hybridDatabaseProvider = Provider<HybridDatabaseService>((ref) {
  return HybridDatabaseService();
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

  final dbService = ref.watch(databaseServiceProvider);
  final profileData = await dbService.getUserProfile(user.uid);

  if (profileData == null) return null;

  return UserProfile.fromJson(profileData);
});

// Cart Item Count Provider
final cartItemCountProvider = StreamProvider<int>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value(0);

  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getCartItems().map((items) => items.length);
});

// Total Clients Provider
final totalClientsProvider = FutureProvider<int>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.getTotalClients();
});

// Total Quotes Provider
final totalQuotesProvider = FutureProvider<int>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.getTotalQuotes();
});

// Total Products Provider
final totalProductsProvider = FutureProvider<int>((ref) async {
  final dbService = ref.watch(databaseServiceProvider);
  return await dbService.getTotalProducts();
});

// Recent Quotes Provider
final recentQuotesProvider = StreamProvider<List<Quote>>((ref) {
  final user = ref.watch(authStateProvider).valueOrNull;
  if (user == null) return Stream.value([]);

  final dbService = ref.watch(databaseServiceProvider);
  return dbService.getQuotes().map((quotesList) {
    // Convert to Quote models and limit to 10
    final quotes =
        quotesList.map((json) => Quote.fromJson(json)).take(10).toList();
    return quotes;
  });
});

// Theme Mode Provider
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system);

  void setThemeMode(ThemeMode mode) {
    state = mode;
  }

  void toggleDarkMode(bool isDark) {
    state = isDark ? ThemeMode.dark : ThemeMode.light;
  }
}

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
  final dbService = ref.watch(databaseServiceProvider);

  return (String email, String password, String name) async {
    try {
      final user = await authService.createUserWithEmailAndPassword(
        email: email,
        password: password,
        name: name,
      );

      if (user != null) {
        // Create user profile in Realtime Database
        await dbService.createUserProfile(
          uid: user.uid,
          email: email,
          name: name,
        );
      }

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
      // Error signing out
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
  final dbService = ref.watch(databaseServiceProvider);
  final user = ref.watch(currentUserProvider);

  return (String name) async {
    try {
      if (user == null) return 'No user signed in';

      // Update in Realtime Database
      await dbService.updateUserProfile(
        user.uid,
        {'name': name},
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
          return e.message ?? 'An error occurred changing password';
      }
    } catch (e) {
      return 'An unexpected error occurred';
    }
  };
});
