import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BBXInitDataScreen extends StatefulWidget {
  const BBXInitDataScreen({super.key});

  @override
  State<BBXInitDataScreen> createState() => _BBXInitDataScreenState();
}

class _BBXInitDataScreenState extends State<BBXInitDataScreen> {
  bool _isLoading = false;
  String _statusMessage = '准备初始化测试数�?..';
  int _progress = 0;

  Future<void> _initAllData() async {
    setState(() {
      _isLoading = true;
      _progress = 0;
      _statusMessage = '开始初始化所有测试数�?..';
    });

    try {
      await _initUsers();
      setState(() => _progress = 25);

      await _initRecyclers();
      setState(() => _progress = 50);

      await _initWasteListings();
      setState(() => _progress = 75);

      await _initOffers();
      setState(() => _progress = 100);

      setState(() {
        _statusMessage = '�?所有测试数据初始化成功�?;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('测试数据初始化成功！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = '�?初始化失�? $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('初始化失�? $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initUsers() async {
    setState(() => _statusMessage = '正在创建测试用户...');

    final currentUser = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

    // 确保当前用户是管理员
    if (currentUser != null) {
      await firestore.collection('users').doc(currentUser.uid).set({
        'isAdmin': true,
        'userType': 'admin',
        'displayName': currentUser.displayName ?? currentUser.email ?? 'Admin User',
        'email': currentUser.email,
        'verified': true,
        'rating': 5.0,
        'subscriptionPlan': 'enterprise',
        'companyName': 'BBX Platform',
        'city': 'Kuala Lumpur',
        'contact': '+60123456789',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    // 创建测试用户
    final testUsers = [
      {
        'displayName': '张三',
        'email': 'producer1@test.com',
        'userType': 'producer',
        'companyName': '棕榈油生产公司A',
        'city': 'Kuching',
        'contact': '+60181234567',
        'rating': 4.5,
        'verified': true,
      },
      {
        'displayName': '李四',
        'email': 'producer2@test.com',
        'userType': 'producer',
        'companyName': '棕榈油生产公司B',
        'city': 'Miri',
        'contact': '+60182345678',
        'rating': 4.2,
        'verified': true,
      },
      {
        'displayName': '王五',
        'email': 'processor1@test.com',
        'userType': 'processor',
        'companyName': '生物质处理公司A',
        'city': 'Sibu',
        'contact': '+60183456789',
        'rating': 4.8,
        'verified': true,
      },
      {
        'displayName': '赵六',
        'email': 'recycler1@test.com',
        'userType': 'recycler',
        'companyName': '环保回收公司A',
        'city': 'Bintulu',
        'contact': '+60184567890',
        'rating': 4.6,
        'verified': true,
      },
    ];

    for (final user in testUsers) {
      await firestore.collection('users').add({
        ...user,
        'isAdmin': false,
        'subscriptionPlan': 'free',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _initRecyclers() async {
    setState(() => _statusMessage = '正在创建测试回收�?..');

    final firestore = FirebaseFirestore.instance;
    final recyclers = [
      {
        'name': '绿色环保回收公司',
        'city': 'Kuching',
        'capacity': 5000,
        'accepts': ['EFB', 'POME', 'Palm Shell'],
        'rating': 4.8,
        'verified': true,
        'contact': '+60181111111',
        'priceRange': 'RM 50-100/ton',
      },
      {
        'name': '生物质能源处理中�?,
        'city': 'Miri',
        'capacity': 8000,
        'accepts': ['EFB', 'Palm Fiber', 'Other Biomass'],
        'rating': 4.6,
        'verified': true,
        'contact': '+60182222222',
        'priceRange': 'RM 60-120/ton',
      },
      {
        'name': '循环经济废料处理�?,
        'city': 'Sibu',
        'capacity': 6000,
        'accepts': ['POME', 'Palm Shell', 'Palm Fiber'],
        'rating': 4.5,
        'verified': true,
        'contact': '+60183333333',
        'priceRange': 'RM 55-110/ton',
      },
      {
        'name': '可持续生物质回收�?,
        'city': 'Bintulu',
        'capacity': 7000,
        'accepts': ['EFB', 'POME', 'Other Biomass'],
        'rating': 4.7,
        'verified': true,
        'contact': '+60184444444',
        'priceRange': 'RM 65-115/ton',
      },
    ];

    for (final recycler in recyclers) {
      await firestore.collection('recyclers').add({
        ...recycler,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _initWasteListings() async {
    setState(() => _statusMessage = '正在创建测试废料列表...');

    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;

    final listings = [
      {
        'title': 'EFB 空果串大量出�?,
        'description': '新鲜的棕榈空果串，适合用于堆肥或生物质能源生产',
        'wasteType': 'EFB (Empty Fruit Bunches)',
        'quantity': 100,
        'unit': 'tons',
        'pricePerUnit': 80,
        'status': 'available',
        'contactInfo': '+60181234567',
        'userEmail': 'producer1@test.com',
        'location': {
          'latitude': 1.5533,
          'longitude': 110.3593,
        },
      },
      {
        'title': 'POME 棕榈油厂污水处理',
        'description': '棕榈油厂的废水处理服务，可用于沼气生�?,
        'wasteType': 'POME (Palm Oil Mill Effluent)',
        'quantity': 50,
        'unit': 'tons',
        'pricePerUnit': 60,
        'status': 'available',
        'contactInfo': '+60182345678',
        'userEmail': 'producer2@test.com',
        'location': {
          'latitude': 4.3956,
          'longitude': 113.9777,
        },
      },
      {
        'title': '棕榈壳回�?,
        'description': '高质量的棕榈壳，可用于生物质能源或活性炭生产',
        'wasteType': 'Palm Shell',
        'quantity': 75,
        'unit': 'tons',
        'pricePerUnit': 90,
        'status': 'available',
        'contactInfo': '+60183456789',
        'userEmail': 'producer1@test.com',
        'location': {
          'latitude': 2.3042,
          'longitude': 111.8445,
        },
      },
      {
        'title': '棕榈纤维出售',
        'description': '适合制造生物燃料的棕榈纤维',
        'wasteType': 'Palm Fiber',
        'quantity': 60,
        'unit': 'tons',
        'pricePerUnit': 70,
        'status': 'available',
        'contactInfo': '+60184567890',
        'userEmail': 'producer2@test.com',
        'location': {
          'latitude': 3.1667,
          'longitude': 113.0333,
        },
      },
      {
        'title': '混合生物质废�?,
        'description': '各种生物质废料混合物，适合能源生产',
        'wasteType': 'Other Biomass',
        'quantity': 120,
        'unit': 'tons',
        'pricePerUnit': 85,
        'status': 'available',
        'contactInfo': '+60181234567',
        'userEmail': 'processor1@test.com',
        'location': {
          'latitude': 1.6,
          'longitude': 110.4,
        },
      },
    ];

    for (final listing in listings) {
      await firestore.collection('listings').add({
        ...listing,
        'userId': currentUser?.uid ?? 'test-user',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _initOffers() async {
    setState(() => _statusMessage = '正在创建测试报价...');

    final firestore = FirebaseFirestore.instance;

    // 获取一些测试列�?ID
    final listingsSnapshot = await firestore
        .collection('listings')
        .limit(3)
        .get();

    if (listingsSnapshot.docs.isEmpty) {
      return;
    }

    final offers = [
      {
        'listingId': listingsSnapshot.docs[0].id,
        'recyclerId': 'recycler-001',
        'offerPrice': 75,
        'message': '我们对您�?EFB 很感兴趣，可以提供长期合�?,
        'status': 'pending',
      },
      {
        'listingId': listingsSnapshot.docs[0].id,
        'recyclerId': 'recycler-002',
        'offerPrice': 82,
        'message': '价格优惠，量大从�?,
        'status': 'pending',
      },
      {
        'listingId': listingsSnapshot.docs[1].id,
        'recyclerId': 'recycler-003',
        'offerPrice': 58,
        'message': '我们有专业的 POME 处理设备',
        'status': 'accepted',
      },
      {
        'listingId': listingsSnapshot.docs[2].id,
        'recyclerId': 'recycler-001',
        'offerPrice': 88,
        'message': '棕榈壳质量优良，我们愿意出好价格',
        'status': 'pending',
      },
    ];

    for (final offer in offers) {
      await firestore.collection('offers').add({
        ...offer,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<void> _clearAllData() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认清除'),
        content: const Text(
          '确定要清除所有测试数据吗？\n\n此操作不可撤销！\n\n注意：您的账户信息不会被删除�?,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('确认清除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = '正在清除测试数据...';
      _progress = 0;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

      // 清除 listings
      setState(() => _statusMessage = '清除废料列表...');
      final listings = await firestore.collection('listings').get();
      for (final doc in listings.docs) {
        await doc.reference.delete();
      }
      setState(() => _progress = 25);

      // 清除 offers
      setState(() => _statusMessage = '清除报价...');
      final offers = await firestore.collection('offers').get();
      for (final doc in offers.docs) {
        await doc.reference.delete();
      }
      setState(() => _progress = 50);

      // 清除 recyclers
      setState(() => _statusMessage = '清除回收�?..');
      final recyclers = await firestore.collection('recyclers').get();
      for (final doc in recyclers.docs) {
        await doc.reference.delete();
      }
      setState(() => _progress = 75);

      // 清除测试用户（除了当前用户）
      setState(() => _statusMessage = '清除测试用户...');
      final users = await firestore.collection('users').get();
      for (final doc in users.docs) {
        if (doc.id != currentUserId) {
          await doc.reference.delete();
        }
      }
      setState(() => _progress = 100);

      setState(() => _statusMessage = '�?所有测试数据已清除�?);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('测试数据清除成功�?),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _statusMessage = '�?清除失败: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('清除失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('测试数据初始�?),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 说明卡片
            Card(
              color: const Color(0xFFFFF9C4),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.orange[800],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '测试数据初始化工�?,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[800],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '此工具将创建以下测试数据：\n'
                      '�?4个测试用户（生产者、处理者、回收商）\n'
                      '�?4个测试回收商资料\n'
                      '�?5个测试废料列表\n'
                      '�?4个测试报价\n\n'
                      '注意：您的账户将自动设置为管理员',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.orange[900],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // 状态显�?
            if (_isLoading)
              Column(
                children: [
                  LinearProgressIndicator(
                    value: _progress / 100,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF4CAF50),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _statusMessage,
                    style: const TextStyle(fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${_progress}%',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Text(
                  _statusMessage,
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),

            const SizedBox(height: 32),

            // 初始化按�?
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _initAllData,
              icon: const Icon(Icons.play_arrow),
              label: const Text(
                '初始化所有测试数�?,
                style: TextStyle(fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 清除按钮
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _clearAllData,
              icon: const Icon(Icons.delete_sweep),
              label: const Text(
                '清除所有测试数�?,
                style: TextStyle(fontSize: 16),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
