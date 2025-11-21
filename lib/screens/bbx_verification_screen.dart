import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

/// 用户认证系统
/// 支持多种认证类型：手机、邮箱、企业、身份、银�?
class BBXVerificationScreen extends StatefulWidget {
  const BBXVerificationScreen({super.key});

  @override
  State<BBXVerificationScreen> createState() => _BBXVerificationScreenState();
}

class _BBXVerificationScreenState extends State<BBXVerificationScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  String _selectedType = 'phone';
  bool _isLoading = false;

  // 表单控制�?
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  final TextEditingController _registrationNumberController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _idNumberController = TextEditingController();
  final TextEditingController _bankNameController = TextEditingController();
  final TextEditingController _accountNumberController = TextEditingController();
  final TextEditingController _verificationCodeController = TextEditingController();

  List<String> _uploadedDocuments = [];
  Map<String, dynamic>? _currentVerification;

  @override
  void initState() {
    super.initState();
    _loadCurrentVerification();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _emailController.dispose();
    _companyNameController.dispose();
    _registrationNumberController.dispose();
    _addressController.dispose();
    _idNumberController.dispose();
    _bankNameController.dispose();
    _accountNumberController.dispose();
    _verificationCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentVerification() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final doc = await _firestore
          .collection('verifications')
          .doc(userId)
          .get();

      if (doc.exists) {
        setState(() {
          _currentVerification = doc.data();
        });
      }
    } catch (e) {
      debugPrint('加载认证信息失败: $e');
    }
  }

  Future<void> _pickDocument() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        setState(() => _isLoading = true);

        // 上传�?Firebase Storage
        final userId = _auth.currentUser!.uid;
        final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
        final ref = FirebaseStorage.instance
            .ref()
            .child('verifications/$userId/$fileName');

        await ref.putFile(File(image.path));
        final url = await ref.getDownloadURL();

        setState(() {
          _uploadedDocuments.add(url);
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('文档上传成功')),
          );
        }
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e')),
        );
      }
    }
  }

  Future<void> _submitVerification() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      Map<String, dynamic> data = {
        'type': _selectedType,
        'status': 'pending',
        'documents': _uploadedDocuments,
        'submittedAt': FieldValue.serverTimestamp(),
      };

      // 根据类型添加额外字段
      switch (_selectedType) {
        case 'phone':
          data['phone'] = _phoneController.text;
          break;
        case 'email':
          data['email'] = _emailController.text;
          break;
        case 'business':
          data['companyName'] = _companyNameController.text;
          data['registrationNumber'] = _registrationNumberController.text;
          data['address'] = _addressController.text;
          break;
        case 'identity':
          data['idNumber'] = _idNumberController.text;
          break;
        case 'bank':
          data['bankName'] = _bankNameController.text;
          data['accountNumber'] = _accountNumberController.text;
          break;
      }

      await _firestore
          .collection('verifications')
          .doc(userId)
          .set(data, SetOptions(merge: true));

      setState(() => _isLoading = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('提交成功，等待审�?)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败: $e')),
        );
      }
    }
  }

  Widget _buildVerificationBadge(String? status) {
    if (status == null) return const SizedBox();

    IconData icon;
    Color color;
    String label;

    switch (status) {
      case 'pending':
        icon = Icons.pending;
        color = Colors.orange;
        label = '待审�?;
        break;
      case 'approved':
        icon = Icons.verified;
        color = Colors.green;
        label = '已认�?;
        break;
      case 'rejected':
        icon = Icons.cancel;
        color = Colors.red;
        label = '未通过';
        break;
      default:
        icon = Icons.help;
        color = Colors.grey;
        label = '未知';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('身份认证'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 当前认证状�?
                  if (_currentVerification != null) ...[
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '当前认证状�?,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                _buildVerificationBadge(
                                  _currentVerification!['status'],
                                ),
                              ],
                            ),
                            if (_currentVerification!['reviewNote'] != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                '审核备注: ${_currentVerification!['reviewNote']}',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // 认证类型选择
                  const Text(
                    '选择认证类型',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildTypeChip('phone', '手机认证', Icons.phone),
                      _buildTypeChip('email', '邮箱认证', Icons.email),
                      _buildTypeChip('business', '企业认证', Icons.business),
                      _buildTypeChip('identity', '身份认证', Icons.badge),
                      _buildTypeChip('bank', '银行认证', Icons.account_balance),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // 认证表单
                  _buildVerificationForm(),
                  const SizedBox(height: 24),

                  // 文档上传
                  const Text(
                    '上传证明文档',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildDocumentUpload(),
                  const SizedBox(height: 24),

                  // 提交按钮
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _uploadedDocuments.isEmpty
                          ? null
                          : _submitVerification,
                      child: const Text('提交认证申请'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildTypeChip(String type, String label, IconData icon) {
    final isSelected = _selectedType == type;
    return FilterChip(
      selected: isSelected,
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 4),
          Text(label),
        ],
      ),
      onSelected: (selected) {
        setState(() {
          _selectedType = type;
        });
      },
    );
  }

  Widget _buildVerificationForm() {
    switch (_selectedType) {
      case 'phone':
        return Column(
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(
                labelText: '手机号码',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _verificationCodeController,
                    decoration: const InputDecoration(
                      labelText: '验证�?,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    // TODO: 发送短信验证码
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('验证码已发�?)),
                    );
                  },
                  child: const Text('发送验证码'),
                ),
              ],
            ),
          ],
        );
      case 'email':
        return TextField(
          controller: _emailController,
          decoration: const InputDecoration(
            labelText: '邮箱地址',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.email),
          ),
          keyboardType: TextInputType.emailAddress,
        );
      case 'business':
        return Column(
          children: [
            TextField(
              controller: _companyNameController,
              decoration: const InputDecoration(
                labelText: '公司名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _registrationNumberController,
              decoration: const InputDecoration(
                labelText: '工商注册�?,
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: '公司地址',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        );
      case 'identity':
        return TextField(
          controller: _idNumberController,
          decoration: const InputDecoration(
            labelText: '身份证号�?,
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.badge),
          ),
        );
      case 'bank':
        return Column(
          children: [
            TextField(
              controller: _bankNameController,
              decoration: const InputDecoration(
                labelText: '银行名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _accountNumberController,
              decoration: const InputDecoration(
                labelText: '账号',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        );
      default:
        return const SizedBox();
    }
  }

  Widget _buildDocumentUpload() {
    return Column(
      children: [
        // 已上传的文档
        if (_uploadedDocuments.isNotEmpty)
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _uploadedDocuments.length,
              itemBuilder: (context, index) {
                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  width: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _uploadedDocuments[index],
                          fit: BoxFit.cover,
                          width: 100,
                          height: 100,
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _uploadedDocuments.removeAt(index);
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        // 上传按钮
        OutlinedButton.icon(
          onPressed: _pickDocument,
          icon: const Icon(Icons.upload_file),
          label: const Text('选择文档上传'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(double.infinity, 48),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '请上传清晰的证件照片或相关证明文�?,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

/// 认证徽章组件 - 可在其他页面使用
class VerificationBadge extends StatelessWidget {
  final String userId;
  final double size;

  const VerificationBadge({
    super.key,
    required this.userId,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('verifications')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final status = data['status'];
        final type = data['type'];

        if (status != 'approved') {
          return const SizedBox();
        }

        // 根据认证类型显示不同徽章
        IconData icon;
        Color color;

        switch (type) {
          case 'phone':
          case 'email':
            icon = Icons.verified;
            color = Colors.blue;
            break;
          case 'business':
            icon = Icons.verified;
            color = Colors.amber;
            break;
          case 'identity':
          case 'bank':
            icon = Icons.workspace_premium;
            color = Colors.purple;
            break;
          default:
            icon = Icons.verified;
            color = Colors.grey;
        }

        return Icon(icon, size: size, color: color);
      },
    );
  }
}
