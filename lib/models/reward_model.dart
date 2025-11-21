import 'package:cloud_firestore/cloud_firestore.dart';

enum RewardTransactionType {
  earn,
  redeem,
}

enum MemberTier {
  bronze,
  silver,
  gold,
  platinum,
}

class RewardTransaction {
  final String id;
  final RewardTransactionType type;
  final int points;
  final String reason;
  final DateTime timestamp;

  RewardTransaction({
    required this.id,
    required this.type,
    required this.points,
    required this.reason,
    required this.timestamp,
  });

  factory RewardTransaction.fromMap(Map<String, dynamic> data) {
    return RewardTransaction(
      id: data['id'] ?? '',
      type: data['type'] == 'earn'
          ? RewardTransactionType.earn
          : RewardTransactionType.redeem,
      points: data['points'] ?? 0,
      reason: data['reason'] ?? '',
      timestamp: data['timestamp'] is Timestamp
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.parse(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type == RewardTransactionType.earn ? 'earn' : 'redeem',
      'points': points,
      'reason': reason,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

class DailyTask {
  final String id;
  final String title;
  final String description;
  final int points;
  final String icon;
  final bool isCompleted;
  final DateTime? completedAt;

  DailyTask({
    required this.id,
    required this.title,
    required this.description,
    required this.points,
    this.icon = 'task',
    this.isCompleted = false,
    this.completedAt,
  });

  factory DailyTask.fromMap(Map<String, dynamic> data) {
    return DailyTask(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      points: data['points'] ?? 0,
      icon: data['icon'] ?? 'task',
      isCompleted: data['isCompleted'] ?? false,
      completedAt: data['completedAt'] != null
          ? (data['completedAt'] is Timestamp
              ? (data['completedAt'] as Timestamp).toDate()
              : DateTime.parse(data['completedAt']))
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'points': points,
      'icon': icon,
      'isCompleted': isCompleted,
      'completedAt':
          completedAt != null ? completedAt!.toIso8601String() : null,
    };
  }

  DailyTask copyWith({
    String? id,
    String? title,
    String? description,
    int? points,
    String? icon,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return DailyTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      points: points ?? this.points,
      icon: icon ?? this.icon,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

class RewardModel {
  final String id;
  final String userId;
  final int points;
  final MemberTier tier;
  final List<RewardTransaction> transactions;
  final List<DailyTask> dailyTasks;
  final DateTime createdAt;
  final DateTime updatedAt;

  RewardModel({
    required this.id,
    required this.userId,
    required this.points,
    required this.tier,
    required this.transactions,
    required this.dailyTasks,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RewardModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return RewardModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      points: data['points'] ?? 0,
      tier: _parseTier(data['tier']),
      transactions: (data['transactions'] as List<dynamic>?)
              ?.map((t) => RewardTransaction.fromMap(t as Map<String, dynamic>))
              .toList() ??
          [],
      dailyTasks: (data['dailyTasks'] as List<dynamic>?)
              ?.map((t) => DailyTask.fromMap(t as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'points': points,
      'tier': tier.toString().split('.').last,
      'transactions': transactions.map((t) => t.toMap()).toList(),
      'dailyTasks': dailyTasks.map((t) => t.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

    String get tierDisplayName {
    switch (tier) {
      case MemberTier.bronze:
        return 'Bronze';
      case MemberTier.silver:
        return 'Silver';
      case MemberTier.gold:
        return 'Gold';
      case MemberTier.platinum:
        return 'Platinum';
    }
  }

    String get tierIcon {
    switch (tier) {
      case MemberTier.bronze:
        return '🥉';
      case MemberTier.silver:
        return '🥈';
      case MemberTier.gold:
        return '🥇';
      case MemberTier.platinum:
        return '💎';
    }
  }

    int get pointsToNextTier {
    switch (tier) {
      case MemberTier.bronze:
        return 500 - points;
      case MemberTier.silver:
        return 1500 - points;
      case MemberTier.gold:
        return 5000 - points;
      case MemberTier.platinum:
<<<<<<< Updated upstream
        return 0; // 已是最高等�?
    }
=======
        return 0;     }
>>>>>>> Stashed changes
  }

    String? get nextTierName {
    switch (tier) {
      case MemberTier.bronze:
        return 'Silver';
      case MemberTier.silver:
        return 'Gold';
      case MemberTier.gold:
        return 'Platinum';
      case MemberTier.platinum:
<<<<<<< Updated upstream
        return null; // 已是最高等�?
    }
=======
        return null;     }
>>>>>>> Stashed changes
  }

  static MemberTier _parseTier(String? value) {
    switch (value?.toLowerCase()) {
      case 'silver':
        return MemberTier.silver;
      case 'gold':
        return MemberTier.gold;
      case 'platinum':
        return MemberTier.platinum;
      default:
        return MemberTier.bronze;
    }
  }

    RewardModel addPoints(int pointsToAdd, String reason) {
    final newTransaction = RewardTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: RewardTransactionType.earn,
      points: pointsToAdd,
      reason: reason,
      timestamp: DateTime.now(),
    );

    final newTransactions = [newTransaction, ...transactions];
    final newPoints = points + pointsToAdd;

<<<<<<< Updated upstream
    // 计算新等�?
    MemberTier newTier = tier;
=======
        MemberTier newTier = tier;
>>>>>>> Stashed changes
    if (newPoints >= 5000) {
      newTier = MemberTier.platinum;
    } else if (newPoints >= 1500) {
      newTier = MemberTier.gold;
    } else if (newPoints >= 500) {
      newTier = MemberTier.silver;
    } else {
      newTier = MemberTier.bronze;
    }

    return copyWith(
      points: newPoints,
      tier: newTier,
      transactions: newTransactions,
      updatedAt: DateTime.now(),
    );
  }

    RewardModel redeemPoints(int pointsToRedeem, String reason) {
    if (pointsToRedeem > points) {
      throw Exception('Insufficient points');
    }

    final newTransaction = RewardTransaction(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: RewardTransactionType.redeem,
      points: -pointsToRedeem,
      reason: reason,
      timestamp: DateTime.now(),
    );

    final newTransactions = [newTransaction, ...transactions];
    final newPoints = points - pointsToRedeem;

    return copyWith(
      points: newPoints,
      transactions: newTransactions,
      updatedAt: DateTime.now(),
    );
  }

  RewardModel copyWith({
    String? id,
    String? userId,
    int? points,
    MemberTier? tier,
    List<RewardTransaction>? transactions,
    List<DailyTask>? dailyTasks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RewardModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      points: points ?? this.points,
      tier: tier ?? this.tier,
      transactions: transactions ?? this.transactions,
      dailyTasks: dailyTasks ?? this.dailyTasks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
