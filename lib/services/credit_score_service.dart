import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

///
///
class CreditScoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

    Future<Map<String, dynamic>> calculateCreditScore(String userId) async {
    try {
            final verificationScore = await _getVerificationScore(userId);

            final completionScore = await _getCompletionScore(userId);

            final reviewScore = await _getReviewScore(userId);

            final responseScore = await _getResponseScore(userId);

            final disputeScore = await _getDisputeScore(userId);

            final totalScore = verificationScore +
          completionScore +
          reviewScore +
          responseScore +
          disputeScore;

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
      print('Calc Credit ScoreFailure: $e');
      return {
        'totalScore': 0,
        'creditLevel': 'poor',
        'creditLabel': 'MoreBad',
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

    Future<double> _getVerificationScore(String userId) async {
    try {
      final doc = await _firestore.collection('verifications').doc(userId).get();

      if (!doc.exists) return 0;

      final data = doc.data()!;
      final status = data['status'];

      if (status == 'approved') {
        final type = data['type'];
                switch (type) {
          case 'phone':
          case 'email':
            return 10;           case 'business':
            return 15;           case 'identity':
          case 'bank':
            return 20;           default:
            return 5;
        }
      }

      return 0;
    } catch (e) {
      return 0;
    }
  }

    Future<double> _getCompletionScore(String userId) async {
    try {
            final salesQuery = await _firestore
          .collection('transactions')
          .where('sellerId', isEqualTo: userId)
          .get();

      if (salesQuery.docs.isEmpty) return 15; 
      int totalTransactions = salesQuery.docs.length;
      int completedTransactions = 0;

      for (var doc in salesQuery.docs) {
        final data = doc.data();
        if (data['status'] == 'completed') {
          completedTransactions++;
        }
      }

      final completionRate = completedTransactions / totalTransactions;
      return completionRate * 30;     } catch (e) {
      return 0;
    }
  }

    Future<double> _getReviewScore(String userId) async {
    try {
      final reviewsQuery = await _firestore
          .collection('reviews')
          .where('revieweeId', isEqualTo: userId)
          .get();

      if (reviewsQuery.docs.isEmpty) return 12.5; 
      double totalRating = 0;
      for (var doc in reviewsQuery.docs) {
        final data = doc.data();
        totalRating += (data['overallRating'] ?? 0.0).toDouble();
      }

      final averageRating = totalRating / reviewsQuery.docs.length;
      return (averageRating / 5) * 25;     } catch (e) {
      return 0;
    }
  }

    Future<double> _getResponseScore(String userId) async {
    try {
            final messagesQuery = await _firestore
          .collection('messages')
          .where('receiverId', isEqualTo: userId)
          .where('read', isEqualTo: true)
          .limit(50)
          .get();

      if (messagesQuery.docs.isEmpty) return 7.5; 
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

            if (avgResponseTime < 30) return 15;       if (avgResponseTime < 60) return 12;       if (avgResponseTime < 180) return 9;       if (avgResponseTime < 360) return 6;       return 3;     } catch (e) {
      return 7.5;
    }
  }

    Future<double> _getDisputeScore(String userId) async {
    try {
            final transactionsQuery = await _firestore
          .collection('transactions')
          .where('sellerId', isEqualTo: userId)
          .get();

      if (transactionsQuery.docs.isEmpty) return 5; 
            final disputesQuery = await _firestore
          .collection('disputes')
          .where('transactionId',
              whereIn: transactionsQuery.docs.map((d) => d.id).toList())
          .get();

      final disputeRate =
          disputesQuery.docs.length / transactionsQuery.docs.length;

            if (disputeRate == 0) return 10;       if (disputeRate < 0.05) return 8;       if (disputeRate < 0.10) return 6;       if (disputeRate < 0.15) return 4;       return 2;     } catch (e) {
      return 5;
    }
  }

    Map<String, dynamic> _getCreditLevel(double score) {
    if (score >= 90) {
      return {
        'level': 'excellent',
        'label': 'SuperCross',
        'stars': 5,
        'color': 'purple',
      };
    } else if (score >= 80) {
      return {
        'level': 'good',
        'label': 'Excellent',
        'stars': 4,
        'color': 'blue',
      };
    } else if (score >= 70) {
      return {
        'level': 'fair',
        'label': 'GoodGood',
        'stars': 3,
        'color': 'green',
      };
    } else if (score >= 60) {
      return {
        'level': 'average',
        'label': 'One?,
        'stars': 2,
        'color': 'orange',
      };
    } else {
      return {
        'level': 'poor',
        'label': 'MoreBad',
        'stars': 1,
        'color': 'red',
      };
    }
  }

    Future<void> saveCreditScore(String userId) async {
    final scoreData = await calculateCreditScore(userId);

    await _firestore.collection('users').doc(userId).update({
      'creditScore': scoreData,
      'creditScoreUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

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

    Future<void> batchUpdateCreditScores() async {
    try {
      final usersQuery = await _firestore.collection('users').get();

      for (var doc in usersQuery.docs) {
        await saveCreditScore(doc.id);
      }
    } catch (e) {
      print('BatchUpdateCredit ScoreFailure: $e');
    }
  }
}

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
                showDetails ? '$label ($score?' : label,
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
