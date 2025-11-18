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

  /// 选择并上传头像（主方法）
  static Future<String?> pickAndUploadAvatar({
    required BuildContext context,
    required String userId,
    Function(double)? onProgress,
  }) async {
    try {
      // 1. 显示选择对话框
      final source = await _showImageSourceDialog(context);
      if (source == null) return null;

      // 2. 选择图片
      final File? imageFile = await _pickImage(source);
      if (imageFile == null) return null;

      // 3. 检查文件大小
      final fileSize = await imageFile.length();
      if (fileSize > maxFileSizeBytes) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('图片太大，请选择小于 5MB 的图片'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return null;
      }

      // 4. 压缩图片
      final File compressedFile = await _compressImage(imageFile);

      // 5. 上传到 Storage
      final String downloadUrl = await _uploadToStorage(
        compressedFile,
        userId,
        onProgress,
      );

      // 6. 更新 Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({
        'photoURL': downloadUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ 头像上传成功: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ 头像上传失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('上传失败: $e'),
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
        title: const Text('选择图片来源'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF4CAF50)),
              title: const Text('拍照'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF4CAF50)),
              title: const Text('从相册选择'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
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
        maxWidth: 1000,
        imageQuality: 90,
      );

      if (pickedFile == null) return null;

      return File(pickedFile.path);
    } catch (e) {
      print('❌ 选择图片失败: $e');
      return null;
    }
  }

  /// 压缩图片
  static Future<File> _compressImage(File file) async {
    try {
      print('🔄 开始压缩图片...');

      // 读取图片
      final bytes = await file.readAsBytes();
      img.Image? image = img.decodeImage(bytes);

      if (image == null) {
        throw Exception('无法解码图片');
      }

      // 调整大小
      if (image.width > maxWidth) {
        image = img.copyResize(image, width: maxWidth);
      }

      // 压缩为 JPEG
      final compressedBytes = img.encodeJpg(image, quality: imageQuality);

      // 保存到临时文件
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/compressed_avatar.jpg');
      await tempFile.writeAsBytes(compressedBytes);

      print('✅ 图片压缩完成');
      print('   原始大小: ${(bytes.length / 1024).toStringAsFixed(2)} KB');
      print('   压缩后大小: ${(compressedBytes.length / 1024).toStringAsFixed(2)} KB');

      return tempFile;
    } catch (e) {
      print('❌ 压缩图片失败: $e');
      // 如果压缩失败，返回原始文件
      return file;
    }
  }

  /// 上传到 Firebase Storage
  static Future<String> _uploadToStorage(
    File file,
    String userId,
    Function(double)? onProgress,
  ) async {
    try {
      print('🔄 开始上传到 Firebase Storage...');

      // 删除旧头像（如果存在）
      await deleteAvatar(userId);

      // 上传新头像
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('$userId.jpg');

      final uploadTask = storageRef.putFile(file);

      // 监听上传进度
      uploadTask.snapshotEvents.listen((snapshot) {
        final progress = snapshot.bytesTransferred / snapshot.totalBytes;
        onProgress?.call(progress);
        print('   上传进度: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // 等待上传完成
      final snapshot = await uploadTask;

      // 获取下载 URL
      final downloadUrl = await snapshot.ref.getDownloadURL();

      print('✅ 上传完成: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('❌ 上传失败: $e');
      throw Exception('上传失败: $e');
    }
  }

  /// 删除头像
  static Future<void> deleteAvatar(String userId) async {
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('avatars')
          .child('$userId.jpg');

      await storageRef.delete();
      print('🗑️ 旧头像已删除');
    } catch (e) {
      // 如果文件不存在，忽略错误
      if (e.toString().contains('object-not-found')) {
        print('ℹ️ 没有找到旧头像');
      } else {
        print('⚠️ 删除旧头像失败: $e');
      }
    }
  }

  /// 从 URL 删除头像（通过 Firestore）
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

      print('✅ 头像已从 Firestore 删除');
    } catch (e) {
      print('❌ 删除头像失败: $e');
      throw Exception('删除头像失败: $e');
    }
  }
}
