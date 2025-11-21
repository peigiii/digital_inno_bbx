import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_theme.dart';
import '../../widgets/bbx_button.dart';
import '../../widgets/bbx_loading.dart';

class BBXAccountSettingsScreen extends StatefulWidget {
  const BBXAccountSettingsScreen({super.key});

  @override
  State<BBXAccountSettingsScreen> createState() =>
      _BBXAccountSettingsScreenState();
}

class _BBXAccountSettingsScreenState extends State<BBXAccountSettingsScreen> {
  final User? user = FirebaseAuth.instance.currentUser;
  bool isLoading = true;
  bool isSaving = false;

  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _companyController = TextEditingController();

  String? email;
  bool isVerified = false;
  bool isPhoneVerified = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (user == null) {
      setState(() => isLoading = false);
      return;
    }

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data()!;
        setState(() {
          _displayNameController.text = data['displayName'] ?? '';
          _phoneController.text = data['phone'] ?? '';
          _addressController.text = data['address'] ?? '';
          _companyController.text = data['companyName'] ?? '';
          email = data['email'] ?? user!.email;
          isVerified = data['isVerified'] ?? false;
          isPhoneVerified = data['isPhoneVerified'] ?? false;
        });
      }

      setState(() => isLoading = false);
    } catch (e) {
      debugPrint('Load user data failed: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isSaving = true);

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
        'displayName': _displayNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'companyName': _companyController.text.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

            await user!.updateDisplayName(_displayNameController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Saved successfully'),
            backgroundColor: AppTheme.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: AppTheme.error,
          ),
        );
      }
    } finally {
      setState(() => isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: BBXFullScreenLoading()),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Account Settings'),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isSaving)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _saveChanges,
              child: const Text('Save'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppTheme.spacing16),
          children: [
                        const Text('Personal Info', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.shadowSmall,
              ),
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _displayNameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    controller: _phoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      suffixIcon: isPhoneVerified
                          ? const Icon(
                              Icons.verified,
                              color: AppTheme.success,
                            )
                          : TextButton(
                              onPressed: () {
                                                              },
                              child: const Text('Verify'),
                            ),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: AppTheme.spacing16),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Address',
                      prefixIcon: Icon(Icons.location_on_outlined),
                    ),
                    maxLines: 2,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

                        const Text('Company Info', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.shadowSmall,
              ),
              padding: const EdgeInsets.all(AppTheme.spacing16),
              child: Column(
                children: [
                  TextFormField(
                    controller: _companyController,
                    decoration: const InputDecoration(
                      labelText: 'Company Name',
                      prefixIcon: Icon(Icons.business_outlined),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

                        const Text('Security', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.shadowSmall,
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email_outlined),
                    title: const Text('Email'),
                    subtitle: Text(email ?? 'Not set'),
                    trailing: isVerified
                        ? const Icon(Icons.verified, color: AppTheme.success)
                        : TextButton(
                            onPressed: () {
                                                          },
                            child: const Text('Verify'),
                          ),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Change Password'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => _showChangePasswordDialog(),
                  ),
                  const Divider(height: 1, indent: 56),
                  ListTile(
                    leading: const Icon(Icons.verified_user_outlined),
                    title: const Text('Identity Verification'),
                    subtitle: Text(isVerified ? 'Verified' : 'Unverified'),
                    trailing: Icon(
                      isVerified ? Icons.check_circle : Icons.chevron_right,
                      color: isVerified ? AppTheme.success : null,
                    ),
                    onTap: isVerified
                        ? null
                        : () {
                                                      },
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.spacing24),

                        const Text('Danger Zone', style: AppTheme.heading3),
            const SizedBox(height: AppTheme.spacing12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: AppTheme.shadowSmall,
              ),
              child: ListTile(
                leading: const Icon(Icons.delete_forever, color: AppTheme.error),
                title: const Text(
                  'Delete Account',
                  style: TextStyle(color: AppTheme.error),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDeleteAccountDialog(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: AppTheme.spacing16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          BBXPrimaryButton(
            text: 'Confirm',
            onPressed: () async {
              if (newPasswordController.text !=
                  confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }

                            Navigator.pop(context);
            },
            height: 40,
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Deleting account is permanent. All data will be lost.\n\nAre you sure you want to delete your account?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
                            Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.error),
            child: const Text('Confirm Delete'),
          ),
        ],
      ),
    );
  }
}
