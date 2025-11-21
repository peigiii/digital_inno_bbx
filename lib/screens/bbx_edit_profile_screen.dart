import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/avatar_upload_service.dart';

class BBXEditProfileScreen extends StatefulWidget {
  const BBXEditProfileScreen({super.key});

  @override
  State<BBXEditProfileScreen> createState() => _BBXEditProfileScreenState();
}

class _BBXEditProfileScreenState extends State<BBXEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final User? currentUser = FirebaseAuth.instance.currentUser;

  late TextEditingController _nameController;
  late TextEditingController _companyController;
  late TextEditingController _cityController;
  late TextEditingController _contactController;

  bool isLoading = true;
  bool isSaving = false;
  bool isUploadingAvatar = false;
  String? errorMessage;
  String? avatarUrl;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _companyController = TextEditingController();
    _cityController = TextEditingController();
    _contactController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (currentUser == null) {
      setState(() {
        errorMessage = '未登�?;
        isLoading = false;
      });
      return;
    }

    try {
      print('🔄 开始加载用户数�?..');

      // 添加超时限制
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .get()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('加载超时，请检查网络连�?);
            },
          );

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data()!;
        print('�?用户数据加载成功');

        setState(() {
          _nameController.text = data['displayName'] ?? '';
          _companyController.text = data['companyName'] ?? '';
          _cityController.text = data['city'] ?? '';
          _contactController.text = data['contact'] ?? '';
          avatarUrl = data['photoURL'] ?? '';
          isLoading = false;
          errorMessage = null;
        });
      } else {
        print('⚠️ 用户文档不存在，使用默认�?);
        setState(() {
          _nameController.text = currentUser!.displayName ??
                                  currentUser!.email?.split('@')[0] ??
                                  'User';
          isLoading = false;
          errorMessage = null;
        });
      }
    } catch (e) {
      print('�?加载用户数据失败: $e');
      if (mounted) {
        setState(() {
          errorMessage = '加载失败: $e';
          isLoading = false;
          // 使用默认�?
          _nameController.text = currentUser!.email?.split('@')[0] ?? 'User';
        });
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    if (currentUser == null) return;

    // 防止重复提交
    if (isSaving) return;

    setState(() {
      isSaving = true;
      errorMessage = null;
    });

    try {
      print('🔄 开始保存用户资�?..');

      final updates = {
        'displayName': _nameController.text.trim(),
        'companyName': _companyController.text.trim(),
        'city': _cityController.text.trim(),
        'contact': _contactController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 使用 set 而不�?update，避免文档不存在的问�?
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .set(updates, SetOptions(merge: true))
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('保存超时，请检查网络连�?);
            },
          );

      // 更新 Firebase Auth 显示名称
      await currentUser!.updateDisplayName(_nameController.text.trim());

      print('�?用户资料保存成功');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('�?个人资料已更�?),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // 延迟一下再返回，让用户看到成功提示
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          Navigator.pop(context, true); // 返回 true 表示已更�?
        }
      }
    } catch (e) {
      print('�?保存失败: $e');
      if (mounted) {
        setState(() {
          errorMessage = '保存失败: $e';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('�?保存失败: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isSaving = false;
        });
      }
    }
  }

  Future<void> _uploadAvatar() async {
    if (currentUser == null || isUploadingAvatar) return;

    setState(() {
      isUploadingAvatar = true;
    });

    try {
      final String? downloadUrl = await AvatarUploadService.pickAndUploadAvatar(
        context: context,
        userId: currentUser!.uid,
        onProgress: (progress) {
          print('上传进度: ${(progress * 100).toStringAsFixed(1)}%');
        },
      );

      if (downloadUrl != null && mounted) {
        setState(() {
          avatarUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('�?头像已更�?),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('�?上传头像失败: $e');
    } finally {
      if (mounted) {
        setState(() {
          isUploadingAvatar = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _cityController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('编辑资料'),
          backgroundColor: const Color(0xFF4CAF50),
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Color(0xFF4CAF50),
              ),
              SizedBox(height: 16),
              Text('正在加载...'),
            ],
          ),
        ),
      );
    }

    // 显示错误但仍然允许编�?
    if (errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage!),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('编辑资料'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        actions: [
          if (isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _saveProfile,
              tooltip: '保存',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 头像
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      // 头像显示
                      if (isUploadingAvatar)
                        const CircleAvatar(
                          radius: 60,
                          backgroundColor: Color(0xFF4CAF50),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      else if (avatarUrl != null && avatarUrl!.isNotEmpty)
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: CachedNetworkImageProvider(avatarUrl!),
                          backgroundColor: const Color(0xFF4CAF50),
                        )
                      else
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: const Color(0xFF4CAF50),
                          child: Text(
                            (_nameController.text.isNotEmpty
                                ? _nameController.text[0]
                                : 'U').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      // 相机图标按钮
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.camera_alt,
                              color: Color(0xFF4CAF50),
                            ),
                            onPressed: isUploadingAvatar ? null : _uploadAvatar,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '点击相机图标更换头像',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 姓名
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '姓名 *',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
                helperText: '必填�?,
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入姓�?;
                }
                return null;
              },
              enabled: !isSaving,
            ),
            const SizedBox(height: 16),

            // 公司名称
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: '公司名称',
                prefixIcon: Icon(Icons.business),
                border: OutlineInputBorder(),
              ),
              enabled: !isSaving,
            ),
            const SizedBox(height: 16),

            // 城市
            TextFormField(
              controller: _cityController,
              decoration: const InputDecoration(
                labelText: '城市',
                prefixIcon: Icon(Icons.location_city),
                border: OutlineInputBorder(),
              ),
              enabled: !isSaving,
            ),
            const SizedBox(height: 16),

            // 联系电话
            TextFormField(
              controller: _contactController,
              decoration: const InputDecoration(
                labelText: '联系电话',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
                hintText: '+60 12-345-6789',
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value != null && value.isNotEmpty) {
                  if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(value)) {
                    return '请输入有效的电话号码';
                  }
                }
                return null;
              },
              enabled: !isSaving,
            ),
            const SizedBox(height: 16),

            // 邮箱（只读）
            TextFormField(
              initialValue: currentUser?.email ?? '',
              decoration: const InputDecoration(
                labelText: '邮箱',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
                enabled: false,
                helperText: '邮箱不可修改',
              ),
            ),
            const SizedBox(height: 32),

            // 保存按钮
            ElevatedButton(
              onPressed: isSaving ? null : _saveProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                disabledBackgroundColor: Colors.grey,
              ),
              child: isSaving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text('保存�?..'),
                      ],
                    )
                  : const Text(
                      '保存',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // 调试信息（仅开发模式）
            if (errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  border: Border.all(color: Colors.orange),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '提示�?errorMessage',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
