import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../services/avatar_upload_service.dart';

class BBXOptimizedProfileScreen extends StatefulWidget {
  const BBXOptimizedProfileScreen({super.key});

  @override
  State<BBXOptimizedProfileScreen> createState() => _BBXOptimizedProfileScreenState();
}

class _BBXOptimizedProfileScreenState extends State<BBXOptimizedProfileScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isLoading = true;
  bool isUploadingAvatar = false;

  // User data
  String displayName = '';
  String email = '';
  String? avatarUrl;
  String companyName = '';
  String city = '';
  String contact = '';

  // Stats
  int transactionCount = 0;
  int offerCount = 0;
  int favoriteCount = 0;
  double walletBalance = 0.0;
  String membershipTier = 'Free';
  int rewardPoints = 0;
  int availableCoupons = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      // Load user profile data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          displayName = data['displayName'] ?? user?.displayName ?? 'User';
          email = data['email'] ?? user?.email ?? '';
          avatarUrl = data['photoURL'];
          companyName = data['companyName'] ?? '';
          city = data['city'] ?? '';
          contact = data['contact'] ?? '';
          // 也从用户文档读取这些数据（如果存在）
          walletBalance = (data['walletBalance'] ?? 0).toDouble();
          rewardPoints = data['rewardPoints'] ?? 0;
          membershipTier = data['membershipTier'] ?? 'Free';
        });
      } else {
        setState(() {
          displayName = user?.displayName ?? user?.email?.split('@')[0] ?? 'User';
          email = user?.email ?? '';
          avatarUrl = user?.photoURL;
        });
      }

      // Load statistics in parallel with error handling
      await Future.wait([
        _loadTransactionCount(),
        _loadOfferCount(),
        _loadFavoriteCount(),
        _loadWalletBalance(),
        _loadRewardPoints(),
        _loadCouponsCount(),
      ]);
    } catch (e) {
      debugPrint('[Profile] Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _loadTransactionCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('buyerId', isEqualTo: user!.uid)
          .count()
          .get();
      final buyerCount = snapshot.count ?? 0;

      final sellerSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('sellerId', isEqualTo: user!.uid)
          .count()
          .get();
      final sellerCount = sellerSnapshot.count ?? 0;

      if (mounted) {
        setState(() => transactionCount = buyerCount + sellerCount);
      }
    } catch (e) {
      debugPrint('[Profile] Error loading transaction count: $e');
    }
  }

  Future<void> _loadOfferCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('offers')
          .where('recyclerId', isEqualTo: user!.uid)
          .count()
          .get();
      if (mounted) {
        setState(() => offerCount = snapshot.count ?? 0);
      }
    } catch (e) {
      debugPrint('[Profile] Error loading offer count: $e');
    }
  }

  Future<void> _loadFavoriteCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('favorites')
          .where('userId', isEqualTo: user!.uid)
          .count()
          .get();
      if (mounted) {
        setState(() => favoriteCount = snapshot.count ?? 0);
      }
    } catch (e) {
      debugPrint('[Profile] Error loading favorite count: $e');
    }
  }

  // ✅ 修复：添加错误处理，避免权限问题导致崩溃
  Future<void> _loadWalletBalance() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('wallets')
          .doc(user!.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() => walletBalance = (doc.data()?['balance'] ?? 0).toDouble());
      }
    } catch (e) {
      // 如果权限被拒绝，尝试从用户文档读取
      debugPrint('[Profile] Wallet access denied, using default: $e');
    }
  }

  // ✅ 修复：添加错误处理
  Future<void> _loadRewardPoints() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('rewards')
          .doc(user!.uid)
          .get();
      if (doc.exists && mounted) {
        setState(() => rewardPoints = doc.data()?['points'] ?? 0);
      }
    } catch (e) {
      debugPrint('[Profile] Rewards access denied, using default: $e');
    }
  }

  Future<void> _loadCouponsCount() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('coupons')
          .where('userId', isEqualTo: user!.uid)
          .where('isUsed', isEqualTo: false)
          .count()
          .get();
      if (mounted) {
        setState(() => availableCoupons = snapshot.count ?? 0);
      }
    } catch (e) {
      debugPrint('[Profile] Error loading coupons count: $e');
    }
  }

  Future<void> _uploadAvatar() async {
    if (user == null || isUploadingAvatar) return;

    setState(() => isUploadingAvatar = true);

    try {
      final String? downloadUrl = await AvatarUploadService.pickAndUploadAvatar(
        context: context,
        userId: user!.uid,
        onProgress: (progress) {
          debugPrint('Upload Progress: ${(progress * 100).toStringAsFixed(1)}%');
        },
      );

      if (downloadUrl != null && mounted) {
        setState(() => avatarUrl = downloadUrl);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar updated successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('[Profile] Error uploading avatar: $e');
    } finally {
      if (mounted) {
        setState(() => isUploadingAvatar = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F5F5),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF2E7D32))),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        color: const Color(0xFF2E7D32),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeaderWithStats(),
              _buildAccountCards(),
              _buildMembershipSection(),
              _buildMyServicesSection(),
              _buildSettingsSection(),
              _buildLogoutButton(),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderWithStats() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Green gradient header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(bottom: 50),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                children: [
                  // Avatar with upload button
                  GestureDetector(
                    onTap: () => _showAvatarOptions(),
                    child: Stack(
                      children: [
                        Container(
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: isUploadingAvatar
                                ? Container(
                                    color: Colors.white,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: Color(0xFF2E7D32),
                                        strokeWidth: 3,
                                      ),
                                    ),
                                  )
                                : avatarUrl != null && avatarUrl!.isNotEmpty
                                    ? CachedNetworkImage(
                                        imageUrl: avatarUrl!,
                                        fit: BoxFit.cover,
                                        placeholder: (context, url) => Container(
                                          color: Colors.white,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Color(0xFF2E7D32),
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        ),
                                        errorWidget: (context, url, error) => _buildDefaultAvatar(),
                                      )
                                    : _buildDefaultAvatar(),
                          ),
                        ),
                        // Camera icon overlay
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Color(0xFF2E7D32),
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  if (companyName.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      companyName,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Stats Card
        Positioned(
          left: 16,
          right: 16,
          bottom: -30,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Transactions', '$transactionCount', Icons.receipt_long, '/transactions'),
                _buildVerticalDivider(),
                _buildStatItem('Quotes', '$offerCount', Icons.local_offer, '/my-offers'),
                _buildVerticalDivider(),
                _buildStatItem('Favorites', '$favoriteCount', Icons.favorite, '/favorites'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultAvatar() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Text(
          displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U',
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF2E7D32), size: 26),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF212121),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF757575),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      width: 1,
      height: 40,
      color: const Color(0xFFE0E0E0),
    );
  }

  void _showAvatarOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Profile Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
              ),
              title: const Text('Change Profile Photo'),
              onTap: () {
                Navigator.pop(context);
                _uploadAvatar();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit, color: Color(0xFF2E7D32)),
              ),
              title: const Text('Edit Profile'),
              onTap: () {
                Navigator.pop(context);
                _showEditProfileDialog();
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.qr_code, color: Color(0xFF2E7D32)),
              ),
              title: const Text('My QR Code'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('QR Code feature coming soon...')),
                );
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // ============================================
  // ✅ 修复：重写 Edit Profile 对话框，解决 infinite width 问题
  // ============================================
  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: displayName);
    final companyController = TextEditingController(text: companyName);
    final cityController = TextEditingController(text: city);
    final contactController = TextEditingController(text: contact);
    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (dialogContext) {
        bool isSaving = false;
        
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Container(
              // ✅ 修复：设置最大高度
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(dialogContext).size.height * 0.85,
              ),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ✅ 固定的头部
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      children: [
                        // Handle bar
                        Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        // Header row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Edit Profile',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            // ✅ 修复：Save 按钮使用 SizedBox 约束宽度
                            SizedBox(
                              width: 80,
                              child: TextButton(
                                onPressed: isSaving
                                    ? null
                                    : () => _saveProfile(
                                          dialogContext,
                                          formKey,
                                          nameController,
                                          companyController,
                                          cityController,
                                          contactController,
                                          setDialogState,
                                          (value) => isSaving = value,
                                        ),
                                child: isSaving
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Color(0xFF2E7D32),
                                        ),
                                      )
                                    : const Text(
                                        'Save',
                                        style: TextStyle(
                                          color: Color(0xFF2E7D32),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // ✅ 可滚动的表单内容
                  Flexible(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        MediaQuery.of(dialogContext).viewInsets.bottom + 20,
                      ),
                      child: Form(
                        key: formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Name field
                            _buildTextField(
                              controller: nameController,
                              label: 'Name *',
                              icon: Icons.person,
                              enabled: !isSaving,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Please enter your name';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Company field
                            _buildTextField(
                              controller: companyController,
                              label: 'Company Name',
                              icon: Icons.business,
                              enabled: !isSaving,
                            ),
                            const SizedBox(height: 16),
                            
                            // City field
                            _buildTextField(
                              controller: cityController,
                              label: 'City',
                              icon: Icons.location_city,
                              enabled: !isSaving,
                            ),
                            const SizedBox(height: 16),
                            
                            // Contact field
                            _buildTextField(
                              controller: contactController,
                              label: 'Contact Phone',
                              icon: Icons.phone,
                              hint: '+60 12-345-6789',
                              keyboardType: TextInputType.phone,
                              enabled: !isSaving,
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ✅ 抽取 TextField 组件
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF2E7D32)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2E7D32), width: 2),
        ),
        filled: true,
        fillColor: enabled ? Colors.white : Colors.grey[100],
      ),
      keyboardType: keyboardType,
      enabled: enabled,
      validator: validator,
    );
  }

  // ✅ 抽取保存逻辑
  Future<void> _saveProfile(
    BuildContext dialogContext,
    GlobalKey<FormState> formKey,
    TextEditingController nameController,
    TextEditingController companyController,
    TextEditingController cityController,
    TextEditingController contactController,
    StateSetter setDialogState,
    Function(bool) setIsSaving,
  ) async {
    if (!formKey.currentState!.validate()) return;

    setDialogState(() => setIsSaving(true));

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .set({
        'displayName': nameController.text.trim(),
        'companyName': companyController.text.trim(),
        'city': cityController.text.trim(),
        'contact': contactController.text.trim(),
        'email': email,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await user!.updateDisplayName(nameController.text.trim());

      if (mounted) {
        setState(() {
          displayName = nameController.text.trim();
          companyName = companyController.text.trim();
          city = cityController.text.trim();
          contact = contactController.text.trim();
        });

        Navigator.pop(dialogContext);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setDialogState(() => setIsSaving(false));
      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          SnackBar(
            content: Text('Failed to save: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildAccountCards() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 50, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Account Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.5,
            children: [
              _buildAccountCard(
                'Wallet Balance',
                'RM ${walletBalance.toStringAsFixed(2)}',
                Icons.account_balance_wallet,
                const LinearGradient(colors: [Color(0xFFFFC371), Color(0xFFFF5F6D)]),
                () => Navigator.pushNamed(context, '/wallet'),
              ),
              _buildAccountCard(
                'Membership',
                membershipTier,
                Icons.workspace_premium,
                const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFFFA500)]),
                () => Navigator.pushNamed(context, '/subscription'),
              ),
              _buildAccountCard(
                'Reward Points',
                '$rewardPoints Points',
                Icons.stars,
                const LinearGradient(colors: [Color(0xFFEC6EAD), Color(0xFF3494E6)]),
                () => Navigator.pushNamed(context, '/rewards'),
              ),
              _buildAccountCard(
                'Coupons',
                '$availableCoupons Available',
                Icons.confirmation_number,
                const LinearGradient(colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)]),
                () => Navigator.pushNamed(context, '/coupons'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountCard(
    String title,
    String value,
    IconData icon,
    Gradient gradient,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: Colors.white, size: 26),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        value,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMembershipSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, '/subscription'),
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFA500).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.workspace_premium, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upgrade to Pro',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Enjoy more features',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Upgrade Now',
                    style: TextStyle(
                      color: Color(0xFFFFA500),
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMyServicesSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'My Services',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildMenuItem(Icons.inventory_2_outlined, 'My Items', 'View all listings', '/marketplace'),
          const Divider(height: 1, indent: 56),
          _buildMenuItem(Icons.local_offer_outlined, 'My Quotes', 'View offers', '/my-offers'),
          const Divider(height: 1, indent: 56),
          _buildMenuItem(Icons.receipt_long_outlined, 'My Transactions', 'View transactions', '/transactions'),
          const Divider(height: 1, indent: 56),
          _buildMenuItem(Icons.favorite_outlined, 'My Favorites', 'View favorites', '/favorites'),
          const Divider(height: 1, indent: 56),
          _buildMenuItem(Icons.chat_bubble_outline, 'Messages', 'View messages', '/messages'),
          const Divider(height: 1, indent: 56),
          _buildMenuItem(Icons.bar_chart_outlined, 'My Statistics', 'View data', '/statistics'),
        ],
      ),
    );
  }

  Widget _buildSettingsSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Settings',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _buildMenuItem(Icons.settings_outlined, 'Account Settings', 'Personal Info, Security', '/account-settings'),
          const Divider(height: 1, indent: 56),
          _buildMenuItem(Icons.notifications_outlined, 'Notification Settings', 'Push, Message Alerts', '/notification-settings'),
          const Divider(height: 1, indent: 56),
          _buildMenuItem(Icons.language_outlined, 'Language', 'English', null),
          const Divider(height: 1, indent: 56),
          _buildMenuItem(Icons.help_outline, 'Help Center', 'FAQ', null),
          const Divider(height: 1, indent: 56),
          _buildMenuItem(Icons.info_outline, 'About Us', 'BBX v1.0.0', null),
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, String subtitle, String? route) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          if (route != null) {
            Navigator.pushNamed(context, route);
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$title feature coming soon...'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF2E7D32), size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF212121),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF757575),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF9E9E9E),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showLogoutDialog(),
          borderRadius: BorderRadius.circular(12),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.logout, color: Color(0xFFF44336), size: 22),
                SizedBox(width: 8),
                Text(
                  'Logout',
                  style: TextStyle(
                    color: Color(0xFFF44336),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            child: const Text(
              'Confirm',
              style: TextStyle(color: Color(0xFFF44336)),
            ),
          ),
        ],
      ),
    );
  }
}