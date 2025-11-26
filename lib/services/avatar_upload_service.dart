import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class AvatarUploadService {
  static final ImagePicker _picker = ImagePicker();
  static const int maxWidth = 500;
  static const int imageQuality = 85;
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB

    static Future<String?> pickAndUploadAvatar({
    required BuildContext context,
    required String userId,
    Function(double)? onProgress,
  }) async {
    try {
            final source = await _showImageSourceDialog(context);
      if (source == null) return null;

            final File? imageFile = await _pickImage(source);
      if (imageFile == null) return null;

            final fileSize = await imageFile.length();
      if (fileSize > maxFileSizeBytes) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image too large, please select an image less than 5MB'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

            final File compressedFile = await _compressImage(imageFile);

            final String downloadUrl = await _uploadToStorage(
        compressedFile,
        userId,
        onProgress,
      );

            await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'photoURL': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('?Avatar Uploaded Successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('?Avatar Upload Failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload Failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

    static Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('SelectImageSource'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF4CAF50)),
              title: const Text('Photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF4CAF50)),
              title: const Text('FromGallerySelect'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

    static Future<File?> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1000,
        imageQuality: 90,
      );

      if (pickedFile == null) return null;

      return File(pickedFile.path);
    } catch (e) {
      print('?SelectImageFailure: $e');
      return null;
    }
  }

    static Future<File> _compressImage(File file) async {
    try {
      print('🔄 Start compressing image?..');

            final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Cannot decode image');
      }

            if (image.width > maxWidth) {
        image = img.copyResize(image, width: maxWidth);
      }

            final compressedBytes = img.encodeJpg(image, quality: imageQuality);

            final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/compressed_avatar.jpg');
      await tempFile.writeAsBytes(compressedBytes);

      print('?Image compression complete');
      print('   OrigStartSize: ${(bytes.length / 1024).toStringAsFixed(2)} KB');
      print('   CompressAfterBig? ${(compressedBytes.length / 1024).toStringAsFixed(2)} KB');

      return tempFile;
    } catch (e) {
      print('?Image compression failed: $e');
            return file;
    }
  }

    static Future<String> _uploadToStorage(
    File file,
    String userId,
    Function(double)? onProgress,
  ) async {
    try {
      print('🔄 StartUploadTo Firebase Storage...');

            await deleteAvatar(userId);

            final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('$userId.jpg');

      final uploadTask = storageRef.putFile(file);

            uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
        print('   Upload Progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

            final snapshot = await uploadTask;

            final downloadUrl = await snapshot.ref.getDownloadURL();

      print('?Upload Completed: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('?Upload Failed: $e');
      throw Exception('Upload Failed: $e');
    }
  }

    static Future<void> deleteAvatar(String userId) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('$userId.jpg');

      await storageRef.delete();
      print('🗑️ Old avatar deleted');
    } catch (e) {
      if (e.toString().contains('object-not-found')) {
        print('ℹ️ No old avatar found');
      } else {
        print('⚠️ Failed to delete old avatar: $e');
      }
    }
  }

    static Future<void> deleteAvatarFromFirestore(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'photoURL': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await deleteAvatar(userId);

      print('?AvatarAlreadyFrom Firestore Delete');
    } catch (e) {
      print('?DeleteAvatarFailure: $e');
      throw Exception('DeleteAvatarFailure: $e');
    }
  }
}
