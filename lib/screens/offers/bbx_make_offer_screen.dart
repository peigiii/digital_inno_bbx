import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/listing_model.dart';
import '../../services/offer_service.dart';

/// 提交报价页面
class BBXMakeOfferScreen extends StatefulWidget {
  final ListingModel listing;

  const BBXMakeOfferScreen({
    super.key,
    required this.listing,
  });

  @override
  State<BBXMakeOfferScreen> createState() => _BBXMakeOfferScreenState();
}

class _BBXMakeOfferScreenState extends State<BBXMakeOfferScreen> {
  final _formKey = GlobalKey<FormState>();
  final _offerPriceController = TextEditingController();
  final _messageController = TextEditingController();
  final _offerService = OfferService();

  DateTime? _scheduledPickupDate;
  String _deliveryMethod = 'self_pickup';
  bool _isLoading = false;
  double? _discountPercentage;

  @override
  void dispose() {
    _offerPriceController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// 计算折扣百分比
  void _calculateDiscount() {
    final offerPrice = double.tryParse(_offerPriceController.text);
    if (offerPrice != null && widget.listing.pricePerUnit > 0) {
      setState(() {
        _discountPercentage = ((widget.listing.pricePerUnit - offerPrice) / widget.listing.pricePerUnit * 100);
      });
    } else {
      setState(() {
        _discountPercentage = null;
      });
    }
  }

  /// 选择收集日期
  Future<void> _selectPickupDate() async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final maxDate = now.add(const Duration(days: 30));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: tomorrow,
      firstDate: tomorrow,
      lastDate: maxDate,
      helpText: '选择预计收集日期',
      cancelText: '取消',
      confirmText: '确定',
    );

    if (pickedDate != null) {
      setState(() {
        _scheduledPickupDate = pickedDate;
      });
    }
  }

  /// 提交报价
  Future<void> _submitOffer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final offerPrice = double.parse(_offerPriceController.text);

    setState(() {
      _isLoading = true;
    });

    try {
      await _offerService.createOffer(
        listingId: widget.listing.id,
        sellerId: widget.listing.userId,
        offerPrice: offerPrice,
        originalPrice: widget.listing.pricePerUnit,
        message: _messageController.text.trim(),
        scheduledPickupDate: _scheduledPickupDate,
        deliveryMethod: _deliveryMethod,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('报价已提交，等待卖家回复'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败：$e'),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('提交报价'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 商品信息卡片
            _buildListingCard(),
            const SizedBox(height: 24),

            // 报价金额
            _buildOfferPriceField(),
            const SizedBox(height: 24),

            // 预计收集日期
            _buildPickupDateField(),
            const SizedBox(height: 24),

            // 收集方式
            _buildDeliveryMethodSection(),
            const SizedBox(height: 24),

            // 附加消息
            _buildMessageField(),
            const SizedBox(height: 24),

            // 提示信息
            _buildHintBox(),
            const SizedBox(height: 24),

            // 提交按钮
            _buildSubmitButton(),
          ],
        ),
      ),
    );
  }

  /// 商品信息卡片
  Widget _buildListingCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.listing.title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.inventory_2, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  '${widget.listing.quantity} ${widget.listing.unit}',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(width: 24),
                const Icon(Icons.attach_money, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'RM ${widget.listing.pricePerUnit.toStringAsFixed(2)}/${widget.listing.unit}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 报价金额输入框
  Widget _buildOfferPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '报价金额 *',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _offerPriceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            prefixText: 'RM ',
            suffixText: '/${widget.listing.unit}',
            hintText: '输入您的报价',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入报价金额';
            }
            final price = double.tryParse(value);
            if (price == null || price <= 0) {
              return '请输入有效的金额';
            }
            return null;
          },
          onChanged: (value) {
            _calculateDiscount();
          },
        ),
        if (_discountPercentage != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _discountPercentage! > 0 ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  _discountPercentage! > 0 ? Icons.trending_down : Icons.trending_up,
                  size: 16,
                  color: _discountPercentage! > 0 ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  _discountPercentage! > 0
                      ? '折扣 ${_discountPercentage!.toStringAsFixed(1)}%'
                      : '高于原价 ${(-_discountPercentage!).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: _discountPercentage! > 0 ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// 预计收集日期选择器
  Widget _buildPickupDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '预计收集日期',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _selectPickupDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  _scheduledPickupDate != null
                      ? DateFormat('yyyy年MM月dd日').format(_scheduledPickupDate!)
                      : '选择日期',
                  style: TextStyle(
                    fontSize: 16,
                    color: _scheduledPickupDate != null ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// 收集方式选择
  Widget _buildDeliveryMethodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '收集方式',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        RadioListTile<String>(
          title: const Text('自行收集'),
          subtitle: const Text('买家自行到卖家地点收集'),
          value: 'self_pickup',
          groupValue: _deliveryMethod,
          onChanged: (value) {
            setState(() {
              _deliveryMethod = value!;
            });
          },
        ),
        RadioListTile<String>(
          title: const Text('使用平台物流'),
          subtitle: const Text('通过平台合作物流公司运输'),
          value: 'platform_logistics',
          groupValue: _deliveryMethod,
          onChanged: (value) {
            setState(() {
              _deliveryMethod = value!;
            });
          },
        ),
        RadioListTile<String>(
          title: const Text('卖家送货'),
          subtitle: const Text('由卖家安排送货到指定地点'),
          value: 'seller_delivery',
          groupValue: _deliveryMethod,
          onChanged: (value) {
            setState(() {
              _deliveryMethod = value!;
            });
          },
        ),
      ],
    );
  }

  /// 附加消息输入框
  Widget _buildMessageField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '附加消息（可选）',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _messageController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: '向卖家说明您的需求或其他信息...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ],
    );
  }

  /// 提示信息框
  Widget _buildHintBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '温馨提示',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '• 报价有效期为 48 小时\n'
                  '• 卖家可能接受、拒绝或还价\n'
                  '• 请确保您的报价合理',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.blue.shade900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 提交按钮
  Widget _buildSubmitButton() {
    return SizedBox(
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitOffer,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
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
            : const Text(
                '提交报价',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
              ),
      ),
    );
  }
}
