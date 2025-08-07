// lib/core/services/firebase_auth_service.dart
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email & password
  Future<UserCredential> signUp({
    required String email,
    required String password,
    String? company,
  }) async {
    try {
      // Check if this is the first user
      final usersSnapshot = await _firestore.collection('user_profiles').get();
      final isFirstUser = usersSnapshot.docs.isEmpty;

      // Create auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user profile in Firestore with appropriate role
      if (credential.user != null) {
        String role = 'distributor';

        // First user becomes superadmin
        if (isFirstUser) {
          role = 'superadmin';
          debugPrint('🎉 First user registered as SUPER ADMIN: $email');
        }

        await _firestore
            .collection('user_profiles')
            .doc(credential.user!.uid)
            .set({
          'id': credential.user!.uid,
          'email': email,
          'company': company,
          'role': role,
          'created_at': FieldValue.serverTimestamp(),
          'updated_at': FieldValue.serverTimestamp(),
        });
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'weak-password') {
        throw Exception('The password provided is too weak.');
      } else if (e.code == 'email-already-in-use') {
        throw Exception('An account already exists for that email.');
      }
      throw Exception(e.message ?? 'Sign up failed');
    }
  }

  // Sign in with email & password
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        throw Exception('No user found for that email.');
      } else if (e.code == 'wrong-password') {
        throw Exception('Wrong password provided.');
      }
      throw Exception(e.message ?? 'Sign in failed');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw Exception(e.message ?? 'Password reset failed');
    }
  }

  // Get user profile from Firestore
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('user_profiles').doc(uid).get();
      return doc.data();
    } catch (e) {
      debugPrint('Error getting user profile: $e');
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    data['updated_at'] = FieldValue.serverTimestamp();
    await _firestore.collection('user_profiles').doc(uid).update(data);
  }

  // Update user role (admin/superadmin only)
  Future<void> updateUserRole(String targetUid, String newRole) async {
    try {
      // Don't allow changing superadmin role
      final targetDoc =
          await _firestore.collection('user_profiles').doc(targetUid).get();
      if (targetDoc.data()?['role'] == 'superadmin') {
        throw Exception('Cannot change super admin role');
      }

      await _firestore.collection('user_profiles').doc(targetUid).update({
        'role': newRole,
        'updated_at': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update user role: $e');
    }
  }

  // Get all users (admin/superadmin only)
  Stream<List<Map<String, dynamic>>> getAllUsers() {
    return _firestore
        .collection('user_profiles')
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  // Delete user (superadmin only)
  Future<void> deleteUser(String uid) async {
    try {
      // Don't allow deleting superadmin
      final userDoc =
          await _firestore.collection('user_profiles').doc(uid).get();
      if (userDoc.data()?['role'] == 'superadmin') {
        throw Exception('Cannot delete super admin');
      }

      // Delete from Firestore
      await _firestore.collection('user_profiles').doc(uid).delete();

      // Note: Deleting from Firebase Auth requires admin SDK
      // This would typically be done via a Cloud Function
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }
}
