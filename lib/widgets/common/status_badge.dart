import 'package:flutter/material.dart';

/// A reusable status badge widget for displaying listing, offer, and transaction statuses.
class StatusBadge extends StatelessWidget {
  final String status;
  final bool showIcon;
  final double fontSize;

  const StatusBadge({
    Key? key,
    required this.status,
    this.showIcon = true,
    this.fontSize = 12,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig(status);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: config.bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(config.icon, size: fontSize + 2, color: config.textColor),
            const SizedBox(width: 4),
          ],
          Text(
            config.displayText,
            style: TextStyle(
              color: config.textColor,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _getStatusConfig(String status) {
    switch (status.toLowerCase()) {
      // Listing statuses
      case 'open':
      case 'available':
        return _StatusConfig(
          bgColor: const Color(0xFFE8F5E9),
          textColor: const Color(0xFF2E7D32),
          displayText: 'Available',
          icon: Icons.check_circle,
        );
      case 'pending':
        return _StatusConfig(
          bgColor: const Color(0xFFFFF3E0),
          textColor: const Color(0xFFE65100),
          displayText: 'Pending',
          icon: Icons.schedule,
        );
      case 'sold':
      case 'closed':
        return _StatusConfig(
          bgColor: const Color(0xFFFFEBEE),
          textColor: const Color(0xFFC62828),
          displayText: 'Sold',
          icon: Icons.sell,
        );
      case 'expired':
        return _StatusConfig(
          bgColor: const Color(0xFFEEEEEE),
          textColor: const Color(0xFF616161),
          displayText: 'Expired',
          icon: Icons.timer_off,
        );
      case 'deleted':
        return _StatusConfig(
          bgColor: const Color(0xFFFFEBEE),
          textColor: const Color(0xFFC62828),
          displayText: 'Deleted',
          icon: Icons.delete,
        );
        
      // Offer statuses
      case 'accepted':
        return _StatusConfig(
          bgColor: const Color(0xFFE8F5E9),
          textColor: const Color(0xFF2E7D32),
          displayText: 'Accepted',
          icon: Icons.check_circle,
        );
      case 'rejected':
      case 'declined':
        return _StatusConfig(
          bgColor: const Color(0xFFFFEBEE),
          textColor: const Color(0xFFC62828),
          displayText: 'Rejected',
          icon: Icons.cancel,
        );
      case 'countered':
        return _StatusConfig(
          bgColor: const Color(0xFFE3F2FD),
          textColor: const Color(0xFF1565C0),
          displayText: 'Countered',
          icon: Icons.swap_horiz,
        );
      case 'withdrawn':
        return _StatusConfig(
          bgColor: const Color(0xFFEEEEEE),
          textColor: const Color(0xFF616161),
          displayText: 'Withdrawn',
          icon: Icons.undo,
        );
        
      // Transaction statuses
      case 'processing':
        return _StatusConfig(
          bgColor: const Color(0xFFE3F2FD),
          textColor: const Color(0xFF1565C0),
          displayText: 'Processing',
          icon: Icons.hourglass_empty,
        );
      case 'completed':
        return _StatusConfig(
          bgColor: const Color(0xFFE8F5E9),
          textColor: const Color(0xFF2E7D32),
          displayText: 'Completed',
          icon: Icons.check_circle,
        );
      case 'cancelled':
        return _StatusConfig(
          bgColor: const Color(0xFFFFEBEE),
          textColor: const Color(0xFFC62828),
          displayText: 'Cancelled',
          icon: Icons.cancel,
        );
      case 'refunded':
        return _StatusConfig(
          bgColor: const Color(0xFFFFF3E0),
          textColor: const Color(0xFFE65100),
          displayText: 'Refunded',
          icon: Icons.replay,
        );
      case 'disputed':
        return _StatusConfig(
          bgColor: const Color(0xFFFCE4EC),
          textColor: const Color(0xFFC2185B),
          displayText: 'Disputed',
          icon: Icons.warning,
        );
        
      // Compliance statuses
      case 'approved':
        return _StatusConfig(
          bgColor: const Color(0xFFE8F5E9),
          textColor: const Color(0xFF2E7D32),
          displayText: 'Approved',
          icon: Icons.verified,
        );
      case 'under_review':
      case 'review':
        return _StatusConfig(
          bgColor: const Color(0xFFFFF3E0),
          textColor: const Color(0xFFE65100),
          displayText: 'Under Review',
          icon: Icons.pending,
        );
        
      // Payment statuses
      case 'paid':
        return _StatusConfig(
          bgColor: const Color(0xFFE8F5E9),
          textColor: const Color(0xFF2E7D32),
          displayText: 'Paid',
          icon: Icons.payment,
        );
      case 'unpaid':
        return _StatusConfig(
          bgColor: const Color(0xFFFFF3E0),
          textColor: const Color(0xFFE65100),
          displayText: 'Unpaid',
          icon: Icons.money_off,
        );
        
      // Shipping statuses
      case 'shipped':
        return _StatusConfig(
          bgColor: const Color(0xFFE3F2FD),
          textColor: const Color(0xFF1565C0),
          displayText: 'Shipped',
          icon: Icons.local_shipping,
        );
      case 'delivered':
        return _StatusConfig(
          bgColor: const Color(0xFFE8F5E9),
          textColor: const Color(0xFF2E7D32),
          displayText: 'Delivered',
          icon: Icons.check_circle,
        );
      case 'in_transit':
        return _StatusConfig(
          bgColor: const Color(0xFFE3F2FD),
          textColor: const Color(0xFF1565C0),
          displayText: 'In Transit',
          icon: Icons.local_shipping,
        );
        
      default:
        return _StatusConfig(
          bgColor: const Color(0xFFEEEEEE),
          textColor: const Color(0xFF616161),
          displayText: status,
          icon: Icons.info,
        );
    }
  }
}

class _StatusConfig {
  final Color bgColor;
  final Color textColor;
  final String displayText;
  final IconData icon;

  _StatusConfig({
    required this.bgColor,
    required this.textColor,
    required this.displayText,
    required this.icon,
  });
}

/// A compact status indicator (dot only)
class StatusDot extends StatelessWidget {
  final String status;
  final double size;

  const StatusDot({
    Key? key,
    required this.status,
    this.size = 10,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _getStatusColor(status),
        shape: BoxShape.circle,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
      case 'available':
      case 'accepted':
      case 'completed':
      case 'approved':
      case 'paid':
      case 'delivered':
        return const Color(0xFF2E7D32);
      case 'pending':
      case 'processing':
      case 'under_review':
      case 'unpaid':
      case 'refunded':
        return const Color(0xFFE65100);
      case 'sold':
      case 'closed':
      case 'rejected':
      case 'cancelled':
      case 'deleted':
        return const Color(0xFFC62828);
      case 'shipped':
      case 'in_transit':
      case 'countered':
        return const Color(0xFF1565C0);
      case 'disputed':
        return const Color(0xFFC2185B);
      default:
        return const Color(0xFF616161);
    }
  }
}

