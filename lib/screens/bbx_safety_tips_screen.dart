import 'package:flutter/material.dart';

class BBXSafetyTipsScreen extends StatelessWidget {
  const BBXSafetyTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SecureGuide'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
                    Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[500]!],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              children: [
                Icon(Icons.security, size: 48, color: Colors.white),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SecureTransaction',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'ProtectYour AccountandFund Safety?,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

                    _buildSection(
            title: 'TransactionSecureInfo',
            icon: Icons.shopping_cart,
            color: Colors.green,
            tips: [
              SafetyTip(
                icon: Icons.check_circle,
                title: 'UsePlatformEscrow Transaction',
                description: 'AllTransactionShouldPassPlatformTrustPipeSystemEnterRow，Ensure FundsSecure?,
              ),
              SafetyTip(
                icon: Icons.verified_user,
                title: 'SelectAuthenticateUser',
                description: 'Prioritize CompletedIdentityAuthenticateandEnterprise Verification of User Transaction?,
              ),
              SafetyTip(
                icon: Icons.rate_review,
                title: 'View Review History',
                description: 'TransactionFrontViewPairSquare of ReviewandCredit Score?,
              ),
              SafetyTip(
                icon: Icons.photo_camera,
                title: 'Keep transaction proofs',
                description: 'SaveChatRecord、Photos and shipping proof as evidence?,
              ),
              SafetyTip(
                icon: Icons.local_shipping,
                title: 'Confirm receipt before payment',
                description: 'Received item andConfirmNoneMistakeAfter，AgainConfirmReceive and release funds?,
              ),
            ],
          ),
          const SizedBox(height: 24),

                    _buildSection(
            title: 'Fraud Prevention Guide?,
            icon: Icons.warning,
            color: Colors.orange,
            tips: [
              SafetyTip(
                icon: Icons.block,
                title: 'Do not trade offline',
                description: 'RejectTaskWhatWantRequestOfflineTransaction、Direct Transfer of Request?,
              ),
              SafetyTip(
                icon: Icons.money_off,
                title: 'Beware of ultra lowPrice',
                description: 'Items significantly below market price may be fraudulent，NeedCautionCaution?,
              ),
              SafetyTip(
                icon: Icons.link_off,
                title: 'NoWantClickOuterPartLink',
                description: 'Do not click unknown links or download files?,
              ),
              SafetyTip(
                icon: Icons.phone_disabled,
                title: 'ProtectIndividualInfo',
                description: 'Do not reveal bank card numbers、PasswordWaitSensitiveFeelInfo?,
              ),
              SafetyTip(
                icon: Icons.report,
                title: 'Report problems promptlyReport',
                description: 'DiscoverCanDoubtRowForNowTowardsPlatformReport?,
              ),
            ],
          ),
          const SizedBox(height: 24),

                    _buildSection(
            title: 'Common Scam Identification',
            icon: Icons.psychology,
            color: Colors.red,
            tips: [
              SafetyTip(
                icon: Icons.credit_card,
                title: 'VirtualFalsePaymentScreenshot',
                description: 'Require ship before pay，LiftSupplyFalse of PaymentProofProof?,
                danger: true,
              ),
              SafetyTip(
                icon: Icons.settings_overscan,
                title: 'QR CodeFraud?,
                description: 'Sending fake payment codes to scam?,
                danger: true,
              ),
              SafetyTip(
                icon: Icons.swap_horiz,
                title: 'Substandard goods',
                description: 'UseFalseCounterfeitItemReplaceTrueItem?,
                danger: true,
              ),
              SafetyTip(
                icon: Icons.person_off,
                title: 'VirtualFalseIdentity',
                description: 'Impersonating support or admin to scam?,
                danger: true,
              ),
              SafetyTip(
                icon: Icons.email,
                title: 'FishFishInfo',
                description: 'Sending fake system notifications to induce clicks?,
                danger: true,
              ),
            ],
          ),
          const SizedBox(height: 24),

                    _buildSection(
            title: 'AccountSecure',
            icon: Icons.lock,
            color: Colors.purple,
            tips: [
              SafetyTip(
                icon: Icons.password,
                title: 'Use strong passwords?,
                description: 'SettingsComplexPassword，ContainWordMother、NumberandSpecialSpecialWordSymbol?,
              ),
              SafetyTip(
                icon: Icons.fingerprint,
                title: 'EnableBirthThingKnowOther',
                description: 'Enable fingerprint or face ID login，LiftRiseSecureNature?,
              ),
              SafetyTip(
                icon: Icons.phone_android,
                title: 'Bind Phone?,
                description: 'Bind phone number to recover password and receive security alerts?,
              ),
              SafetyTip(
                icon: Icons.logout,
                title: 'SetPeriodLogoutClimb?,
                description: 'AtPublicCommonSetPrepUseAfterAndTimeLogoutAccount?,
              ),
              SafetyTip(
                icon: Icons.update,
                title: 'AndTimeUpdateApp',
                description: 'ProtectHoldAppForLatest Version，GetSecureUpdate?,
              ),
            ],
          ),
          const SizedBox(height: 24),

                    Card(
            color: Colors.red[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.support_agent, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Text(
                        'MeetToQuestion?,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'If you encounter security issues or suspicious behavior?,
                    style: TextStyle(color: Colors.red[900]),
                  ),
                  const SizedBox(height: 8),
                  _buildContactItem(
                    Icons.report_problem,
                    'NowReport',
                    'Use the report function to report to the platform?,
                  ),
                  _buildContactItem(
                    Icons.chat,
                    'Contact Support',
                    'PassOnlineSupportGetHelp',
                  ),
                  _buildContactItem(
                    Icons.email,
                    'EmailContact',
                    'support@bbx.com',
                  ),
                  _buildContactItem(
                    Icons.phone,
                    'SupportHotLine',
                    '1-800-BBX-HELP',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

                    Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.blue[700]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'The platform will never ask for your password or offline transactions。Stay vigilant，ProtectSelfSelf?,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<SafetyTip> tips,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...tips.map((tip) => _buildTipCard(tip)),
      ],
    );
  }

  Widget _buildTipCard(SafetyTip tip) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: tip.danger
                    ? Colors.red[100]
                    : Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                tip.icon,
                size: 20,
                color: tip.danger ? Colors.red[700] : Colors.green[700],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tip.description,
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.red[700]),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SafetyTip {
  final IconData icon;
  final String title;
  final String description;
  final bool danger;

  SafetyTip({
    required this.icon,
    required this.title,
    required this.description,
    this.danger = false,
  });
}
