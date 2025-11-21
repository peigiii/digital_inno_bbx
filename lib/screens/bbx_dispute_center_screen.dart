import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class BBXDisputeCenterScreen extends StatefulWidget {
  const BBXDisputeCenterScreen({super.key});

  @override
  State<BBXDisputeCenterScreen> createState() => _BBXDisputeCenterScreenState();
}

class _BBXDisputeCenterScreenState extends State<BBXDisputeCenterScreen>
    with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('争议解决中心'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: '全部'),
            Tab(text: '处理?),
            Tab(text: '已解?),
            Tab(text: '已关?),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDisputeList(null),
          _buildDisputeList('investigating'),
          _buildDisputeList('resolved'),
          _buildDisputeList('closed'),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateDisputeDialog(),
        icon: const Icon(Icons.add),
        label: const Text('提交争议'),
      ),
    );
  }

  Widget _buildDisputeList(String? statusFilter) {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return const Center(child: Text('请先登录'));
    }

    Query query = _firestore
        .collection('disputes')
        .where('raisedBy', isEqualTo: userId)
        .orderBy('createdAt', descending: true);

    if (statusFilter != null) {
      query = query.where('status', isEqualTo: statusFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('错误: ${snapshot.error}'));
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final disputes = snapshot.data!.docs;

        if (disputes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gavel_outlined, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  '暂无争议记录',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: disputes.length,
          itemBuilder: (context, index) {
            final doc = disputes[index];
            final data = doc.data() as Map<String, dynamic>;
            return _buildDisputeCard(doc.id, data);
          },
        );
      },
    );
  }

  Widget _buildDisputeCard(String disputeId, Map<String, dynamic> data) {
    final status = data['status'] ?? 'open';
    Color statusColor;
    String statusLabel;

    switch (status) {
      case 'open':
        statusColor = Colors.orange;
        statusLabel = '待处?;
        break;
      case 'investigating':
        statusColor = Colors.blue;
        statusLabel = '调查?;
        break;
      case 'resolved':
        statusColor = Colors.green;
        statusLabel = '已解?;
        break;
      case 'closed':
        statusColor = Colors.grey;
        statusLabel = '已关?;
        break;
      default:
        statusColor = Colors.grey;
        statusLabel = '未知';
    }

    final type = data['type'] ?? '';
    String typeLabel;
    IconData typeIcon;

    switch (type) {
      case 'not_received':
        typeLabel = '未收到货';
        typeIcon = Icons.local_shipping_outlined;
        break;
      case 'wrong_item':
        typeLabel = '货不对板';
        typeIcon = Icons.warning_outlined;
        break;
      case 'quality_issue':
        typeLabel = '质量问题';
        typeIcon = Icons.broken_image_outlined;
        break;
      default:
        typeLabel = '其他';
        typeIcon = Icons.help_outline;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showDisputeDetail(disputeId, data),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(typeIcon, size: 20, color: statusColor),
                      const SizedBox(width: 8),
                      Text(
                        typeLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
              const SizedBox(height: 12),

                            Text(
                data['description'] ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.grey[700]),
              ),
              const SizedBox(height: 12),

                            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(data['createdAt']),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  if (data['evidence'] != null &&
                      (data['evidence'] as List).isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.attach_file,
                            size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${(data['evidence'] as List).length} 个证?,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDisputeDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const CreateDisputeSheet(),
    );
  }

  void _showDisputeDetail(String disputeId, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DisputeDetailSheet(
        disputeId: disputeId,
        disputeData: data,
      ),
    );
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return '-';
    final date = timestamp.toDate();
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class CreateDisputeSheet extends StatefulWidget {
  const CreateDisputeSheet({super.key});

  @override
  State<CreateDisputeSheet> createState() => _CreateDisputeSheetState();
}

class _CreateDisputeSheetState extends State<CreateDisputeSheet> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();

  String? _selectedTransactionId;
  String _selectedType = 'not_received';
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
          .child('dispute_evidence/$userId/$fileName');

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

  Future<void> _submitDispute() async {
    if (_selectedTransactionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择相关交易')),
      );
      return;
    }

    if (_descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请填写问题描?)),
      );
      return;
    }

    try {
      setState(() => _isLoading = true);

      final userId = _auth.currentUser!.uid;

      await _firestore.collection('disputes').add({
        'transactionId': _selectedTransactionId,
        'raisedBy': userId,
        'type': _selectedType,
        'description': _descriptionController.text,
        'evidence': _evidence,
        'status': 'open',
        'resolution': null,
        'createdAt': FieldValue.serverTimestamp(),
        'resolvedAt': null,
      });

            await _firestore
          .collection('transactions')
          .doc(_selectedTransactionId)
          .update({
        'status': 'disputed',
      });

      setState(() => _isLoading = false);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('争议已提?)),
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
                '提交争议',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),

                            const Text(
                '选择相关交易',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              _buildTransactionSelector(),
              const SizedBox(height: 24),

                            const Text(
                '争议类型',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('未收到货'),
                    selected: _selectedType == 'not_received',
                    onSelected: (selected) {
                      setState(() => _selectedType = 'not_received');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('货不对板'),
                    selected: _selectedType == 'wrong_item',
                    onSelected: (selected) {
                      setState(() => _selectedType = 'wrong_item');
                    },
                  ),
                  ChoiceChip(
                    label: const Text('质量问题'),
                    selected: _selectedType == 'quality_issue',
                    onSelected: (selected) {
                      setState(() => _selectedType = 'quality_issue');
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),

                            const Text(
                '问题描述',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: '请详细描述遇到的问题...',
                ),
                maxLines: 5,
              ),
              const SizedBox(height: 24),

                            const Text(
                '上传证据',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
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
                onPressed: _isLoading ? null : _pickEvidence,
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('添加证据图片'),
              ),
              const SizedBox(height: 24),

                            SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitDispute,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('提交争议'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionSelector() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return const SizedBox();

    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('transactions')
          .where('buyerId', isEqualTo: userId)
          .where('status', whereIn: ['completed', 'shipped'])
          .orderBy('createdAt', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final transactions = snapshot.data!.docs;

        if (transactions.isEmpty) {
          return const Text('暂无可申请争议的交易');
        }

        return DropdownButtonFormField<String>(
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          hint: const Text('选择交易'),
          value: _selectedTransactionId,
          items: transactions.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return DropdownMenuItem(
              value: doc.id,
              child: Text('订单 ${doc.id.substring(0, 8)} - RM ${data['amount']}'),
            );
          }).toList(),
          onChanged: (value) {
            setState(() => _selectedTransactionId = value);
          },
        );
      },
    );
  }
}

class DisputeDetailSheet extends StatelessWidget {
  final String disputeId;
  final Map<String, dynamic> disputeData;

  const DisputeDetailSheet({
    super.key,
    required this.disputeId,
    required this.disputeData,
  });

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '争议详情',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),

                            _buildInfoSection('争议类型', _getTypeLabel(disputeData['type'])),
              _buildInfoSection('状?, _getStatusLabel(disputeData['status'])),
              _buildInfoSection('描述', disputeData['description'] ?? '-'),

                            if (disputeData['evidence'] != null &&
                  (disputeData['evidence'] as List).isNotEmpty) ...[
                const SizedBox(height: 24),
                const Text(
                  '证据',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: (disputeData['evidence'] as List).length,
                    itemBuilder: (context, index) {
                      final url = (disputeData['evidence'] as List)[index];
                      return Container(
                        margin: const EdgeInsets.only(right: 8),
                        width: 150,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(url, fit: BoxFit.cover),
                        ),
                      );
                    },
                  ),
                ),
              ],

                            if (disputeData['resolution'] != null) ...[
                const SizedBox(height: 24),
                const Text(
                  '解决方案',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                Card(
                  color: Colors.green[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(disputeData['resolution']),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoSection(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }

  String _getTypeLabel(String? type) {
    switch (type) {
      case 'not_received':
        return '未收到货';
      case 'wrong_item':
        return '货不对板';
      case 'quality_issue':
        return '质量问题';
      default:
        return '其他';
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'open':
        return '待处?';
      case 'investigating':
        return '调查?';
      case 'resolved':
        return '已解?';
      case 'closed':
        return '已关?';
      default:
        return '未知';
    }
  }
}
