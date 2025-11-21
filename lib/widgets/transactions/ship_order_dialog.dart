import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/delivery_config.dart';
import '../../services/transaction_service.dart';

/// 卖家发货对话�?仅邮寄方式使�?
class ShipOrderDialog extends StatefulWidget {
  final String transactionId;

  const ShipOrderDialog({
    Key? key,
    required this.transactionId,
  }) : super(key: key);

  @override
  State<ShipOrderDialog> createState() => _ShipOrderDialogState();
}

class _ShipOrderDialogState extends State<ShipOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final _trackingNumberController = TextEditingController();
  final _notesController = TextEditingController();
  final _transactionService = TransactionService();

  String _selectedCourier = DeliveryConfig.courierCompanies.first;
  bool _isLoading = false;

  @override
  void dispose() {
    _trackingNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  /// 提交发货信息
  Future<void> _submitShipping() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 构建快递信�?
      final shippingInfo = {
        'courierName': _selectedCourier,
        'trackingNumber': _trackingNumberController.text.trim(),
        'shippedAt': Timestamp.now(),
        'notes': _notesController.text.trim(),
      };

      // 更新交易记录
      await _transactionService.updateTransaction(
        widget.transactionId,
        {
          'shippingInfo': shippingInfo,
          'shippingStatus': 'in_transit',
          'shippedAt': Timestamp.now(),
        },
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('发货信息已提�?),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败�?e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.local_shipping, color: Colors.blue),
          SizedBox(width: 8),
          Text('填写快递单�?),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 快递公司选择
              const Text(
                '快递公�?*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCourier,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: DeliveryConfig.courierCompanies.map((courier) {
                  return DropdownMenuItem<String>(
                    value: courier,
                    child: Text(courier),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedCourier = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // 快递单号输�?
              const Text(
                '快递单�?*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _trackingNumberController,
                decoration: InputDecoration(
                  hintText: '输入快递单�?,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '请输入快递单�?;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // 发货备注
              const Text(
                '发货备注(可�?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _notesController,
                maxLines: 3,
                maxLength: 200,
                decoration: InputDecoration(
                  hintText: '例如：已打包，预�?天送达',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _submitShipping,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('确认发货'),
        ),
      ],
    );
  }
}
