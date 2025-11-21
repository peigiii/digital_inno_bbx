import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/transaction_model.dart';
import '../../services/transaction_service.dart';

/// 更新物流信息页面
class BBXUpdateLogisticsScreen extends StatefulWidget {
  final String transactionId;

  const BBXUpdateLogisticsScreen({
    Key? key,
    required this.transactionId,
  }) : super(key: key);

  @override
  State<BBXUpdateLogisticsScreen> createState() => _BBXUpdateLogisticsScreenState();
}

class _BBXUpdateLogisticsScreenState extends State<BBXUpdateLogisticsScreen> {
  final TransactionService _transactionService = TransactionService();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedStatus;
  File? _selectedPhoto;
  bool _isSubmitting = false;
  TransactionModel? _transaction;

  @override
  void initState() {
    super.initState();
    _loadTransaction();
  }

  @override
  void dispose() {
    _locationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTransaction() async {
    try {
      final transaction = await _transactionService.getTransactionDetails(widget.transactionId);
      setState(() {
        _transaction = transaction;
        _selectedStatus = _getNextStatus(transaction.shippingStatus);
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
      }
    }
  }

  /// 获取下一个可用状�?
  String? _getNextStatus(String currentStatus) {
    switch (currentStatus) {
      case 'pending':
        return 'picked_up';
      case 'picked_up':
        return 'in_transit';
      case 'in_transit':
        return 'delivered';
      default:
        return null;
    }
  }

  /// 获取可选状态列�?
  List<String> _getAvailableStatuses(String currentStatus) {
    switch (currentStatus) {
      case 'pending':
        return ['picked_up'];
      case 'picked_up':
        return ['in_transit', 'delivered'];
      case 'in_transit':
        return ['delivered'];
      default:
        return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_transaction == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('更新物流信息')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final availableStatuses = _getAvailableStatuses(_transaction!.shippingStatus);

    if (availableStatuses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('更新物流信息')),
        body: const Center(
          child: Text('当前状态无法更新物流信�?),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('更新物流信息'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 当前状态提�?
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '当前物流状�?,
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _transaction!.shippingStatusDisplay,
                            style: TextStyle(
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // 状态选择
            const Text(
              '更新状�?,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: '选择新的状�?,
              ),
              items: availableStatuses.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(_getStatusDisplayText(status)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedStatus = value;
                });
              },
            ),

            const SizedBox(height: 24),

            // 当前位置输入
            const Text(
              '当前位置（可选）',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _locationController,
              decoration: const InputDecoration(
                hintText: '如：吉隆坡仓�?,
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
            ),

            const SizedBox(height: 24),

            // 描述输入
            const Text(
              '描述信息',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              '请描述当前物流状�?,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _descriptionController,
              maxLines: 4,
              maxLength: 200,
              decoration: const InputDecoration(
                hintText: '请描述当前物流状�?,
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 24),

            // 上传照片
            const Text(
              '添加照片证明（可选）',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            GestureDetector(
              onTap: _pickPhoto,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey[400]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                child: _selectedPhoto == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '点击添加照片',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      )
                    : Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.file(
                              _selectedPhoto!,
                              width: double.infinity,
                              height: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _selectedPhoto = null;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            ),

            if (_selectedPhoto != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.refresh),
                label: const Text('重新选择'),
              ),
            ],

            const SizedBox(height: 32),

            // 底部按钮
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('取消'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitUpdate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('提交更新'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 选择照片
  Future<void> _pickPhoto() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final File imageFile = File(pickedFile.path);

        // 验证文件大小�?MB�?
        final fileSize = await imageFile.length();
        if (fileSize > 5 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('图片大小不能超过5MB')),
            );
          }
          return;
        }

        setState(() {
          _selectedPhoto = imageFile;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择照片失败: $e')),
        );
      }
    }
  }

  /// 提交更新
  Future<void> _submitUpdate() async {
    // 验证
    if (_selectedStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择状�?)),
      );
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入描述信�?)),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await _transactionService.updateShippingStatus(
        transactionId: widget.transactionId,
        newStatus: _selectedStatus!,
        location: _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null,
        description: _descriptionController.text.trim(),
        photo: _selectedPhoto,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('物流信息已更�?)),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('提交失败: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  /// 获取状态显示文�?
  String _getStatusDisplayText(String status) {
    switch (status) {
      case 'pending':
        return '待发�?;
      case 'picked_up':
        return '已取�?;
      case 'in_transit':
        return '运输�?;
      case 'delivered':
        return '已送达';
      case 'completed':
        return '已完�?;
      default:
        return status;
    }
  }
}
