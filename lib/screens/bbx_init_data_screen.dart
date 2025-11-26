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
  String _statusMessage = 'Preparing InitializationTestNumber?..';
  int _progress = 0;

  Future<void> _initAllData() async {
    setState(() {
      _isLoading = true;
      _progress = 0;
      _statusMessage = 'StartInitizeAllTestNumber?..';
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
        _statusMessage = '?AllTestDataInitizeSuccess?;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('TestDataInitizeSuccess！'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _statusMessage = '?Init Failed? $e';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Init Failed? $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _initUsers() async {
    setState(() => _statusMessage = 'IsCreateTestUser...');

    final currentUser = FirebaseAuth.instance.currentUser;
    final firestore = FirebaseFirestore.instance;

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

        final testUsers = [
      {
        'displayName': 'User A',
        'email': 'producer1@test.com',
        'userType': 'producer',
        'companyName': 'Palm OilBirthProduceCompanyA',
        'city': 'Kuching',
        'contact': '+60181234567',
        'rating': 4.5,
        'verified': true,
      },
      {
        'displayName': 'User B',
        'email': 'producer2@test.com',
        'userType': 'producer',
        'companyName': 'Palm OilBirthProduceCompanyB',
        'city': 'Miri',
        'contact': '+60182345678',
        'rating': 4.2,
        'verified': true,
      },
      {
        'displayName': 'User C',
        'email': 'processor1@test.com',
        'userType': 'processor',
        'companyName': 'Biomass ProcessingCompanyA',
        'city': 'Sibu',
        'contact': '+60183456789',
        'rating': 4.8,
        'verified': true,
      },
      {
        'displayName': 'User D',
        'email': 'recycler1@test.com',
        'userType': 'recycler',
        'companyName': 'Eco RecyclingCompanyA',
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
    setState(() => _statusMessage = 'IsCreateTestReturnCollect?..');

    final firestore = FirebaseFirestore.instance;
    final recyclers = [
      {
        'name': 'Green RecyclingCompany',
        'city': 'Kuching',
        'capacity': 5000,
        'accepts': ['EFB', 'POME', 'Palm Shell'],
        'rating': 4.8,
        'verified': true,
        'contact': '+60181111111',
        'priceRange': 'RM 50-100/ton',
      },
      {
        'name': 'Biomass EnergyProcessing?,
        'city': 'Miri',
        'capacity': 8000,
        'accepts': ['EFB', 'Palm Fiber', 'Other Biomass'],
        'rating': 4.6,
        'verified': true,
        'contact': '+60182222222',
        'priceRange': 'RM 60-120/ton',
      },
      {
        'name': 'CycleRingSutraEconomyWasteProcess?,
        'city': 'Sibu',
        'capacity': 6000,
        'accepts': ['POME', 'Palm Shell', 'Palm Fiber'],
        'rating': 4.5,
        'verified': true,
        'contact': '+60183333333',
        'priceRange': 'RM 55-110/ton',
      },
      {
        'name': 'Sustainable Biomass Recycling?,
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
    setState(() => _statusMessage = 'IsCreateTestWasteColTable...');

    final firestore = FirebaseFirestore.instance;
    final currentUser = FirebaseAuth.instance.currentUser;

    final listings = [
      {
        'title': 'EFB EmptyFruitStringBigAmountOut?,
        'description': 'NewFresh of EFB (Empty Fruit Bunches)，Suitable for composting or biomass energy production',
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
        'title': 'POME POME Treatment',
        'description': 'Palm Oil Mill of WasteWaterProcessService，For Biogas Production?,
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
        'title': 'Palm ShellReturn?,
        'description': 'HighQuality of Palm Shell，Can be used for biomass energy or activated carbon',
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
        'title': 'Palm FiberSell',
        'description': 'For Biofuel of Palm Fiber',
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
        'title': 'MixCombineBirthThingQualityWaste?,
        'description': 'EachSeedBirthThingQualityWasteMixCombineThing，For Energy Production',
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
    setState(() => _statusMessage = 'IsCreateTestQuote...');

    final firestore = FirebaseFirestore.instance;

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
        'message': 'We to you?EFB VeryFeelInterest，Can provide long-term cooperation?,
        'status': 'pending',
      },
      {
        'listingId': listingsSnapshot.docs[0].id,
        'recyclerId': 'recycler-002',
        'offerPrice': 82,
        'message': 'PriceDiscount，Volume Discount?,
        'status': 'pending',
      },
      {
        'listingId': listingsSnapshot.docs[1].id,
        'recyclerId': 'recycler-003',
        'offerPrice': 58,
        'message': 'We have professional of  POME Processing Equipment',
        'status': 'accepted',
      },
      {
        'listingId': listingsSnapshot.docs[2].id,
        'recyclerId': 'recycler-001',
        'offerPrice': 88,
        'message': 'Palm ShellGood Quality，We offer good pricePrice',
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
        title: const Text('ConfirmClear'),
        content: const Text(
          'OKWantClearAllTestData?？\n\nAction cannot be undone！\n\nNote：Your Account InfoNoWillByDelete?,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('ConfirmClear'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _isLoading = true;
      _statusMessage = 'Clearing test data...';
      _progress = 0;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;

            setState(() => _statusMessage = 'ClearWasteColTable...');
      final listings = await firestore.collection('listings').get();
      for (final doc in listings.docs) {
        await doc.reference.delete();
      }
      setState(() => _progress = 25);

            setState(() => _statusMessage = 'ClearQuote...');
      final offers = await firestore.collection('offers').get();
      for (final doc in offers.docs) {
        await doc.reference.delete();
      }
      setState(() => _progress = 50);

            setState(() => _statusMessage = 'ClearReturnCollect?..');
      final recyclers = await firestore.collection('recyclers').get();
      for (final doc in recyclers.docs) {
        await doc.reference.delete();
      }
      setState(() => _progress = 75);

            setState(() => _statusMessage = 'ClearTestUser...');
      final users = await firestore.collection('users').get();
      for (final doc in users.docs) {
        if (doc.id != currentUserId) {
          await doc.reference.delete();
        }
      }
      setState(() => _progress = 100);

      setState(() => _statusMessage = '?AllTestDataAlreadyClear?);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('TestDataClearSuccess?),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _statusMessage = '?ClearFailure: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ClearFailure: $e'),
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
        title: const Text('TestDataInit?),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                          'TestDataInit Tool?,
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
                      'ThisToolsWillCreateByDownTestData：\n'
                      '?4TestUser（Producer、ProcessPerson、Recycler）\n'
                      '?4TestRecyclerProfile\n'
                      '?5TestWasteColTable\n'
                      '?4TestQuote\n\n'
                      'Note：Your account will be automatically set as admin',
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

                        ElevatedButton.icon(
              onPressed: _isLoading ? null : _initAllData,
              icon: const Icon(Icons.play_arrow),
              label: const Text(
                'InitizeAllTestNumber?,
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

                        OutlinedButton.icon(
              onPressed: _isLoading ? null : _clearAllData,
              icon: const Icon(Icons.delete_sweep),
              label: const Text(
                'ClearAllTestNumber?,
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
