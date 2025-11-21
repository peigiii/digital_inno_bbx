import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/delivery_config.dart';
import '../../services/transaction_service.dart';

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

    Future<void> _submitShipping() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
            final shippingInfo = {
        'courierName': _selectedCourier,
        'trackingNumber': _trackingNumberController.text.trim(),
        'shippedAt': Timestamp.now(),
        'notes': _notesController.text.trim(),
      };

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
            content: Text('发货信息已提?),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Submission failed: $e'),
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
          Text('Fill in tracking info',
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                            const Text(
                'Courier Company *',
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

                            const Text(
                'Tracking Number *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _trackingNumberController,
                decoration: InputDecoration(
                  hintText: 'Enter tracking number',
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
                    return 'Please enter tracking number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

                            const Text(
                'Remarks (Optional)',
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
                  hintText: 'e.g. Packed, arriving in 3 days',
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
