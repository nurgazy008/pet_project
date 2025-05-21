// screens/settings_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = false;
  String _language = 'English';
  bool _isLoading = true;
  
  final List<String> _availableLanguages = ['English', 'Russian', 'Kazakh'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final User? user = _auth.currentUser;
      
      if (user != null) {
        final DocumentSnapshot settingsDoc = 
            await _firestore.collection('users').doc(user.uid).collection('settings').doc('preferences').get();
        
        if (settingsDoc.exists) {
          final settingsData = settingsDoc.data() as Map<String, dynamic>;
          
          setState(() {
            _notificationsEnabled = settingsData['notifications'] ?? true;
            _darkModeEnabled = settingsData['darkMode'] ?? false;
            _language = settingsData['language'] ?? 'English';
            _isLoading = false;
          });
        } else {
          // Create default settings
          await _firestore.collection('users').doc(user.uid).collection('settings').doc('preferences').set({
            'notifications': true,
            'darkMode': false,
            'language': 'English',
          });
          
          setState(() {
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading settings: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSettings() async {
    try {
      final User? user = _auth.currentUser;
      
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).collection('settings').doc('preferences').update({
          'notifications': _notificationsEnabled,
          'darkMode': _darkModeEnabled,
          'language': _language,
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings updated successfully')),
        );
      }
    } catch (e) {
      print('Error updating settings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update settings')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: true,
        backgroundColor: const Color(0xFFFFB6C1),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                _buildSettingsSection('General Settings'),
                _buildSwitchTile(
                  title: 'Notifications',
                  subtitle: 'Receive notifications about events and updates',
                  value: _notificationsEnabled,
                  onChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                    _updateSettings();
                  },
                ),
                _buildSwitchTile(
                  title: 'Dark Mode',
                  subtitle: 'Use dark theme throughout the app',
                  value: _darkModeEnabled,
                  onChanged: (value) {
                    setState(() {
                      _darkModeEnabled = value;
                    });
                    _updateSettings();
                  },
                ),
                _buildSettingsSection('Language'),
                _buildLanguageDropdown(),
                _buildSettingsSection('Account'),
                _buildListTile(
                  title: 'Change Password',
                  leading: Icons.lock_outline,
                  onTap: () => _showChangePasswordDialog(),
                ),
                _buildListTile(
                  title: 'Delete Account',
                  leading: Icons.delete_outline,
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () => _showDeleteAccountDialog(),
                ),
              ],
            ),
    );
  }

  Widget _buildSettingsSection(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: SwitchListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        value: value,
        onChanged: onChanged,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        activeColor: Theme.of(context).primaryColor,
      ),
    );
  }

  Widget _buildLanguageDropdown() {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: DropdownButtonFormField<String>(
          value: _language,
          decoration: const InputDecoration(
            labelText: 'Select Language',
            border: InputBorder.none,
          ),
          items: _availableLanguages.map((String language) {
            return DropdownMenuItem<String>(
              value: language,
              child: Text(language),
            );
          }).toList(),
          onChanged: (String? newValue) {
            if (newValue != null) {
              setState(() {
                _language = newValue;
              });
              _updateSettings();
            }
          },
        ),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required IconData leading,
    Color? textColor,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 1,
      child: ListTile(
        leading: Icon(leading, color: iconColor),
        title: Text(
          title,
          style: TextStyle(color: textColor),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        onTap: onTap,
      ),
    );
  }

  void _showChangePasswordDialog() {
    final TextEditingController currentPasswordController = TextEditingController();
    final TextEditingController newPasswordController = TextEditingController();
    final TextEditingController confirmPasswordController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: currentPasswordController,
                decoration: const InputDecoration(labelText: 'Current Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your current password';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: newPasswordController,
                decoration: const InputDecoration(labelText: 'New Password'),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: confirmPasswordController,
                decoration: const InputDecoration(labelText: 'Confirm New Password'),
                obscureText: true,
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                try {
                  // Reauthenticate the user first (required for sensitive operations)
                  final User? user = _auth.currentUser;
                  if (user != null && user.email != null) {
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: currentPasswordController.text,
                    );
                    await user.reauthenticateWithCredential(credential);
                    
                    // Change password
                    await user.updatePassword(newPasswordController.text);
                    
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password changed successfully')),
                    );
                  }
                } catch (e) {
                  print('Error changing password: $e');
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to change password: $e')),
                  );
                  Navigator.pop(context);
                }
              }
            },
            child: const Text('Change'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final TextEditingController passwordController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isDeleting = false;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Delete Account'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Warning: This action cannot be undone. All your data will be permanently deleted.',
                      style: TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: passwordController,
                      decoration: const InputDecoration(
                        labelText: 'Enter your password to confirm',
                      ),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setState(() {
                              isDeleting = true;
                            });
                            
                            try {
                              // Reauthenticate user
                              final User? user = _auth.currentUser;
                              if (user != null && user.email != null) {
                                AuthCredential credential = EmailAuthProvider.credential(
                                  email: user.email!,
                                  password: passwordController.text,
                                );
                                await user.reauthenticateWithCredential(credential);
                                
                                // Delete user data from Firestore
                                await _firestore.collection('users').doc(user.uid).delete();
                                
                                // Delete user account
                                await user.delete();
                                
                                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                              }
                            } catch (e) {
                              print('Error deleting account: $e');
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Failed to delete account: $e')),
                              );
                              Navigator.pop(context);
                            }
                          }
                        },
                  child: isDeleting
                      ? const CircularProgressIndicator(strokeWidth: 2)
                      : const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}