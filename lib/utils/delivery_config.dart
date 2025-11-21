import 'package:flutter/material.dart';

/// Delivery Configuration Class
class DeliveryConfig {
  /// Delivery Method Configuration
  static const Map<String, Map<String, dynamic>> methods = {
    'self_collect': {
      'label': 'Self Collect',
      'icon': Icons.store,
      'color': Color(0xFF4CAF50), // Green
      'description': 'Collect from seller specified location',
    },
    'delivery': {
      'label': 'Delivery',
      'icon': Icons.local_shipping,
      'color': Color(0xFF2196F3), // Blue
      'description': 'Seller arranges courier delivery',
    },
  };

  /// Courier Companies List
  static const List<String> courierCompanies = [
    'Pos Laju',
    'J&T Express',
    'GDex',
    'Ninja Van',
    'DHL',
    'City-Link Express',
    'ABX Express',
    'Skynet',
    'Other',
  ];

  /// Get Delivery Method Label
  static String getLabel(String method) {
    return methods[method]?['label'] ?? method;
  }

  /// Get Delivery Method Icon
  static IconData getIcon(String method) {
    return methods[method]?['icon'] ?? Icons.local_shipping;
  }

  /// Get Delivery Method Color
  static Color getColor(String method) {
    return methods[method]?['color'] ?? Colors.grey;
  }

  /// Get Delivery Method Description
  static String getDescription(String method) {
    return methods[method]?['description'] ?? '';
  }

  /// Is Self Collect
  static bool isSelfCollect(String? method) {
    return method == 'self_collect';
  }

  /// Is Delivery
  static bool isDelivery(String? method) {
    return method == 'delivery';
  }

  /// Build Method Chip
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

  /// Build Shipping Fee Note
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
              'Shipping fee to be arranged with seller (Extra payment)',
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
