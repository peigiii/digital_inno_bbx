import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_loading.dart';
import '../../widgets/bbx_empty_state.dart';

/// BBX 优惠券页�?
class BBXCouponsScreen extends StatefulWidget {
  const BBXCouponsScreen({super.key});

  @override
  State<BBXCouponsScreen> createState() => _BBXCouponsScreenState();
}

class _BBXCouponsScreenState extends State<BBXCouponsScreen>
    with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  late TabController _tabController;
  bool isLoading = true;

  List<Map<String, dynamic>> availableCoupons = [];
  List<Map<String, dynamic>> usedCoupons = [];
  List<Map<String, dynamic>> expiredCoupons = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadCoupons();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCoupons() async {
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final couponsSnapshot = await FirebaseFirestore.instance
          .collection('coupons')
          .where('userId', isEqualTo: user!.uid)
          .get();

      final now = DateTime.now();

      setState(() {
        availableCoupons = [];
        usedCoupons = [];
        expiredCoupons = [];

        for (var doc in couponsSnapshot.docs) {
          final data = doc.data();
          data['id'] = doc.id;

          final expiryDate = (data['expiryDate'] as Timestamp).toDate();
          final status = data['status'] as String;

          if (status == 'used') {
            usedCoupons.add(data);
          } else if (expiryDate.isBefore(now)) {
            expiredCoupons.add(data);
          } else {
            availableCoupons.add(data);
          }
        }

        isLoading = false;
      });
    } catch (e) {
      debugPrint('加载优惠券失�? $e');
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('我的优惠�?),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primary500,
          unselectedLabelColor: AppTheme.neutral600,
          indicatorColor: AppTheme.primary500,
          tabs: [
            Tab(text: '可用 (${availableCoupons.length})'),
            Tab(text: '已使�?(${usedCoupons.length})'),
            Tab(text: '已过�?(${expiredCoupons.length})'),
          ],
        ),
      ),
      body: isLoading
          ? const Center(child: BBXFullScreenLoading())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCouponList(availableCoupons, 'available'),
                _buildCouponList(usedCoupons, 'used'),
                _buildCouponList(expiredCoupons, 'expired'),
              ],
            ),
    );
  }

  Widget _buildCouponList(List<Map<String, dynamic>> coupons, String type) {
    if (coupons.isEmpty) {
      return BBXEmptyState(
        icon: Icons.confirmation_number_outlined,
        title: type == 'available'
            ? '暂无可用优惠�?
            : type == 'used'
                ? '暂无已使用优惠券'
                : '暂无过期优惠�?,
        description: type == 'available' ? '完成任务获取更多优惠�? : null,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.spacing16),
      itemCount: coupons.length,
      itemBuilder: (context, index) {
        final coupon = coupons[index];
        return _buildCouponCard(coupon, type);
      },
    );
  }

  Widget _buildCouponCard(Map<String, dynamic> coupon, String type) {
    final discount = coupon['discount'] as int;
    final discountType = coupon['discountType'] as String; // 'fixed' or 'percentage'
    final minAmount = (coupon['minAmount'] as num?)?.toDouble() ?? 0;
    final expiryDate = (coupon['expiryDate'] as Timestamp).toDate();
    final title = coupon['title'] as String? ?? '优惠�?;
    final description = coupon['description'] as String? ?? '';

    final isAvailable = type == 'available';
    final isExpired = type == 'expired';

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spacing12),
      decoration: BoxDecoration(
        borderRadius: AppTheme.borderRadiusMedium,
        boxShadow: AppTheme.shadowMedium,
      ),
      child: ClipRRect(
        borderRadius: AppTheme.borderRadiusMedium,
        child: Stack(
          children: [
            // 背景渐变
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isExpired
                      ? [AppTheme.neutral300, AppTheme.neutral200]
                      : [AppTheme.error, const Color(0xFFE91E63)],
                ),
              ),
              child: Row(
                children: [
                  // 左侧：折扣金�?
                  Container(
                    width: 120,
                    padding: const EdgeInsets.all(AppTheme.spacing16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          discountType == 'fixed'
                              ? 'RM $discount'
                              : '$discount%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: AppTheme.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          discountType == 'fixed' ? '优惠' : '折扣',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // 中间虚线分隔
                  CustomPaint(
                    size: const Size(1, 100),
                    painter: _DashedLinePainter(),
                  ),

                  // 右侧：优惠券信息
                  Expanded(
                    child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.all(AppTheme.spacing16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: AppTheme.heading4,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (description.isNotEmpty)
                            Text(
                              description,
                              style: AppTheme.caption,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 8),
                          Text(
                            '�?RM ${minAmount.toStringAsFixed(0)} 可用',
                            style: AppTheme.caption.copyWith(
                              color: AppTheme.neutral600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: isExpired
                                    ? AppTheme.error
                                    : AppTheme.neutral600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '有效期至 ${DateFormat('yyyy-MM-dd').format(expiryDate)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: isExpired
                                      ? AppTheme.error
                                      : AppTheme.neutral600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 使用状态标�?
            if (!isAvailable)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isExpired ? AppTheme.neutral500 : AppTheme.success,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isExpired ? '已过�? : '已使�?,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: AppTheme.bold,
                    ),
                  ),
                ),
              ),

            // 使用按钮（仅可用优惠券显示）
            if (isAvailable)
              Positioned(
                bottom: 8,
                right: 8,
                child: TextButton(
                  onPressed: () => _useCoupon(coupon['id']),
                  style: TextButton.styleFrom(
                    backgroundColor: AppTheme.primary500,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: const Text(
                    '立即使用',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _useCoupon(String couponId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('使用优惠�?),
        content: const Text('确定要使用这张优惠券吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              // TODO: 实现优惠券使用逻辑
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('优惠券已应用'),
                  backgroundColor: AppTheme.success,
                ),
              );
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

/// 虚线绘制�?
class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 1;

    const dashHeight = 5.0;
    const dashSpace = 3.0;
    double startY = 0;

    while (startY < size.height) {
      canvas.drawLine(
        Offset(0, startY),
        Offset(0, startY + dashHeight),
        paint,
      );
      startY += dashHeight + dashSpace;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
