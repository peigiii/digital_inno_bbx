import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../models/listing_model.dart';
import '../../services/offer_service.dart';

/// BBX 报价底部弹窗 - 现代化设�?
/// 适配 Pixel 5, Material Design 3
class BBXOptimizedMakeOfferBottomSheet extends StatefulWidget {
  final ListingModel listing;

  const BBXOptimizedMakeOfferBottomSheet({
    super.key,
    required this.listing,
  });

  static Future<void> show(BuildContext context, ListingModel listing) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BBXOptimizedMakeOfferBottomSheet(listing: listing),
    );
  }

  @override
  State<BBXOptimizedMakeOfferBottomSheet> createState() =>
      _BBXOptimizedMakeOfferBottomSheetState();
}

class _BBXOptimizedMakeOfferBottomSheetState
    extends State<BBXOptimizedMakeOfferBottomSheet>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _offerPriceController = TextEditingController();
  final _messageController = TextEditingController();
  final _offerService = OfferService();

  DateTime? _scheduledPickupDate;
  String _deliveryMethod = 'self_pickup';
  bool _isLoading = false;
  double? _discountPercentage;
  bool _showDetails = false;

  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _offerPriceController.dispose();
    _messageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _calculateDiscount() {
    final offerPrice = double.tryParse(_offerPriceController.text);
    if (offerPrice != null && widget.listing.pricePerUnit > 0) {
      setState(() {
        _discountPercentage =
            ((widget.listing.pricePerUnit - offerPrice) /
                widget.listing.pricePerUnit *
                100);
      });
    } else {
      setState(() {
        _discountPercentage = null;
      });
    }
  }

  Future<void> _selectPickupDate() async {
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final maxDate = now.add(const Duration(days: 30));

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: tomorrow,
      firstDate: tomorrow,
      lastDate: maxDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary500,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: AppTheme.neutral900,
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null) {
      setState(() {
        _scheduledPickupDate = pickedDate;
      });
    }
  }

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
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppTheme.success,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('报价已提交，等待卖家回复'),
                ),
              ],
            ),
            backgroundColor: AppTheme.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('提交失败�?e'),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
            ),
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
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.9;

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(_slideAnimation),
      child: Container(
        constraints: BoxConstraints(maxHeight: maxHeight),
        decoration: const BoxDecoration(
          color: AppTheme.background,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppTheme.radiusXLarge),
            topRight: Radius.circular(AppTheme.radiusXLarge),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 顶部手柄和标�?
            _buildHeader(),

            // 内容区域（可滚动�?
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  bottom: mediaQuery.viewInsets.bottom + AppTheme.spacing16,
                ),
                child: Form(
                  key: _formKey,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Column(
                      children: [
                        // 商品信息卡片
                        _buildListingCard(),

                        // 报价输入区域
                        _buildOfferPriceSection(),

                        // 其他选项（可展开�?
                        _buildOptionalSection(),

                        // 提交按钮
                        _buildSubmitButton(),

                        const SizedBox(height: AppTheme.spacing16),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 顶部手柄和标�?
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppTheme.spacing12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radiusXLarge),
          topRight: Radius.circular(AppTheme.radiusXLarge),
        ),
      ),
      child: Column(
        children: [
          // 拖动手柄
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.neutral300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: AppTheme.spacing12),

          // 标题
          Row(
            children: [
              const SizedBox(width: AppTheme.spacing16),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.close_rounded,
                  color: AppTheme.neutral700,
                ),
              ),
              const Expanded(
                child: Text(
                  '提交报价',
                  style: AppTheme.heading3,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 56),
            ],
          ),
        ],
      ),
    );
  }

  /// 商品信息卡片
  Widget _buildListingCard() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacing16),
      padding: const EdgeInsets.all(AppTheme.spacing16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusLarge,
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Row(
        children: [
          // 商品图片
          ClipRRect(
            borderRadius: AppTheme.borderRadiusMedium,
            child: Image.network(
              widget.listing.imageUrls.isNotEmpty
                  ? widget.listing.imageUrls.first
                  : '',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  width: 80,
                  height: 80,
                  color: AppTheme.neutral100,
                  child: const Icon(
                    Icons.image_not_supported_rounded,
                    color: AppTheme.neutral400,
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: AppTheme.spacing12),

          // 商品信息
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.listing.title,
                  style: AppTheme.heading4,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppTheme.spacing4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.getCategoryColor(widget.listing.wasteType)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
                  ),
                  child: Text(
                    widget.listing.wasteType,
                    style: TextStyle(
                      color: AppTheme.getCategoryColor(widget.listing.wasteType),
                      fontSize: 11,
                      fontWeight: AppTheme.semibold,
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.spacing8),
                Text(
                  '原价：RM ${widget.listing.pricePerUnit.toStringAsFixed(2)}/${widget.listing.unit}',
                  style: AppTheme.body2.copyWith(
                    color: AppTheme.neutral600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 报价输入区域
  Widget _buildOfferPriceSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppTheme.spacing16),
      padding: const EdgeInsets.all(AppTheme.spacing20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppTheme.borderRadiusLarge,
        border: Border.all(color: AppTheme.info.withOpacity(0.2), width: 2),
      ),
      child: Column(
        children: [
          // 标题
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.info.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_offer_rounded,
                  color: AppTheme.info,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.spacing12),
              const Text(
                '您的报价',
                style: AppTheme.heading4,
              ),
            ],
          ),

          const SizedBox(height: AppTheme.spacing20),

          // 报价输入�?
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'RM',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: AppTheme.bold,
                  color: AppTheme.neutral700,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _offerPriceController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(
                    fontSize: 48,
                    fontWeight: AppTheme.bold,
                    color: AppTheme.primary700,
                    height: 1.0,
                  ),
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    hintText: '0.00',
                    hintStyle: TextStyle(
                      fontSize: 48,
                      fontWeight: AppTheme.bold,
                      color: AppTheme.neutral300,
                    ),
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入报价金�?;
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
              ),
              Text(
                '/${widget.listing.unit}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: AppTheme.medium,
                  color: AppTheme.neutral600,
                ),
              ),
            ],
          ),

          // 折扣显示
          if (_discountPercentage != null) ...[
            const SizedBox(height: AppTheme.spacing16),
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacing16,
                vertical: AppTheme.spacing8,
              ),
              decoration: BoxDecoration(
                color: _discountPercentage! > 0
                    ? AppTheme.success
                    : AppTheme.warning,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _discountPercentage! > 0
                        ? Icons.trending_down_rounded
                        : Icons.trending_up_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _discountPercentage! > 0
                        ? '折扣 ${_discountPercentage!.toStringAsFixed(1)}%'
                        : '高于原价 ${(-_discountPercentage!).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: AppTheme.semibold,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // 快捷选项
          const SizedBox(height: AppTheme.spacing16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildQuickOptionChip('原价', widget.listing.pricePerUnit),
              _buildQuickOptionChip(
                  '-5%', widget.listing.pricePerUnit * 0.95),
              _buildQuickOptionChip(
                  '-10%', widget.listing.pricePerUnit * 0.90),
              _buildQuickOptionChip(
                  '-15%', widget.listing.pricePerUnit * 0.85),
            ],
          ),
        ],
      ),
    );
  }

  /// 快捷选项按钮
  Widget _buildQuickOptionChip(String label, double price) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _offerPriceController.text = price.toStringAsFixed(2);
          _calculateDiscount();
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacing12,
          vertical: AppTheme.spacing8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(color: AppTheme.info.withOpacity(0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppTheme.info,
            fontSize: 13,
            fontWeight: AppTheme.semibold,
          ),
        ),
      ),
    );
  }

  /// 可选项区域
  Widget _buildOptionalSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppTheme.spacing16,
        AppTheme.spacing16,
        AppTheme.spacing16,
        0,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppTheme.borderRadiusLarge,
        border: Border.all(color: AppTheme.neutral200),
      ),
      child: Column(
        children: [
          // 展开/收起按钮
          InkWell(
            onTap: () {
              setState(() {
                _showDetails = !_showDetails;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Row(
                children: [
                  const Icon(
                    Icons.settings_suggest_rounded,
                    color: AppTheme.neutral700,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      '更多选项（可选）',
                      style: AppTheme.body1,
                    ),
                  ),
                  Icon(
                    _showDetails
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: AppTheme.neutral700,
                  ),
                ],
              ),
            ),
          ),

          // 展开的详细选项
          if (_showDetails) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 预计收集日期
                  InkWell(
                    onTap: _selectPickupDate,
                    child: Container(
                      padding: const EdgeInsets.all(AppTheme.spacing12),
                      decoration: BoxDecoration(
                        color: AppTheme.neutral50,
                        borderRadius: AppTheme.borderRadiusMedium,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            color: AppTheme.primary500,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '预计收集日期',
                                  style: AppTheme.caption.copyWith(
                                    color: AppTheme.neutral600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  _scheduledPickupDate != null
                                      ? DateFormat('yyyy年MM月dd�?)
                                          .format(_scheduledPickupDate!)
                                      : '选择日期',
                                  style: AppTheme.body2.copyWith(
                                    fontWeight: AppTheme.medium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppTheme.neutral500,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppTheme.spacing16),

                  // 附加消息
                  TextFormField(
                    controller: _messageController,
                    maxLines: 3,
                    maxLength: 200,
                    decoration: InputDecoration(
                      labelText: '附加消息',
                      hintText: '向卖家说明您的需�?..',
                      border: OutlineInputBorder(
                        borderRadius: AppTheme.borderRadiusMedium,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppTheme.borderRadiusMedium,
                        borderSide: const BorderSide(color: AppTheme.neutral300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppTheme.borderRadiusMedium,
                        borderSide:
                            const BorderSide(color: AppTheme.primary500, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 提交按钮
  Widget _buildSubmitButton() {
    return Container(
      margin: const EdgeInsets.all(AppTheme.spacing16),
      height: 56,
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary500.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _submitOffer,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Center(
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                      SizedBox(width: 8),
                      Text(
                        '提交报价',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: AppTheme.bold,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

