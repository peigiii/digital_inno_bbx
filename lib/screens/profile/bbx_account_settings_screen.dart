import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_button.dart';
import '../../widgets/bbx_loading.dart';

/// BBX 账户设置页面
class BBXAccountSettingsScreen extends StatefulWidget {
  const BBXAccountSettingsScreen({super.key});

  @override
  State<BBXAccountSettingsScreen> createState() =>
      _BBXAccountSettingsScreenState();
}

class _BBXAccountSettingsScreenState extends State<BBXAccountSettingsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isLoading = true;
  bool isSaving = false;

  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _companyController = TextEditingController();

  String? email;
  bool isVerified = false;
  bool isPhoneVerified = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _displayNameController.text = data['displayName'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _companyController.text = data['companyName'] ?? '';
          email = data['email'] ?? user!.email;
          isVerified = data['isVerified'] ?? false;
          isPhoneVerified = data['isPhoneVerified'] ?? false;
        });
      }

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('加载用户数据失败: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'displayName': _displayNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'companyName': _companyController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 更新 Firebase Auth 显示名称
      await user!.updateDisplayName(_displayNameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('保存成功'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('保存失败: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: BBXFullScreenLoading()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('账户设置'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveChanges,
              child: const Text('保存'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          children: [
            // 个人信息
            const Text('个人信息', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.shadowSmall,
              ),
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: '姓名',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入姓�?;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: '手机号码',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      suffixIcon: isPhoneVerified
                          ? const Icon(
                              Icons.verified,
                              color: AppTheme.success,
                            )
                          : TextButton(
                              onPressed: () {
                                // TODO: 实现手机验证
                              },
                              child: const Text('验证'),
                            ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: '地址',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

            // 公司信息
            const Text('公司信息', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.shadowSmall,
              ),
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _companyController,
                    decoration: const InputDecoration(
                      labelText: '公司名称',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

            // 账户安全
            const Text('账户安全', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.shadowSmall,
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('邮箱'),
                    subtitle: Text(email ?? '未设�?),
                    trailing: isVerified
                        ? const Icon(Icons.verified, color: AppTheme.success)
                        : TextButton(
                            onPressed: () {
                              // TODO: 发送验证邮�?
                            },
                            child: const Text('验证'),
                          ),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('修改密码'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showChangePasswordDialog(),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: const Text('实名认证'),
                    subtitle: Text(isVerified ? '已认�? : '未认�?),
                    trailing: Icon(
                      isVerified ? Icons.check_circle : Icons.chevron_right,
                      color: isVerified ? AppTheme.success : null,
                    ),
                    onTap: isVerified
                        ? null
                        : () {
                            // TODO: 跳转到实名认证页�?
                          },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

            // 危险操作
            const Text('危险操作', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.shadowSmall,
              ),
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: AppTheme.error),
                title: const Text(
                  '删除账户',
                  style: TextStyle(color: AppTheme.error),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDeleteAccountDialog(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('修改密码'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '当前密码',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '新密�?,
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: '确认新密�?,
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          BBXPrimaryButton(
            text: '确认',
            onPressed: () async {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('两次输入的密码不一�?)),
                );
                return;
              }

              // TODO: 实现密码修改逻辑
              Navigator.pop(context);
            },
            height: 40,
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('删除账户'),
        content: const Text(
          '删除账户后，所有数据将被永久删除且无法恢复。\n\n确定要删除账户吗�?,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              // TODO: 实现账户删除逻辑
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('确认删除'),
          ),
        ],
      ),
    );
  }
}
