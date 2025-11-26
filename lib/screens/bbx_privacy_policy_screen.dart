import 'package:flutter/material.dart';

class BBXPrivacyPolicyScreen extends StatelessWidget {
  const BBXPrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BBX Privacy Policy',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'MostAfterUpdate：${DateTime.now().year}?{DateTime.now().month}?,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. InfoCollectGather',
              'We collect followingType of Info：\n'
              '?Account Info（Name、Email、Phone）\n'
              '?Company Info（CompanyName、Address）\n'
              '?TransactionRecord\n'
              '?SetPrepInfo\n'
              '?UseData',
            ),
            _buildSection(
              '2. InfoUse',
              'We use collected of InfoUseAt：\n'
              '?Provide and improve services\n'
              '?Process Transaction\n'
              '?SendNotificationandUpdate\n'
              '?AnalysisUseEmotionSituation\n'
              '?Prevent Fraud',
            ),
            _buildSection(
              '3. InfoShare',
              'We will not sell your personal information。We may share withInfo：\n'
              '?TransactionPairSquare（OnlyLimitMustWantInfo）\n'
              '?ServiceLiftSupplyBusiness\n'
              '?LawWantRequest of Emotion?,
            ),
            _buildSection(
              '4. DataSecure',
              'We use industry-standard security measures to protect your data，Include：\n'
              '?EncryptTransfer\n'
              '?SecureStorage\n'
              '?Access Control\n'
              '?SetPeriodSecureAudit',
            ),
            _buildSection(
              '5. Your RightProfit',
              'YouHaveRight：\n'
              '?VisitAskYour Data\n'
              '?MoreRightNoAccurateSure of Data\n'
              '?DeleteYour Account\n'
              '?ExportYour Data\n'
              '?RejectMarketing Comms',
            ),
            _buildSection(
              '6. ContactIs',
              'If any privacy issues，PleaseContact：\n'
              'Email: privacy@bbx.com\n'
              'Phone: +60 12-345-6789\n'
              'Address: Kuching, Sarawak, Malaysia',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: const TextStyle(height: 1.5),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
