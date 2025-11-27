import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'image_upload_service.dart';

/// 头像上传服务 - 使用 ImgBB 免费托管
class AvatarUploadService {
  static final ImagePicker _picker = ImagePicker();
  static const int maxWidth = 512;
  static const int imageQuality = 85;
  static const int maxFileSizeBytes = 5 * 1024 * 1024; // 5MB

  /// 选择并上传头像
  static Future<String?> pickAndUploadAvatar({
    required BuildContext context,
    required String userId,
    Function(double)? onProgress,
  }) async {
    try {
      // 显示图片来源选择对话框
      final source = await _showImageSourceDialog(context);
      if (source == null) return null;

      // 选择图片
      final File? imageFile = await _pickImage(source);
      if (imageFile == null) return null;

      // 检查文件大小
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

      onProgress?.call(0.2);

      // 压缩图片
      final File compressedFile = await _compressImage(imageFile);

      onProgress?.call(0.4);

      // 上传到 ImgBB
      debugPrint('📤 Uploading avatar to ImgBB...');
      final String? downloadUrl = await ImageUploadService.uploadImage(compressedFile);

      if (downloadUrl == null) {
        throw Exception('Failed to upload avatar to ImgBB');
      }

      onProgress?.call(0.8);

      // 更新 Firestore 用户文档
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'photoURL': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 更新 Firebase Auth 用户资料
      try {
        await FirebaseAuth.instance.currentUser?.updatePhotoURL(downloadUrl);
      } catch (e) {
        debugPrint('⚠️ Failed to update Firebase Auth photo URL: $e');
        // 不抛出错误，因为 Firestore 已经更新成功
      }

      onProgress?.call(1.0);

      debugPrint('✅ Avatar uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Avatar upload failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  /// 显示图片来源选择对话框
  static Future<ImageSource?> _showImageSourceDialog(BuildContext context) async {
    return showDialog<ImageSource>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFF4CAF50)),
              ),
              title: const Text('Take Photo'),
              subtitle: const Text('Use camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.photo_library, color: Color(0xFF4CAF50)),
              ),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select existing photo'),
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

  /// 选择图片
  static Future<File?> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 90,
      );

      if (pickedFile == null) return null;

      return File(pickedFile.path);
    } catch (e) {
      debugPrint('❌ Image selection failed: $e');
      return null;
    }
  }

  /// 压缩图片
  static Future<File> _compressImage(File file) async {
    try {
      debugPrint('🔄 Compressing image...');

      // 读取图片
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('Cannot decode image');
      }

      // 调整大小
      if (image.width > maxWidth || image.height > maxWidth) {
        image = img.copyResize(
          image,
          width: image.width > image.height ? maxWidth : null,
          height: image.height > image.width ? maxWidth : null,
        );
      }

      // 压缩为 JPEG
      final compressedBytes = img.encodeJpg(image, quality: imageQuality);

      // 保存到临时文件
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempFile = File('${tempDir.path}/avatar_$timestamp.jpg');
      await tempFile.writeAsBytes(compressedBytes);

      debugPrint('✅ Image compression complete');
      debugPrint('   Original size: ${(bytes.length / 1024).toStringAsFixed(2)} KB');
      debugPrint('   Compressed size: ${(compressedBytes.length / 1024).toStringAsFixed(2)} KB');

      return tempFile;
    } catch (e) {
      debugPrint('⚠️ Image compression failed: $e');
      // 如果压缩失败，返回原文件
      return file;
    }
  }

  /// 删除头像（仅从 Firestore 清除 URL）
  /// 注意：ImgBB 的图片是永久存储的，无法通过 API 删除
  static Future<void> deleteAvatarFromFirestore(String userId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'photoURL': '',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 更新 Firebase Auth
      try {
        await FirebaseAuth.instance.currentUser?.updatePhotoURL('');
      } catch (e) {
        debugPrint('⚠️ Failed to clear Firebase Auth photo URL: $e');
      }

      debugPrint('✅ Avatar URL cleared from Firestore');
    } catch (e) {
      debugPrint('❌ Failed to delete avatar: $e');
      throw Exception('Failed to delete avatar: $e');
    }
  }

  /// 使用 XFile 上传头像（简化方法）
  static Future<String?> uploadAvatarFromXFile({
    required XFile xFile,
    required String userId,
    Function(double)? onProgress,
  }) async {
    try {
      onProgress?.call(0.2);

      // 上传到 ImgBB
      final String? downloadUrl = await ImageUploadService.uploadXFile(xFile);

      if (downloadUrl == null) {
        throw Exception('Failed to upload avatar');
      }

      onProgress?.call(0.7);

      // 更新 Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .set({
        'photoURL': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      onProgress?.call(1.0);

      return downloadUrl;
    } catch (e) {
      debugPrint('❌ Avatar upload failed: $e');
      return null;
    }
  }
}
