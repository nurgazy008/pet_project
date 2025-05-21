// screens/profile_page.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'personal_info_page.dart';
import 'settings_page.dart';
import 'support_page.dart';
import 'privacy_policy_page.dart';
import '../services/auth_service.dart';
import '../services/image_picker_service.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePickerService _imagePickerService = ImagePickerService();
  final AuthService _authService = AuthService();
  
  String _name = '';
  String _studentClass = '';
  String _profileImageUrl = '';
  bool _isLoading = true;
  bool _isUpdatingImage = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoading = true;
      });
      
      final User? user = _auth.currentUser;
      
      if (user != null) {
        final DocumentSnapshot userDoc = 
            await _firestore.collection('users').doc(user.uid).get();
        
        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          
          setState(() {
            _name = userData['name'] ?? 'User';
            _studentClass = userData['studentClass'] ?? '';
            _profileImageUrl = userData['profileImageUrl'] ?? '';
            _isLoading = false;
          });
        } else {
          // If user document doesn't exist, create it with default values
          await _firestore.collection('users').doc(user.uid).set({
            'name': user.displayName ?? 'User',
            'studentClass': '',
            'profileImageUrl': user.photoURL ?? '',
            'email': user.email ?? '',
          });
          
          setState(() {
            _name = user.displayName ?? 'User';
            _studentClass = '';
            _profileImageUrl = user.photoURL ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateProfileImage() async {
    try {
      // Set loading state
      setState(() {
        _isUpdatingImage = true;
      });
      
      // Pick image using the ImagePickerService
      final File? imageFile = await _imagePickerService.pickImage(context);
      
      if (imageFile != null) {
        // Upload image and get the download URL
        final String? downloadUrl = await _imagePickerService.uploadProfileImage(imageFile);
        
        if (downloadUrl != null) {
          setState(() {
            _profileImageUrl = downloadUrl;
          });
          
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      print('Error updating profile image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to update profile picture'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUpdatingImage = false;
      });
    }
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      // Navigate to login page or home page after sign out
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      print('Error signing out: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to sign out')),
      );
    }
  }

  void _navigateToPage(Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    ).then((_) => _loadUserData()); // Reload data when returning from other pages
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 16),
                  _buildMenuItems(),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      height: 250,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFB6C1), Color(0xFFB19CD9)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(50),
          bottomRight: Radius.circular(50),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Expanded(
                    child: Text(
                      'Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  // Empty Container for balance
                  Container(width: 48),
                ],
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _isUpdatingImage ? null : _updateProfileImage,
              child: Stack(
                children: [
                  // Profile image
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    backgroundImage: _profileImageUrl.isNotEmpty
                        ? NetworkImage(_profileImageUrl)
                        : null,
                    child: _profileImageUrl.isEmpty
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),
                  
                  // Edit icon overlay
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      height: 34,
                      width: 34,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: _isUpdatingImage
                          ? const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.blue,
                              ),
                            )
                          : const Icon(
                              Icons.camera_alt,
                              color: Colors.blue,
                              size: 18,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _studentClass,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItems() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.person_outline,
            title: 'Personal Info',
            onTap: () => _navigateToPage(PersonalInfoPage()),
          ),
          _buildMenuItem(
            icon: Icons.settings,
            title: 'Setting',
            onTap: () => _navigateToPage(SettingsPage()),
          ),
          _buildMenuItem(
            icon: Icons.support_agent,
            title: 'Support',
            onTap: () => _navigateToPage(SupportPage()),
          ),
          _buildMenuItem(
            icon: Icons.policy,
            title: 'Privacy & Policy',
            onTap: () => _navigateToPage(PrivacyPolicyPage()),
          ),
          const SizedBox(height: 16),
          _buildSignOutButton(),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAE1D0),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.orange[300]),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return InkWell(
      onTap: _signOut,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFE6E6FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout, color: Colors.blue),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Text(
                'Sign out',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}