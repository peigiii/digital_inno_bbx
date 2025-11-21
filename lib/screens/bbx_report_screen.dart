import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class BBXReportScreen extends StatefulWidget {
  final String targetType; // 'user', 'listing', 'review'
  final String targetId;
  final String? targetName; 
  const BBXReportScreen({
    super.key,
    required this.targetType,
    required this.targetId,
    this.targetName,
  });

  @override
  State<BBXReportScreen> createState() => _BBXReportScreenState();
}

class _BBXReportScreenState extends State<BBXReportScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  String _selectedReason = 'false_info';
  final TextEditingController _descriptionController = TextEditingController();
  List<String> _evidence = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickEvidence() async {
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
          .child('report_evidence/$userId/$fileName');

      await ref.putFile(File(image.path));
      final url = await ref.getDownloadURL();

      setState(() {
        _evidence.add(url);
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

  Future<void> _submitReport() async {
    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写举报原?)),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final userId = _auth.currentUser!.uid;

      await _firestore.collection('reports').add({
        'reporterId': userId,
        'targetType': widget.targetType,
        'targetId': widget.targetId,
        'reason': _selectedReason,
        'description': _descriptionController.text,
        'evidence': _evidence,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'reviewedAt': null,
        'reviewNote': null,
      });

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('举报已提交，我们会尽快处?)),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('举报'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                                    Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            _getTargetIcon(),
                            size: 32,
                            color: Colors.red,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '举报${_getTargetTypeLabel()}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (widget.targetName != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.targetName!,
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                                    const Text(
                    '举报原因',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildReasonOption('false_info', '虚假信息', Icons.info_outline),
                  _buildReasonOption('fraud', '欺诈行为', Icons.warning_outlined),
                  _buildReasonOption('quality', '质量问题', Icons.broken_image_outlined),
                  _buildReasonOption('inappropriate', '违规内容', Icons.report_outlined),
                  _buildReasonOption('spam', '垃圾信息', Icons.mail_outline),
                  _buildReasonOption('other', '其他', Icons.more_horiz),
                  const SizedBox(height: 24),

                                    const Text(
                    '详细描述',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: '请详细描述问?..',
                    ),
                    maxLines: 5,
                    maxLength: 500,
                  ),
                  const SizedBox(height: 24),

                                    const Text(
                    '上传证据 (可?',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  if (_evidence.isNotEmpty)
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _evidence.length,
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
                                    _evidence[index],
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
                                        _evidence.removeAt(index);
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
                  OutlinedButton.icon(
                    onPressed: _pickEvidence,
                    icon: const Icon(Icons.add_photo_alternate),
                    label: const Text('添加证据图片'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 48),
                    ),
                  ),
                  const SizedBox(height: 24),

                                    Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '我们会在24小时内审核您的举报，并采取相应措施?,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                                    SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text('提交举报'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildReasonOption(String value, String label, IconData icon) {
    final isSelected = _selectedReason == value;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: isSelected ? Colors.red[50] : null,
      child: RadioListTile<String>(
        value: value,
        groupValue: _selectedReason,
        onChanged: (val) {
          if (val != null) {
            setState(() => _selectedReason = val);
          }
        },
        title: Row(
          children: [
            Icon(icon, size: 20, color: isSelected ? Colors.red : Colors.grey),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
        activeColor: Colors.red,
      ),
    );
  }

  IconData _getTargetIcon() {
    switch (widget.targetType) {
      case 'user':
        return Icons.person;
      case 'listing':
        return Icons.shopping_bag;
      case 'review':
        return Icons.rate_review;
      default:
        return Icons.help_outline;
    }
  }

  String _getTargetTypeLabel() {
    switch (widget.targetType) {
      case 'user':
        return '用户';
      case 'listing':
        return '商品';
      case 'review':
        return '评价';
      default:
        return '';
    }
  }
}

class BBXMyReportsScreen extends StatelessWidget {
  const BBXMyReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    final userId = auth.currentUser?.uid;
    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('我的举报')),
        body: const Center(child: Text('请先登录')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('我的举报'),
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('reports')
            .where('reporterId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('错误: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final reports = snapshot.data!.docs;

          if (reports.isEmpty) {
            return const Center(child: Text('暂无举报记录'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final doc = reports[index];
              final data = doc.data() as Map<String, dynamic>;
              return _buildReportCard(data);
            },
          );
        },
      ),
    );
  }

  Widget _buildReportCard(Map<String, dynamic> data) {
    final status = data['status'] ?? 'pending';
    Color statusColor;
    String statusLabel;

    switch (status) {
      case 'pending':
        statusColor = Colors.orange;
        statusLabel = '待处?;
        break;
      case 'processing':
        statusColor = Colors.blue;
        statusLabel = '处理?;
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusLabel = '已处?;
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusLabel = '已驳?;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = '未知';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _getReasonLabel(data['reason']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              data['description'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[700]),
            ),
            if (data['reviewNote'] != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '处理结果: ${data['reviewNote']}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDate(data['createdAt']),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  String _getReasonLabel(String? reason) {
    switch (reason) {
      case 'false_info':
        return '虚假信息';
      case 'fraud':
        return '欺诈行为';
      case 'quality':
        return '质量问题';
      case 'inappropriate':
        return '违规内容';
      case 'spam':
        return '垃圾信息';
      case 'other':
        return '其他';
      default:
        return '未知原因';
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final date = timestamp.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
