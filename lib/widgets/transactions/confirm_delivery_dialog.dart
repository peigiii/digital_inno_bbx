import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/transaction_service.dart';

class ConfirmDeliveryDialog extends StatefulWidget {
  final String transactionId;
  final String deliveryMethod; // self_collect ?delivery

  const ConfirmDeliveryDialog({
    Key? key,
    required this.transactionId,
    required this.deliveryMethod,
  }) : super(key: key);

  @override
  State<ConfirmDeliveryDialog> createState() => _ConfirmDeliveryDialogState();
}

class _ConfirmDeliveryDialogState extends State<ConfirmDeliveryDialog> {
  final _transactionService = TransactionService();
  bool _isLoading = false;

    Future<void> _confirmDelivery() async {
    setState(() {
      _isLoading = true;
    });

    try {
            await _transactionService.updateTransaction(
        widget.transactionId,
        {
          'shippingStatus': 'delivered',
          'deliveryDate': Timestamp.now(),
        },
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Confirmed收?),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('操作失败?e'),
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
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 8),
          Text('确认收货'),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '请确认您已经收到货物?,
            style: TextStyle(fontSize: 15),
          ),
          SizedBox(height: 12),
          Text(
            '确认后款项将支付给卖家?,
            style: TextStyle(
              fontSize: 14,
              color: Colors.orange,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          child: const Text('暂不确认'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _confirmDelivery,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
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
              : const Text('确认收货'),
        ),
      ],
    );
  }
}
