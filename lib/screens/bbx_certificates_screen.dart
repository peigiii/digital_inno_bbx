import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

/// 证书管理页面
/// 管理用户的资质证书和认证文件
class BBXCertificatesScreen extends StatefulWidget {
  final String? userId; // 如果为null，显示当前用户的证书

  const BBXCertificatesScreen({
    super.key,
    this.userId,
  });

  @override
  State<BBXCertificatesScreen> createState() => _BBXCertificatesScreenState();
}

class _BBXCertificatesScreenState extends State<BBXCertificatesScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  bool get _isOwnProfile => widget.userId == null || widget.userId == _auth.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    final displayUserId = widget.userId ?? _auth.currentUser?.uid;

    if (displayUserId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('资质证书')),
        body: const Center(child: Text('请先登录')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('资质证书'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('certificates')
            .where('userId', isEqualTo: displayUserId)
            .orderBy('uploadedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('错误: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final certificates = snapshot.data!.docs;

          if (certificates.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.workspace_premium_outlined,
                      size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    '暂无证书',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  if (_isOwnProfile) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _showAddCertificateDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('上传证书'),
                    ),
                  ],
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.8,
                  ),
                  itemCount: certificates.length,
                  itemBuilder: (context, index) {
                    final doc = certificates[index];
                    final data = doc.data() as Map<String, dynamic>;
                    return _buildCertificateCard(doc.id, data);
                  },
                ),
              ),
              if (_isOwnProfile)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddCertificateDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('上传证书'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCertificateCard(String certificateId, Map<String, dynamic> data) {
    final type = data['type'] ?? '';
    final imageUrl = data['imageUrl'] ?? '';
    final status = data['status'] ?? 'pending';

    return GestureDetector(
      onTap: () => _showCertificateDetail(certificateId, data),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 证书图片
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  imageUrl.isNotEmpty
                      ? Image.network(imageUrl, fit: BoxFit.cover)
                      : Container(
                          color: Colors.grey[200],
                          child: Icon(Icons.description,
                              size: 48, color: Colors.grey[400]),
                        ),
                  // 状态标签
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _buildStatusBadge(status),
                  ),
                ],
              ),
            ),
            // 证书信息
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCertificateTypeLabel(type),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (data['issuer'] != null)
                    Text(
                      data['issuer'],
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    String label;

    switch (status) {
      case 'approved':
        color = Colors.green;
        label = '已认证';
        break;
      case 'rejected':
        color = Colors.red;
        label = '未通过';
        break;
      default:
        color = Colors.orange;
        label = '待审核';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showAddCertificateDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const AddCertificateSheet(),
    );
  }

  void _showCertificateDetail(String certificateId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 证书图片
            if (data['imageUrl'] != null)
              Image.network(
                data['imageUrl'],
                fit: BoxFit.contain,
              ),
            // 证书信息
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getCertificateTypeLabel(data['type']),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (data['issuer'] != null)
                    Text('颁发机构: ${data['issuer']}'),
                  if (data['number'] != null)
                    Text('证书编号: ${data['number']}'),
                  if (data['validUntil'] != null)
                    Text('有效期至: ${_formatDate(data['validUntil'])}'),
                  const SizedBox(height: 8),
                  _buildStatusBadge(data['status'] ?? 'pending'),
                  if (data['reviewNote'] != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '审核备注: ${data['reviewNote']}',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            // 关闭按钮
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('关闭'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getCertificateTypeLabel(String type) {
    switch (type) {
      case 'business_license':
        return '营业执照';
      case 'industry_cert':
        return '行业资质证书';
      case 'iso_cert':
        return 'ISO 认证';
      case 'environmental_cert':
        return '环保认证';
      case 'quality_cert':
        return '质量认证';
      case 'safety_cert':
        return '安全生产许可证';
      case 'other':
        return '其他证书';
      default:
        return '证书';
    }
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// 添加证书表单
class AddCertificateSheet extends StatefulWidget {
  const AddCertificateSheet({super.key});

  @override
  State<AddCertificateSheet> createState() => _AddCertificateSheetState();
}

class _AddCertificateSheetState extends State<AddCertificateSheet> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  String _selectedType = 'business_license';
  final TextEditingController _issuerController = TextEditingController();
  final TextEditingController _numberController = TextEditingController();
  DateTime? _validUntil;
  String? _imageUrl;
  bool _isLoading = false;

  @override
  void dispose() {
    _issuerController.dispose();
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isLoading = true);

      final userId = _auth.currentUser!.uid;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('certificates/$userId/$fileName');

      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();

      setState(() {
        _imageUrl = url;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_imageUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请上传证书图片')),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final userId = _auth.currentUser!.uid;

      await _firestore.collection('certificates').add({
        'userId': userId,
        'type': _selectedType,
        'issuer': _issuerController.text,
        'number': _numberController.text,
        'validUntil': _validUntil != null ? Timestamp.fromDate(_validUntil!) : null,
        'imageUrl': _imageUrl,
        'status': 'pending',
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('证书已提交，等待审核')),
        );
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

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            controller: scrollController,
            children: [
              const Text(
                '上传证书',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

              // 证书类型
              const Text('证书类型', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'business_license', child: Text('营业执照')),
                  DropdownMenuItem(value: 'industry_cert', child: Text('行业资质证书')),
                  DropdownMenuItem(value: 'iso_cert', child: Text('ISO 认证')),
                  DropdownMenuItem(value: 'environmental_cert', child: Text('环保认证')),
                  DropdownMenuItem(value: 'quality_cert', child: Text('质量认证')),
                  DropdownMenuItem(value: 'safety_cert', child: Text('安全生产许可证')),
                  DropdownMenuItem(value: 'other', child: Text('其他证书')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedType = value);
                  }
                },
              ),
              const SizedBox(height: 16),

              // 颁发机构
              const Text('颁发机构', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _issuerController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '例如：国家质量监督检验检疫总局',
                ),
              ),
              const SizedBox(height: 16),

              // 证书编号
              const Text('证书编号', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _numberController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '证书编号',
                ),
              ),
              const SizedBox(height: 16),

              // 有效期
              const Text('有效期至 (可选)', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 365)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (date != null) {
                    setState(() => _validUntil = date);
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _validUntil != null
                        ? '${_validUntil!.year}-${_validUntil!.month.toString().padLeft(2, '0')}-${_validUntil!.day.toString().padLeft(2, '0')}'
                        : '选择日期',
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // 证书图片
              const Text('证书图片', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              if (_imageUrl != null)
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(_imageUrl!, fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _imageUrl = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 20,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                OutlinedButton.icon(
                  onPressed: _isLoading ? null : _pickImage,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('选择图片'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              const SizedBox(height: 24),

              // 提交按钮
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('提交审核'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
