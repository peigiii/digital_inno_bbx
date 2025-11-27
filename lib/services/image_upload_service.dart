import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// ImgBB 图片上传服务
/// 免费、无限上传、永久存储
class ImageUploadService {
  // ImgBB API Key
  static const String _apiKey = 'b3fd1a9d96ddadc4ec9313d89cd4f060';
  static const String _uploadUrl = 'https://api.imgbb.com/1/upload';

  /// 上传单张图片到 ImgBB
  /// 返回图片 URL，失败返回 null
  static Future<String?> uploadImage(File imageFile) async {
    try {
      debugPrint('📤 [ImageUpload] Starting upload...');
      debugPrint('📁 [ImageUpload] File path: ${imageFile.path}');
      debugPrint('📏 [ImageUpload] File size: ${await imageFile.length()} bytes');

      // 读取图片并转换为 base64
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      debugPrint('🔄 [ImageUpload] Sending request to ImgBB...');

      // 发送请求
      final response = await http.post(
        Uri.parse(_uploadUrl),
        body: {
          'key': _apiKey,
          'image': base64Image,
        },
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Upload timeout - please try again');
        },
      );

      debugPrint('📡 [ImageUpload] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final imageUrl = jsonResponse['data']['url'] as String;
          final displayUrl = jsonResponse['data']['display_url'] as String;
          final thumbUrl = jsonResponse['data']['thumb']?['url'] as String?;

          debugPrint('✅ [ImageUpload] Success!');
          debugPrint('   - URL: $imageUrl');
          debugPrint('   - Display URL: $displayUrl');
          debugPrint('   - Thumb URL: $thumbUrl');

          // 返回 display_url（优化过的图片链接）
          return displayUrl;
        } else {
          final error = jsonResponse['error']?['message'] ?? 'Unknown error';
          debugPrint('❌ [ImageUpload] API error: $error');
          return null;
        }
      } else {
        debugPrint('❌ [ImageUpload] HTTP error: ${response.statusCode}');
        debugPrint('   Response body: ${response.body}');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ [ImageUpload] Exception: $e');
      debugPrint('📚 [ImageUpload] Stack trace: $stackTrace');
      return null;
    }
  }

  /// 上传多张图片
  /// 返回成功上传的图片 URL 列表
  /// [onProgress] 回调返回当前进度 (0.0 - 1.0)
  static Future<List<String>> uploadMultipleImages(
    List<XFile> images, {
    Function(double progress, int current, int total)? onProgress,
  }) async {
    List<String> uploadedUrls = [];

    for (int i = 0; i < images.length; i++) {
      debugPrint('📤 [ImageUpload] Uploading image ${i + 1}/${images.length}');

      // 报告进度
      onProgress?.call((i + 1) / images.length, i + 1, images.length);

      final file = File(images[i].path);
      final url = await uploadImage(file);

      if (url != null) {
        uploadedUrls.add(url);
        debugPrint('✅ [ImageUpload] Image ${i + 1} uploaded successfully');
      } else {
        debugPrint('⚠️ [ImageUpload] Image ${i + 1} failed to upload');
      }
    }

    debugPrint('📊 [ImageUpload] Completed: ${uploadedUrls.length}/${images.length} images uploaded');
    return uploadedUrls;
  }

  /// 从 XFile 上传（ImagePicker 返回的格式）
  static Future<String?> uploadXFile(XFile xFile) async {
    return uploadImage(File(xFile.path));
  }

  /// 上传图片并返回详细结果
  static Future<ImageUploadResult> uploadImageWithDetails(File imageFile) async {
    try {
      debugPrint('📤 [ImageUpload] Starting detailed upload...');

      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(_uploadUrl),
        body: {
          'key': _apiKey,
          'image': base64Image,
        },
      ).timeout(
        const Duration(seconds: 60),
        onTimeout: () {
          throw Exception('Upload timeout');
        },
      );

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);

        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'];
          return ImageUploadResult(
            success: true,
            url: data['url'],
            displayUrl: data['display_url'],
            thumbUrl: data['thumb']?['url'],
            deleteUrl: data['delete_url'],
            width: data['width'],
            height: data['height'],
            size: data['size'],
          );
        } else {
          return ImageUploadResult(
            success: false,
            error: jsonResponse['error']?['message'] ?? 'Upload failed',
          );
        }
      } else {
        return ImageUploadResult(
          success: false,
          error: 'HTTP error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return ImageUploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }
}

/// 图片上传结果
class ImageUploadResult {
  final bool success;
  final String? url;
  final String? displayUrl;
  final String? thumbUrl;
  final String? deleteUrl;
  final int? width;
  final int? height;
  final int? size;
  final String? error;

  ImageUploadResult({
    required this.success,
    this.url,
    this.displayUrl,
    this.thumbUrl,
    this.deleteUrl,
    this.width,
    this.height,
    this.size,
    this.error,
  });

  /// 获取最佳展示 URL
  String? get bestUrl => displayUrl ?? url;

  @override
  String toString() {
    if (success) {
      return 'ImageUploadResult(success: true, url: $url, size: ${width}x$height)';
    } else {
      return 'ImageUploadResult(success: false, error: $error)';
    }
  }
}

