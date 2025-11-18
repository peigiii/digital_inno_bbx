import 'package:cloud_firestore/cloud_firestore.dart';

/// 信用评分系统
///
/// 评分因素：
/// 1. 认证状态（+20分）
/// 2. 交易完成率（0-30分）
/// 3. 平均评分（0-25分）
/// 4. 响应速度（0-15分）
/// 5. 争议率（0-10分，争议越少分越高）
///
/// 总分：100分
class CreditScoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 计算用户信用评分
  Future<Map<String, dynamic>> calculateCreditScore(String userId) async {
    try {
      // 1. 认证状态评分 (0-20分)
      final verificationScore = await _getVerificationScore(userId);

      // 2. 交易完成率评分 (0-30分)
      final completionScore = await _getCompletionScore(userId);

      // 3. 平均评分 (0-25分)
      final reviewScore = await _getReviewScore(userId);

      // 4. 响应速度评分 (0-15分)
      final responseScore = await _getResponseScore(userId);

      // 5. 争议率评分 (0-10分)
      final disputeScore = await _getDisputeScore(userId);

      // 计算总分
      final totalScore = verificationScore +
          completionScore +
          reviewScore +
          responseScore +
          disputeScore;

      // 确定信用等级
      final creditLevel = _getCreditLevel(totalScore);

      return {
        'totalScore': totalScore.toInt(),
        'creditLevel': creditLevel['level'],
        'creditLabel': creditLevel['label'],
        'creditStars': creditLevel['stars'],
        'breakdown': {
          'verification': verificationScore.toInt(),
          'completion': completionScore.toInt(),
          'review': reviewScore.toInt(),
          'response': responseScore.toInt(),
          'dispute': disputeScore.toInt(),
        },
        'calculatedAt': DateTime.now(),
      };
    } catch (e) {
      print('计算信用评分失败: $e');
      return {
        'totalScore': 0,
        'creditLevel': 'poor',
        'creditLabel': '较差',
        'creditStars': 1,
        'breakdown': {
          'verification': 0,
          'completion': 0,
          'review': 0,
          'response': 0,
          'dispute': 0,
        },
        'calculatedAt': DateTime.now(),
      };
    }
  }

  /// 认证状态评分
  Future<double> _getVerificationScore(String userId) async {
    try {
      final doc = await _firestore.collection('verifications').doc(userId).get();

      if (!doc.exists) return 0;

      final data = doc.data()!;
      final status = data['status'];

      if (status == 'approved') {
        final type = data['type'];
        // 不同认证类型给不同分数
        switch (type) {
          case 'phone':
          case 'email':
            return 10; // 基础认证
          case 'business':
            return 15; // 企业认证
          case 'identity':
          case 'bank':
            return 20; // 高级认证
          default:
            return 5;
        }
      }

      return 0;
    } catch (e) {
      return 0;
    }
  }

  /// 交易完成率评分
  Future<double> _getCompletionScore(String userId) async {
    try {
      // 获取所有销售交易
      final salesQuery = await _firestore
          .collection('transactions')
          .where('sellerId', isEqualTo: userId)
          .get();

      if (salesQuery.docs.isEmpty) return 15; // 新用户给予基础分

      int totalTransactions = salesQuery.docs.length;
      int completedTransactions = 0;

      for (var doc in salesQuery.docs) {
        final data = doc.data();
        if (data['status'] == 'completed') {
          completedTransactions++;
        }
      }

      final completionRate = completedTransactions / totalTransactions;
      return completionRate * 30; // 最高30分
    } catch (e) {
      return 0;
    }
  }

  /// 平均评分
  Future<double> _getReviewScore(String userId) async {
    try {
      final reviewsQuery = await _firestore
          .collection('reviews')
          .where('revieweeId', isEqualTo: userId)
          .get();

      if (reviewsQuery.docs.isEmpty) return 12.5; // 新用户给予中等分

      double totalRating = 0;
      for (var doc in reviewsQuery.docs) {
        final data = doc.data();
        totalRating += (data['overallRating'] ?? 0.0).toDouble();
      }

      final averageRating = totalRating / reviewsQuery.docs.length;
      return (averageRating / 5) * 25; // 最高25分
    } catch (e) {
      return 0;
    }
  }

  /// 响应速度评分
  Future<double> _getResponseScore(String userId) async {
    try {
      // 获取用户的消息响应数据
      final messagesQuery = await _firestore
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('read', isEqualTo: true)
          .limit(50)
          .get();

      if (messagesQuery.docs.isEmpty) return 7.5; // 新用户给予中等分

      int totalResponseTime = 0;
      int count = 0;

      for (var doc in messagesQuery.docs) {
        final data = doc.data();
        final sentAt = (data['sentAt'] as Timestamp?)?.toDate();
        final readAt = (data['readAt'] as Timestamp?)?.toDate();

        if (sentAt != null && readAt != null) {
          final responseTime = readAt.difference(sentAt).inMinutes;
          totalResponseTime += responseTime;
          count++;
        }
      }

      if (count == 0) return 7.5;

      final avgResponseTime = totalResponseTime / count;

      // 响应时间越短，分数越高
      if (avgResponseTime < 30) return 15; // 30分钟内
      if (avgResponseTime < 60) return 12; // 1小时内
      if (avgResponseTime < 180) return 9; // 3小时内
      if (avgResponseTime < 360) return 6; // 6小时内
      return 3; // 6小时以上
    } catch (e) {
      return 7.5;
    }
  }

  /// 争议率评分
  Future<double> _getDisputeScore(String userId) async {
    try {
      // 获取相关交易数
      final transactionsQuery = await _firestore
          .collection('transactions')
          .where('sellerId', isEqualTo: userId)
          .get();

      if (transactionsQuery.docs.isEmpty) return 5; // 新用户给予中等分

      // 获取争议数
      final disputesQuery = await _firestore
          .collection('disputes')
          .where('transactionId',
              whereIn: transactionsQuery.docs.map((d) => d.id).toList())
          .get();

      final disputeRate =
          disputesQuery.docs.length / transactionsQuery.docs.length;

      // 争议率越低，分数越高
      if (disputeRate == 0) return 10; // 无争议
      if (disputeRate < 0.05) return 8; // 争议率 < 5%
      if (disputeRate < 0.10) return 6; // 争议率 < 10%
      if (disputeRate < 0.15) return 4; // 争议率 < 15%
      return 2; // 争议率 >= 15%
    } catch (e) {
      return 5;
    }
  }

  /// 获取信用等级
  Map<String, dynamic> _getCreditLevel(double score) {
    if (score >= 90) {
      return {
        'level': 'excellent',
        'label': '卓越',
        'stars': 5,
        'color': 'purple',
      };
    } else if (score >= 80) {
      return {
        'level': 'good',
        'label': '优秀',
        'stars': 4,
        'color': 'blue',
      };
    } else if (score >= 70) {
      return {
        'level': 'fair',
        'label': '良好',
        'stars': 3,
        'color': 'green',
      };
    } else if (score >= 60) {
      return {
        'level': 'average',
        'label': '一般',
        'stars': 2,
        'color': 'orange',
      };
    } else {
      return {
        'level': 'poor',
        'label': '较差',
        'stars': 1,
        'color': 'red',
      };
    }
  }

  /// 保存信用评分到用户文档
  Future<void> saveCreditScore(String userId) async {
    final scoreData = await calculateCreditScore(userId);

    await _firestore.collection('users').doc(userId).update({
      'creditScore': scoreData,
      'creditScoreUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// 获取用户信用评分
  Future<Map<String, dynamic>?> getCreditScore(String userId) async {
    try {
      final doc = await _firestore.collection('users').doc(userId).get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      return data['creditScore'] as Map<String, dynamic>?;
    } catch (e) {
      return null;
    }
  }

  /// 批量更新信用评分（管理员功能）
  Future<void> batchUpdateCreditScores() async {
    try {
      final usersQuery = await _firestore.collection('users').get();

      for (var doc in usersQuery.docs) {
        await saveCreditScore(doc.id);
      }
    } catch (e) {
      print('批量更新信用评分失败: $e');
    }
  }
}

/// 信用评分组件 - 可在其他页面使用
class CreditScoreBadge extends StatelessWidget {
  final String userId;
  final bool showDetails;

  const CreditScoreBadge({
    super.key,
    required this.userId,
    this.showDetails = false,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(userId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const SizedBox();
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final creditScore = data['creditScore'] as Map<String, dynamic>?;

        if (creditScore == null) {
          return const SizedBox();
        }

        final stars = creditScore['creditStars'] ?? 0;
        final label = creditScore['creditLabel'] ?? '';
        final score = creditScore['totalScore'] ?? 0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getColor(stars).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _getColor(stars)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...List.generate(
                stars,
                (index) => Icon(
                  Icons.star,
                  size: 12,
                  color: _getColor(stars),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                showDetails ? '$label ($score分)' : label,
                style: TextStyle(
                  fontSize: 12,
                  color: _getColor(stars),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getColor(int stars) {
    switch (stars) {
      case 5:
        return Colors.purple;
      case 4:
        return Colors.blue;
      case 3:
        return Colors.green;
      case 2:
        return Colors.orange;
      default:
        return Colors.red;
    }
  }
}

// 需要导入 Flutter 包来使用 StatelessWidget
import 'package:flutter/material.dart';
