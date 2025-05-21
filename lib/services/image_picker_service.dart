// services/image_picker_service.dart
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:permission_handler/permission_handler.dart';
import 'auth_service.dart';

class ImagePickerService {
  final ImagePicker _picker = ImagePicker();
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final AuthService _authService = AuthService();

  // Check and request permissions before accessing camera or gallery
  Future<bool> _checkPermission(Permission permission) async {
    var status = await permission.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isDenied) {
      status = await permission.request();
      return status.isGranted;
    }

    if (status.isPermanentlyDenied) {
      return false;
    }

    return false;
  }

  // Show a selection dialog for image source
  Future<File?> pickImage(BuildContext context) async {
    File? pickedImage;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Image Source'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Gallery'),
                onTap: () async {
                  Navigator.of(context).pop();
                  pickedImage = await _pickImageFromGallery(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Camera'),
                onTap: () async {
                  Navigator.of(context).pop();
                  pickedImage = await _pickImageFromCamera(context);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );

    return pickedImage;
  }

  // Pick image from gallery
  Future<File?> _pickImageFromGallery(BuildContext context) async {
    try {
      // Check permission
      bool hasPermission = Platform.isIOS
          ? await _checkPermission(Permission.photos)
          : await _checkPermission(Permission.storage);

      if (!hasPermission) {
        _showPermissionDeniedDialog(context, 'photos');
        return null;
      }

      // Pick image
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }

      return null;
    } catch (e) {
      debugPrint('Error picking image from gallery: $e');
      _showErrorDialog(context, 'Error picking image from gallery');
      return null;
    }
  }

  // Pick image from camera
  Future<File?> _pickImageFromCamera(BuildContext context) async {
    try {
      // Check permission
      bool hasPermission = await _checkPermission(Permission.camera);

      if (!hasPermission) {
        _showPermissionDeniedDialog(context, 'camera');
        return null;
      }

      // Pick image
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        return File(pickedFile.path);
      }

      return null;
    } catch (e) {
      debugPrint('Error picking image from camera: $e');
      _showErrorDialog(context, 'Error picking image from camera');
      return null;
    }
  }

  // Upload profile image to Firebase Storage and update user data
  Future<String?> uploadProfileImage(File file) async {
    try {
      final user = _authService.currentUser;

      if (user == null) {
        return null;
      }

      // Create storage reference
      final storageRef = _storage.ref().child(
          'profile_images/${user.uid}_${DateTime.now().millisecondsSinceEpoch}.jpg');

      
      final UploadTask uploadTask = storageRef.putFile(
        file,
        SettableMetadata(contentType: 'image/jpeg'),
      );

   
      final TaskSnapshot snapshot = await uploadTask;

  
      final String downloadUrl = await snapshot.ref.getDownloadURL();

    
      await _authService.updateProfile(photoURL: downloadUrl);

   
      await _authService.updateUserData({
        'profileImageUrl': downloadUrl,
      });

      return downloadUrl;
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      return null;
    }
  }

  void _showPermissionDeniedDialog(
      BuildContext context, String permissionType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Permission Required'),
          content: Text(
              'Please grant $permissionType access in your device settings to use this feature.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await openAppSettings();
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  // Show error dialog
  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  uploadImageToFirebase(File file) {}
}
