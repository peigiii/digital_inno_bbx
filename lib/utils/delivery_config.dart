import 'package:flutter/material.dart';

/// 配送方式配置类
class DeliveryConfig {
  /// 配送方式配�?
  static const Map<String, Map<String, dynamic>> methods = {
    'self_collect': {
      'label': '自提',
      'icon': Icons.store,
      'color': Color(0xFF4CAF50), // 绿色
      'description': '到卖家指定地点取�?,
    },
    'delivery': {
      'label': '邮寄',
      'icon': Icons.local_shipping,
      'color': Color(0xFF2196F3), // 蓝色
      'description': '卖家安排快递配�?,
    },
  };

  /// 快递公司列�?
  static const List<String> courierCompanies = [
    'Pos Laju',
    'J&T Express',
    'GDex',
    'Ninja Van',
    'DHL',
    'City-Link Express',
    'ABX Express',
    'Skynet',
    '其他',
  ];

  /// 获取配送方式标�?
  static String getLabel(String method) {
    return methods[method]?['label'] ?? method;
  }

  /// 获取配送方式图�?
  static IconData getIcon(String method) {
    return methods[method]?['icon'] ?? Icons.local_shipping;
  }

  /// 获取配送方式颜�?
  static Color getColor(String method) {
    return methods[method]?['color'] ?? Colors.grey;
  }

  /// 获取配送方式描�?
  static String getDescription(String method) {
    return methods[method]?['description'] ?? '';
  }

  /// 是否是自�?
  static bool isSelfCollect(String? method) {
    return method == 'self_collect';
  }

  /// 是否是邮�?
  static bool isDelivery(String? method) {
    return method == 'delivery';
  }

  /// 构建配送方式标签组�?
  static Widget buildMethodChip(String method, {bool small = false}) {
    final config = methods[method];
    if (config == null) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 8,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: (config['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (config['color'] as Color).withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            config['icon'] as IconData,
            size: small ? 12 : 14,
            color: config['color'] as Color,
          ),
          SizedBox(width: small ? 3 : 4),
          Text(
            config['label'] as String,
            style: TextStyle(
              fontSize: small ? 11 : 12,
              color: config['color'] as Color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建邮费提示组件
  static Widget buildShippingFeeNote() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '邮费需与卖家协�?额外支付)',
              style: TextStyle(
                color: Colors.orange[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
