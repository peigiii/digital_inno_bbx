import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_button.dart';
import '../../widgets/bbx_loading.dart';

class BBXWalletScreen extends StatefulWidget {
  const BBXWalletScreen({super.key});

  @override
  State<BBXWalletScreen> createState() => _BBXWalletScreenState();
}

class _BBXWalletScreenState extends State<BBXWalletScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isLoading = true;
  double balance = 0.0;
  List<Map<String, dynamic>> transactions = [];

  @override
  void initState() {
    super.initState();
    _loadWalletData();
  }

  Future<void> _loadWalletData() async {
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final walletDoc = await FirebaseFirestore.instance
          .collection('wallets')
          .doc(user!.uid)
          .get();

      if (walletDoc.exists) {
        final data = walletDoc.data()!;
        setState(() {
          balance = (data['balance'] ?? 0).toDouble();
          transactions = List<Map<String, dynamic>>.from(
            data['transactions'] ?? [],
          );
        });
      }

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Load wallet data failed: $e');
      setState(() => isLoading = false);
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
        title: const Text('My Wallet'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
                    Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppTheme.spacing24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Balance',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  'RM ${balance.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: AppTheme.bold,
                  ),
                ),
                const SizedBox(height: AppTheme.spacing24),

                                Row(
                  children: [
                    Expanded(
                      child: BBXSecondaryButton(
                        text: 'Top Up',
                        icon: Icons.add_circle_outline,
                        onPressed: () => _showDepositDialog(),
                        height: 44,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing12),
                    Expanded(
                      child: BBXSecondaryButton(
                        text: 'Withdraw',
                        icon: Icons.remove_circle_outline,
                        onPressed: () => _showWithdrawDialog(),
                        height: 44,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

                    Expanded(
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Transactions', style: AppTheme.heading3),
                  const SizedBox(height: AppTheme.spacing12),

                  Expanded(
                    child: transactions.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 64,
                                  color: AppTheme.neutral400,
                                ),
                                SizedBox(height: AppTheme.spacing16),
                                Text(
                                  'No transactions yet',
                                  style: TextStyle(
                                    color: AppTheme.neutral500,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = transactions[index];
                              return _buildTransactionItem(transaction);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(Map<String, dynamic> transaction) {
    final type = transaction['type'] as String;
    final amount = (transaction['amount'] as num).toDouble();
    final description = transaction['description'] as String? ?? '';
    final timestamp = transaction['timestamp'];

    final isPositive = amount >= 0;
    final icon = type == 'deposit'
        ? Icons.add_circle
        : type == 'withdraw'
            ? Icons.remove_circle
            : Icons.swap_horiz;
    final color = isPositive ? AppTheme.success : AppTheme.error;

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.shadowSmall,
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.1),
          child: Icon(icon, color: color),
        ),
        title: Text(
          description,
          style: AppTheme.body1,
        ),
        subtitle: Text(
          _formatTimestamp(timestamp),
          style: AppTheme.caption,
        ),
        trailing: Text(
          '${isPositive ? '+' : ''}RM ${amount.abs().toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontWeight: AppTheme.semibold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    try {
      DateTime date;
      if (timestamp is String) {
        date = DateTime.parse(timestamp);
      } else if (timestamp is Timestamp) {
        date = timestamp.toDate();
      } else {
        return 'Just now';
      }
      return DateFormat('yyyy-MM-dd HH:mm').format(date);
    } catch (e) {
      return 'Just now';
    }
  }

  void _showDepositDialog() {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Top Up'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount',
                prefixText: 'RM ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            const Text(
              'Amount will be added to your wallet balance',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.neutral600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          BBXPrimaryButton(
            text: 'Confirm',
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0) {
                _processDeposit(amount);
                Navigator.pop(context);
              }
            },
            height: 40,
          ),
        ],
      ),
    );
  }

  void _showWithdrawDialog() {
    final amountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount',
                prefixText: 'RM ',
                border: const OutlineInputBorder(),
                helperText: 'Balance: RM ${balance.toStringAsFixed(2)}',
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            const Text(
              'Withdrawal will be processed in 1-3 working days',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.neutral600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          BBXPrimaryButton(
            text: 'Confirm',
            onPressed: () {
              final amount = double.tryParse(amountController.text) ?? 0;
              if (amount > 0 && amount <= balance) {
                _processWithdraw(amount);
                Navigator.pop(context);
              } else if (amount > balance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Insufficient balance')),
                );
              }
            },
            height: 40,
          ),
        ],
      ),
    );
  }

  Future<void> _processDeposit(double amount) async {
        setState(() {
      balance += amount;
      transactions.insert(0, {
        'type': 'deposit',
        'amount': amount,
        'description': 'Top Up',
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Top Up Successful'),
        backgroundColor: AppTheme.success,
      ),
    );
  }

  Future<void> _processWithdraw(double amount) async {
        setState(() {
      balance -= amount;
      transactions.insert(0, {
        'type': 'withdraw',
        'amount': -amount,
        'description': 'Withdrawal',
        'timestamp': DateTime.now().toIso8601String(),
      });
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Withdrawal Request Submitted'),
        backgroundColor: AppTheme.success,
      ),
    );
  }
}
