// lib/core/services/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get auth state changes
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Sign in with email and password
  Future<User?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  // Create user with email and password
  Future<User?> createUserWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(name);

        // Create user profile in Firestore
        await _createUserProfile(
          uid: credential.user!.uid,
          email: email,
          name: name,
        );
      }

      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  // Create user profile in Firestore
  Future<void> _createUserProfile({
    required String uid,
    required String email,
    required String name,
  }) async {
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'email': email,
      'name': name,
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  // Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    required Map<String, dynamic> data,
  }) async {
    data['updated_at'] = FieldValue.serverTimestamp();
    await _firestore.collection('users').doc(uid).update(data);
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Update password
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  // Re-authenticate user
  Future<void> reauthenticateUser({
    required String email,
    required String password,
  }) async {
    final user = _auth.currentUser;
    if (user != null) {
      final credential = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(credential);
    }
  }

  // Delete user account
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Delete user profile from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // Delete user account
      await user.delete();
    }
  }

  // Check if email is already in use
  // DEPRECATED: This method is no longer recommended for security reasons
  // Instead, handle the 'email-already-in-use' error during sign-up
  @Deprecated(
      'Handle email-already-in-use error during createUserWithEmailAndPassword instead')
  Future<bool> isEmailInUse(String email) async {
    // For security reasons (email enumeration protection),
    // Firebase no longer recommends checking if an email exists before sign-up.
    // Instead, attempt to create the account and handle the error appropriately.
    //
    // This method always returns false to maintain backward compatibility,
    // but you should update your code to handle errors during sign-up instead.
    return false;
  }

  // Recommended approach: Handle errors during sign-up
  Future<SignUpResult> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user != null) {
        // Update display name
        await credential.user!.updateDisplayName(name);

        // Create user profile in Firestore
        await _createUserProfile(
          uid: credential.user!.uid,
          email: email,
          name: name,
        );

        return SignUpResult(
          success: true,
          user: credential.user,
        );
      }

      return const SignUpResult(
        success: false,
        errorMessage: 'Failed to create account',
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage;

      switch (e.code) {
        case 'email-already-in-use':
          errorMessage =
              'This email is already registered. Please sign in instead.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'weak-password':
          errorMessage =
              'The password is too weak. Please use at least 6 characters.';
          break;
        case 'operation-not-allowed':
          errorMessage = 'Email/password accounts are not enabled.';
          break;
        default:
          errorMessage = e.message ?? 'An error occurred during sign up.';
      }

      return SignUpResult(
        success: false,
        errorMessage: errorMessage,
        errorCode: e.code,
      );
    } catch (e) {
      return SignUpResult(
        success: false,
        errorMessage: 'An unexpected error occurred: ${e.toString()}',
      );
    }
  }
}

// Sign-up result class
class SignUpResult {
  final bool success;
  final User? user;
  final String? errorMessage;
  final String? errorCode;

  const SignUpResult({
    required this.success,
    this.user,
    this.errorMessage,
    this.errorCode,
  });

  bool get isEmailAlreadyInUse => errorCode == 'email-already-in-use';
}
