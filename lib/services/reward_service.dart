import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/reward_model.dart';

/// 奖励服务
class RewardService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 获取当前用户的奖励信息
  Future<RewardModel?> getRewards() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore.collection('rewards').doc(userId).get();

      if (!doc.exists) {
        // 创建新的奖励记录
        return await _initializeRewards(userId);
      }

      return RewardModel.fromFirestore(doc);
    } catch (e) {
      print('获取奖励信息失败: $e');
      return null;
    }
  }

  /// 初始化奖励记录
  Future<RewardModel> _initializeRewards(String userId) async {
    final now = DateTime.now();
    final reward = RewardModel(
      id: userId,
      userId: userId,
      points: 50, // 注册奖励
      tier: MemberTier.bronze,
      transactions: [
        RewardTransaction(
          id: now.millisecondsSinceEpoch.toString(),
          type: RewardTransactionType.earn,
          points: 50,
          reason: '注册奖励',
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

  /// 获取积分
  Future<int> getPoints() async {
    final rewards = await getRewards();
    return rewards?.points ?? 0;
  }

  /// 完成任务
  Future<bool> completeTask(String taskId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('用户未登录');

      final doc = await _firestore.collection('rewards').doc(userId).get();
      if (!doc.exists) {
        await _initializeRewards(userId);
        return await completeTask(taskId);
      }

      final reward = RewardModel.fromFirestore(doc);

      // 查找任务
      final taskIndex =
          reward.dailyTasks.indexWhere((task) => task.id == taskId);
      if (taskIndex == -1) throw Exception('任务不存在');

      final task = reward.dailyTasks[taskIndex];
      if (task.isCompleted) throw Exception('任务已完成');

      // 更新任务状态
      final updatedTasks = List<DailyTask>.from(reward.dailyTasks);
      updatedTasks[taskIndex] = task.copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );

      // 添加积分
      final updatedReward = reward.addPoints(task.points, task.title);

      // 更新数据库
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
      print('完成任务失败: $e');
      return false;
    }
  }

  /// 兑换奖励
  Future<bool> redeemReward(String rewardId, int pointsCost) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('用户未登录');

      final doc = await _firestore.collection('rewards').doc(userId).get();
      if (!doc.exists) throw Exception('奖励记录不存在');

      final reward = RewardModel.fromFirestore(doc);

      // 检查积分是否足够
      if (reward.points < pointsCost) {
        throw Exception('积分不足');
      }

      // 扣除积分
      final updatedReward = reward.redeemPoints(pointsCost, rewardId);

      // 更新数据库
      await _firestore.collection('rewards').doc(userId).update({
        'points': updatedReward.points,
        'transactions':
            updatedReward.transactions.map((t) => t.toMap()).toList(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('兑换奖励失败: $e');
      return false;
    }
  }

  /// 添加积分（通用方法）
  Future<bool> addPoints(int points, String reason) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) throw Exception('用户未登录');

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
      print('添加积分失败: $e');
      return false;
    }
  }

  /// 获取每日任务列表
  List<DailyTask> _generateDailyTasks() {
    return [
      DailyTask(
        id: 'daily_signin',
        title: '每日签到',
        description: '每天签到获取积分',
        points: 10,
        icon: 'calendar',
      ),
      DailyTask(
        id: 'share_listing',
        title: '分享商品',
        description: '分享一个商品到社交媒体',
        points: 5,
        icon: 'share',
      ),
      DailyTask(
        id: 'send_message',
        title: '发送消息',
        description: '与其他用户交流',
        points: 3,
        icon: 'message',
      ),
      DailyTask(
        id: 'rate_transaction',
        title: '评价交易',
        description: '对已完成的交易进行评价',
        points: 15,
        icon: 'star',
      ),
      DailyTask(
        id: 'publish_listing',
        title: '发布商品',
        description: '发布一个新的商品',
        points: 20,
        icon: 'add',
      ),
    ];
  }

  /// 获取任务列表
  Future<List<DailyTask>> getTaskList() async {
    final rewards = await getRewards();
    return rewards?.dailyTasks ?? _generateDailyTasks();
  }

  /// 获取奖励历史记录
  Future<List<RewardTransaction>> getRewardHistory() async {
    final rewards = await getRewards();
    return rewards?.transactions ?? [];
  }

  /// 重置每日任务（每天调用一次）
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
      print('重置每日任务失败: $e');
    }
  }
}
