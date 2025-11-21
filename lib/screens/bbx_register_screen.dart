import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'bbx_main_screen.dart';

class BBXRegisterScreen extends StatefulWidget {
  const BBXRegisterScreen({super.key});

  @override
  State<BBXRegisterScreen> createState() => _BBXRegisterScreenState();
}

class _BBXRegisterScreenState extends State<BBXRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _companyController = TextEditingController();
  final _cityController = TextEditingController();
  final _contactController = TextEditingController();

  String _selectedUserType = 'producer';
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // 管理�?email 列表
  final List<String> _adminEmails = [
    'admin@bbx.com',
    'peiyin5917@gmail.com',
    'peigiii@gmail.com',
    // 可以在这里添加更多管理员 email
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _companyController.dispose();
    _cityController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 创建用户账户
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (credential.user != null) {
        // 检查是否是管理�?email
        final email = _emailController.text.trim().toLowerCase();
        final isAdmin = _adminEmails.map((e) => e.toLowerCase()).contains(email);

        // 创建用户文档
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'displayName': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'userType': _selectedUserType,
          'isAdmin': isAdmin,
          'companyName': _companyController.text.trim(),
          'city': _cityController.text.trim(),
          'contact': _contactController.text.trim(),
          'photoURL': '',
          'fcmToken': '',
          'averageRating': 0.0,
          'ratingCount': 0,
          'verified': false,
          'subscriptionPlan': 'free',
          'createdAt': FieldValue.serverTimestamp(),
        });

        // 更新用户显示名称
        await credential.user!.updateDisplayName(_nameController.text.trim());

        if (mounted) {
          // 显示成功消息
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAdmin ? '注册成功！您已获得管理员权限' : '注册成功�?),
              backgroundColor: const Color(0xFF4CAF50),
            ),
          );

          // 导航到主�?
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const BBXMainScreen()),
            (route) => false,
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = '注册失败';
      if (e.code == 'email-already-in-use') {
        message = '该邮箱已被注�?;
      } else if (e.code == 'weak-password') {
        message = '密码强度太弱，请使用至少6位字�?;
      } else if (e.code == 'invalid-email') {
        message = '邮箱格式不正�?;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('注册失败: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        title: const Text('注册新账�?),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isTablet ? 80 : 24,
              vertical: 24,
            ),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        '创建您的 BBX 账户',
                        style: TextStyle(
                          fontSize: isTablet ? 24 : 20,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2E7D32),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),

                      // 用户�?
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: '用户�?,
                          prefixIcon: const Icon(Icons.person),
                          hintText: '请输入您的名�?,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入用户名';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 邮箱
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: '邮箱地址',
                          prefixIcon: const Icon(Icons.email),
                          hintText: '请输入您的邮�?,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入邮箱地址';
                          }
                          if (!value.contains('@')) {
                            return '请输入有效的邮箱地址';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 密码
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: '密码',
                          prefixIcon: const Icon(Icons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                          hintText: '请输入密码（至少6位）',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        obscureText: _obscurePassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入密�?;
                          }
                          if (value.length < 6) {
                            return '密码长度至少6�?;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 确认密码
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: '确认密码',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureConfirmPassword = !_obscureConfirmPassword;
                              });
                            },
                          ),
                          hintText: '请再次输入密�?,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        obscureText: _obscureConfirmPassword,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请确认密�?;
                          }
                          if (value != _passwordController.text) {
                            return '两次输入的密码不一�?;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 用户类型选择
                      DropdownButtonFormField<String>(
                        value: _selectedUserType,
                        decoration: InputDecoration(
                          labelText: '用户类型',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'producer',
                            child: Text('生产�?(Producer)'),
                          ),
                          DropdownMenuItem(
                            value: 'processor',
                            child: Text('处理�?(Processor)'),
                          ),
                          DropdownMenuItem(
                            value: 'recycler',
                            child: Text('回收�?(Recycler)'),
                          ),
                          DropdownMenuItem(
                            value: 'public',
                            child: Text('普通用�?),
                          ),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedUserType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // 公司名称（可选）
                      TextFormField(
                        controller: _companyController,
                        decoration: InputDecoration(
                          labelText: '公司名称（可选）',
                          prefixIcon: const Icon(Icons.business),
                          hintText: '请输入公司名�?,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 城市
                      TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: '城市',
                          prefixIcon: const Icon(Icons.location_city),
                          hintText: '请输入所在城�?,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入城�?;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // 联系电话（可选）
                      TextFormField(
                        controller: _contactController,
                        decoration: InputDecoration(
                          labelText: '联系电话（可选）',
                          prefixIcon: const Icon(Icons.phone),
                          hintText: '请输入联系电�?,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 24),

                      // 提示信息
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4CAF50).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline,
                              color: Color(0xFF2E7D32),
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '使用管理员邮箱注册将自动获得管理员权�?,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 注册按钮
                      SizedBox(
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4CAF50),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  '立即注册',
                                  style: TextStyle(fontSize: 16),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 返回登录按钮
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          '已有账户？返回登�?,
                          style: TextStyle(
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
