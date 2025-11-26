import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reward_model.dart';

class RewardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

    Future<RewardModel?> getRewards() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore.collection('rewards').doc(userId).get();

      if (!doc.exists) {
                return await _initializeRewards(userId);
      }

      return RewardModel.fromFirestore(doc);
    } catch (e) {
      print('GetRewardInfoFailure: $e');
      return null;
    }
  }

    Future<RewardModel> _initializeRewards(String userId) async {
    final now = DateTime.now();
    final reward = RewardModel(
      id: userId,
      userId: userId,
      points: 50,       tier: MemberTier.bronze,
      transactions: [
        RewardTransaction(
          id: now.millisecondsSinceEpoch.toString(),
          type: RewardTransactionType.earn,
          points: 50,
          reason: 'Registration Reward',
          timestamp: now,
        ),
      ],
      dailyTasks: _generateDailyTasks(),
      createdAt: now,
      updatedAt: now,
    );

    await _firestore.collection('rewards').doc(userId).set(reward.toMap());

    return reward;
  }

    Future<int> getPoints() async {
    final rewards = await getRewards();
    return rewards?.points ?? 0;
  }

    Future<bool> completeTask(String taskId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final doc = await _firestore.collection('rewards').doc(userId).get();
      if (!doc.exists) {
        await _initializeRewards(userId);
        return await completeTask(taskId);
      }

      final reward = RewardModel.fromFirestore(doc);

            final taskIndex =
          reward.dailyTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex == -1) throw Exception('Task not found');

      final task = reward.dailyTasks[taskIndex];
      if (task.isCompleted) throw Exception('Task already completed');

            final updatedTasks = List<DailyTask>.from(reward.dailyTasks);
      updatedTasks[taskIndex] = task.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );

            final updatedReward = reward.addPoints(task.points, task.title);

            await _firestore.collection('rewards').doc(userId).update({
        'points': updatedReward.points,
        'tier': updatedReward.tier.toString().split('.').last,
        'transactions':
            updatedReward.transactions.map((t) => t.toMap()).toList(),
        'dailyTasks': updatedTasks.map((t) => t.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Task completion failed: $e');
      return false;
    }
  }

    Future<bool> redeemReward(String rewardId, int pointsCost) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final doc = await _firestore.collection('rewards').doc(userId).get();
      if (!doc.exists) throw Exception('Reward record not found');

      final reward = RewardModel.fromFirestore(doc);

            if (reward.points < pointsCost) {
        throw Exception('Insufficient points');
      }

            final updatedReward = reward.redeemPoints(pointsCost, rewardId);

            await _firestore.collection('rewards').doc(userId).update({
        'points': updatedReward.points,
        'transactions':
            updatedReward.transactions.map((t) => t.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Redemption failed: $e');
      return false;
    }
  }

    Future<bool> addPoints(int points, String reason) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('User not logged in');

      final doc = await _firestore.collection('rewards').doc(userId).get();
      if (!doc.exists) {
        await _initializeRewards(userId);
        return await addPoints(points, reason);
      }

      final reward = RewardModel.fromFirestore(doc);
      final updatedReward = reward.addPoints(points, reason);

      await _firestore.collection('rewards').doc(userId).update({
        'points': updatedReward.points,
        'tier': updatedReward.tier.toString().split('.').last,
        'transactions':
            updatedReward.transactions.map((t) => t.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Failed to add points: $e');
      return false;
    }
  }

    List<DailyTask> _generateDailyTasks() {
    return [
      DailyTask(
        id: 'daily_signin',
        title: 'Daily Check-in',
        description: 'Check-in daily to earn points',
        points: 10,
        icon: 'calendar',
      ),
      DailyTask(
        id: 'share_listing',
        title: 'Share Item',
        description: 'Share an item to social media',
        points: 5,
        icon: 'share',
      ),
      DailyTask(
        id: 'send_message',
        title: 'Send Message',
        description: 'Chat with other users',
        points: 3,
        icon: 'message',
      ),
      DailyTask(
        id: 'rate_transaction',
        title: 'Rate Transaction',
        description: 'Rate completed transactions',
        points: 15,
        icon: 'star',
      ),
      DailyTask(
        id: 'publish_listing',
        title: 'Post Item',
        description: 'Post a new item',
        points: 20,
        icon: 'add',
      ),
    ];
  }

    Future<List<DailyTask>> getTaskList() async {
    final rewards = await getRewards();
    return rewards?.dailyTasks ?? _generateDailyTasks();
  }

    Future<List<RewardTransaction>> getRewardHistory() async {
    final rewards = await getRewards();
    return rewards?.transactions ?? [];
  }

    Future<void> resetDailyTasks() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final newTasks = _generateDailyTasks();

      await _firestore.collection('rewards').doc(userId).update({
        'dailyTasks': newTasks.map((t) => t.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Failed to reset daily tasks: $e');
    }
  }
}
