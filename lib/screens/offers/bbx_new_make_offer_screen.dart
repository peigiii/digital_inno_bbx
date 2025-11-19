import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_button.dart';
import '../../widgets/bbx_chip.dart';
import '../../widgets/bbx_notification.dart';
import '../../models/listing_model.dart';

/// BBX 提交报价页面（完全重构 - 底部弹窗）
class BBXNewMakeOfferScreen extends StatefulWidget {
  final Listing listing;

  const BBXNewMakeOfferScreen({
    super.key,
    required this.listing,
  });

  @override
  State<BBXNewMakeOfferScreen> createState() => _BBXNewMakeOfferScreenState();
}

class _BBXNewMakeOfferScreenState extends State<BBXNewMakeOfferScreen> {
  final TextEditingController _offerController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();
  DateTime? _pickupDate;
  String _deliveryMethod = 'pickup'; // pickup 或 delivery
  String? _selectedQuickAmount;
  bool _isSubmitting = false;

  double get _offerAmount {
    return double.tryParse(_offerController.text) ?? 0.0;
  }

  double get _discount {
    if (_offerAmount == 0 || widget.listing.pricePerUnit == 0) return 0;
    return ((widget.listing.pricePerUnit - _offerAmount) /
            widget.listing.pricePerUnit * 100);
  }

  Color get _discountColor {
    if (_discount < 5) return AppTheme.neutral500;
    if (_discount < 10) return AppTheme.warning;
    if (_discount < 20) return AppTheme.success;
    return AppTheme.error;
  }

  double get _totalAmount {
    final platformFee = _offerAmount * 0.03;
    return _offerAmount + platformFee;
  }

  @override
  void dispose() {
    _offerController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXLarge),
          topRight: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 顶部手柄
          Container(
            margin: const EdgeInsets.only(top: AppTheme.spacing12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.neutral400,
              borderRadius: BorderRadius.circular(AppTheme.radiusFull),
            ),
          ),

          // 标题栏
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacing16),
            child: Row(
              children: [
                const Text('提交报价', style: AppTheme.heading2),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  color: AppTheme.neutral600,
                ),
              ],
            ),
          ),

          // 内容区域
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 商品信息卡片
                  _buildListingCard(),

                  const SizedBox(height: AppTheme.spacing24),

                  // 报价金额输入
                  _buildOfferAmountInput(),

                  const SizedBox(height: AppTheme.spacing16),

                  // 快捷金额选择
                  _buildQuickAmounts(),

                  const SizedBox(height: AppTheme.spacing24),

                  // 收货信息
                  _buildDeliveryInfo(),

                  const SizedBox(height: AppTheme.spacing24),

                  // 留言
                  _buildMessage(),

                  const SizedBox(height: AppTheme.spacing24),

                  // 价格明细
                  _buildPriceDetails(),
                ],
              ),
            ),
          ),

          // 底部操作区
          _buildBottomAction(),
        ],
      ),
    );
  }

  /// 商品信息卡片
  Widget _buildListingCard() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing12),
      decoration: BoxDecoration(
        color: AppTheme.neutral100,
        borderRadius: AppTheme.borderRadiusMedium,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppTheme.borderRadiusMedium,
            child: Image.network(
              widget.listing.images.isNotEmpty ? widget.listing.images.first : '',
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                color: AppTheme.neutral200,
              ),
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.listing.title,
                  style: AppTheme.body1,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      'RM ${widget.listing.pricePerUnit.toStringAsFixed(2)}',
                      style: AppTheme.caption.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: AppTheme.neutral500,
                      ),
                    ),
                    const SizedBox(width: AppTheme.spacing8),
                    Text(
                      'RM ${widget.listing.pricePerUnit.toStringAsFixed(2)}',
                      style: AppTheme.heading4.copyWith(
                        color: AppTheme.primary500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 报价金额输入
  Widget _buildOfferAmountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('您的报价', style: AppTheme.heading3),
        const SizedBox(height: AppTheme.spacing12),
        Container(
          height: 80,
          decoration: BoxDecoration(
            border: Border.all(color: AppTheme.neutral300),
            borderRadius: AppTheme.borderRadiusLarge,
          ),
          child: TextField(
            controller: _offerController,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 40,
              fontWeight: AppTheme.bold,
              color: AppTheme.primary500,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: '0.00',
              prefixText: 'RM ',
              prefixStyle: TextStyle(
                fontSize: 40,
                fontWeight: AppTheme.bold,
                color: AppTheme.primary500,
              ),
            ),
            onChanged: (value) {
              setState(() {
                _selectedQuickAmount = null;
              });
            },
          ),
        ),
        if (_offerAmount > 0) ...[
          const SizedBox(height: AppTheme.spacing8),
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing12,
                vertical: AppTheme.spacing4,
              ),
              decoration: BoxDecoration(
                color: _discountColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Text(
                '比原价${_discount >= 0 ? "低" : "高"} ${_discount.abs().toStringAsFixed(1)}%',
                style: AppTheme.caption.copyWith(
                  color: _discountColor,
                  fontWeight: AppTheme.semibold,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// 快捷金额选择
  Widget _buildQuickAmounts() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('快捷选择', style: AppTheme.body2),
        const SizedBox(height: AppTheme.spacing12),
        Row(
          children: [
            Expanded(
              child: _buildQuickAmountButton('原价9折', 0.9),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: _buildQuickAmountButton('原价8折', 0.8),
            ),
            const SizedBox(width: AppTheme.spacing8),
            Expanded(
              child: _buildQuickAmountButton('原价7折', 0.7),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickAmountButton(String label, double discount) {
    final isSelected = _selectedQuickAmount == label;
    final amount = widget.listing.pricePerUnit * discount;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedQuickAmount = label;
          _offerController.text = amount.toStringAsFixed(2);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary500 : AppTheme.neutral100,
          borderRadius: AppTheme.borderRadiusMedium,
        ),
        child: Text(
          label,
          style: AppTheme.body2.copyWith(
            color: isSelected ? Colors.white : AppTheme.neutral700,
            fontWeight: isSelected ? AppTheme.semibold : AppTheme.regular,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  /// 收货信息
  Widget _buildDeliveryInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('收货信息', style: AppTheme.heading3),
        const SizedBox(height: AppTheme.spacing12),

        // 收货日期
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today_rounded, color: AppTheme.primary500),
          title: const Text('收货日期', style: AppTheme.body1),
          trailing: Text(
            _pickupDate != null
                ? '${_pickupDate!.month}月${_pickupDate!.day}日'
                : '选择日期',
            style: AppTheme.body2.copyWith(
              color: AppTheme.neutral600,
            ),
          ),
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (date != null) {
              setState(() {
                _pickupDate = date;
              });
            }
          },
        ),

        const Divider(),

        // 收货方式
        const Text('收货方式', style: AppTheme.body1),
        const SizedBox(height: AppTheme.spacing8),
        RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          value: 'pickup',
          groupValue: _deliveryMethod,
          onChanged: (value) {
            setState(() {
              _deliveryMethod = value!;
            });
          },
          title: Row(
            children: [
              const Icon(Icons.directions_car_rounded, size: 20),
              const SizedBox(width: AppTheme.spacing8),
              const Text('自提'),
            ],
          ),
        ),
        RadioListTile<String>(
          contentPadding: EdgeInsets.zero,
          value: 'delivery',
          groupValue: _deliveryMethod,
          onChanged: (value) {
            setState(() {
              _deliveryMethod = value!;
            });
          },
          title: Row(
            children: [
              const Icon(Icons.local_shipping_rounded, size: 20),
              const SizedBox(width: AppTheme.spacing8),
              const Text('送货'),
              const SizedBox(width: AppTheme.spacing8),
              Text(
                '(可能加收费用)',
                style: AppTheme.caption.copyWith(
                  color: AppTheme.warning,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 留言
  Widget _buildMessage() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('留言', style: AppTheme.heading3),
            const SizedBox(width: AppTheme.spacing8),
            Text(
              '(可选)',
              style: AppTheme.caption.copyWith(
                color: AppTheme.neutral500,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppTheme.spacing12),
        TextField(
          controller: _messageController,
          maxLines: 3,
          maxLength: 200,
          decoration: const InputDecoration(
            hintText: '向卖家说明您的需求...',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  /// 价格明细
  Widget _buildPriceDetails() {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      title: const Text('价格明细', style: AppTheme.body1),
      children: [
        Container(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          decoration: BoxDecoration(
            color: AppTheme.neutral50,
            borderRadius: AppTheme.borderRadiusMedium,
          ),
          child: Column(
            children: [
              _buildPriceRow('报价金额', _offerAmount),
              const SizedBox(height: AppTheme.spacing8),
              _buildPriceRow('平台服务费 (3%)', _offerAmount * 0.03),
              const Divider(height: AppTheme.spacing24),
              _buildPriceRow(
                '预计总额',
                _totalAmount,
                isTotal: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTheme.heading4
              : AppTheme.body2.copyWith(color: AppTheme.neutral600),
        ),
        Text(
          'RM ${amount.toStringAsFixed(2)}',
          style: isTotal
              ? AppTheme.heading3.copyWith(color: AppTheme.primary500)
              : AppTheme.body2,
        ),
      ],
    );
  }

  /// 底部操作区
  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppTheme.neutral300, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('预计总额', style: AppTheme.body1),
                Text(
                  'RM ${_totalAmount.toStringAsFixed(2)}',
                  style: AppTheme.heading2.copyWith(
                    color: AppTheme.primary500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.spacing12),
            BBXPrimaryButton(
              text: '提交报价',
              isLoading: _isSubmitting,
              onPressed: _offerAmount > 0 && _pickupDate != null
                  ? _submitOffer
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  /// 提交报价
  Future<void> _submitOffer() async {
    if (_offerAmount == 0) {
      BBXNotification.showError(context, '请输入报价金额');
      return;
    }

    if (_pickupDate == null) {
      BBXNotification.showError(context, '请选择收货日期');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw '请先登录';

      await FirebaseFirestore.instance.collection('offers').add({
        'listingId': widget.listing.id,
        'sellerId': widget.listing.userId,
        'buyerId': user.uid,
        'offerPrice': _offerAmount,
        'originalPrice': widget.listing.pricePerUnit,
        'quantity': widget.listing.quantity,
        'totalAmount': _totalAmount,
        'deliveryMethod': _deliveryMethod,
        'pickupDate': Timestamp.fromDate(_pickupDate!),
        'message': _messageController.text,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      // 显示成功对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppTheme.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: AppTheme.success,
                ),
              ),
              const SizedBox(height: AppTheme.spacing16),
              const Text('报价已提交', style: AppTheme.heading2),
              const SizedBox(height: AppTheme.spacing8),
              const Text(
                '卖家将在24小时内回复',
                style: AppTheme.body2,
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            BBXPrimaryButton(
              text: '查看我的报价',
              onPressed: () {
                Navigator.pop(context); // 关闭对话框
                Navigator.pop(context); // 关闭报价页面
                Navigator.pushNamed(context, '/my-offers');
              },
            ),
          ],
        ),
      );

      // 3秒后自动关闭
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          Navigator.pop(context); // 关闭对话框
          Navigator.pop(context); // 关闭报价页面
        }
      });
    } catch (e) {
      BBXNotification.showError(context, '提交失败：$e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
