// lib/core/services/firebase_auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;

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

        // Create user profile in Realtime Database
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

  // Create user profile in Realtime Database
  Future<void> _createUserProfile({
    required String uid,
    required String email,
    required String name,
  }) async {
    await _database.ref('user_profiles/$uid').set({
      'uid': uid,
      'email': email,
      'name': name,
      'role': 'distributor',
      'created_at': ServerValue.timestamp,
      'updated_at': ServerValue.timestamp,
    });
  }

  // Get user profile from Realtime Database
  Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final snapshot = await _database.ref('user_profiles/$uid').get();
      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        data['id'] = uid;
        return data;
      }
      return null;
    } catch (e) {
      // Error getting user profile
      return null;
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> data) async {
    await _database.ref('user_profiles/$uid').update({
      ...data,
      'updated_at': ServerValue.timestamp,
    });
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // Reauthenticate user
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

  // Update password
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Delete user
  Future<void> deleteUser() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Delete user profile from database
      await _database.ref('user_profiles/${user.uid}').remove();
      // Delete auth user
      await user.delete();
    }
  }
}
