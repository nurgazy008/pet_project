// services/auth_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Get current user
  User? get currentUser => _auth.currentUser;
  
  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  
  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }
  
  // Get user data from Firestore
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      final User? user = currentUser;
      if (user == null) return null;
      
      final DocumentSnapshot doc = 
          await _firestore.collection('users').doc(user.uid).get();
          
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting user data: $e');
      return null;
    }
  }
  
  // Update user profile in Firebase Auth
  Future<void> updateProfile({String? displayName, String? photoURL}) async {
    try {
      final User? user = currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      await user.updateDisplayName(displayName ?? user.displayName);
      await user.updatePhotoURL(photoURL ?? user.photoURL);
    } catch (e) {
      debugPrint('Error updating profile: $e');
      rethrow;
    }
  }
  
  // Update user data in Firestore
  Future<void> updateUserData(Map<String, dynamic> data) async {
    try {
      final User? user = currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      // Add updated timestamp
      data['updatedAt'] = FieldValue.serverTimestamp();
      
      final DocumentSnapshot doc = 
          await _firestore.collection('users').doc(user.uid).get();
          
      if (doc.exists) {
        await _firestore.collection('users').doc(user.uid).update(data);
      } else {
        // Add created timestamp for new documents
        data['createdAt'] = FieldValue.serverTimestamp();
        await _firestore.collection('users').doc(user.uid).set(data);
      }
    } catch (e) {
      debugPrint('Error updating user data: $e');
      rethrow;
    }
  }
  
  // Change email address (requires recent authentication)
  Future<void> updateEmail(String newEmail) async {
    try {
      final User? user = currentUser;
      if (user == null) throw Exception('User not authenticated');
      
      await user.updateEmail(newEmail);
      
      // Update email in Firestore as well
      await _firestore.collection('users').doc(user.uid).update({
        'email': newEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating email: $e');
      rethrow;
    }
  }
}