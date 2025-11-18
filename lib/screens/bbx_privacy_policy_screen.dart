import 'package:flutter/material.dart';

class BBXPrivacyPolicyScreen extends StatelessWidget {
  const BBXPrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('隐私政策'),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'BBX 隐私政策',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '最后更新：${DateTime.now().year}年${DateTime.now().month}月',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. 信息收集',
              '我们收集以下类型的信息：\n'
              '• 账户信息（姓名、邮箱、电话）\n'
              '• 公司信息（公司名称、地址）\n'
              '• 交易记录\n'
              '• 设备信息\n'
              '• 使用数据',
            ),
            _buildSection(
              '2. 信息使用',
              '我们使用收集的信息用于：\n'
              '• 提供和改进服务\n'
              '• 处理交易\n'
              '• 发送通知和更新\n'
              '• 分析使用情况\n'
              '• 防止欺诈',
            ),
            _buildSection(
              '3. 信息共享',
              '我们不会出售您的个人信息。我们可能与以下方共享信息：\n'
              '• 交易对方（仅限必要信息）\n'
              '• 服务提供商\n'
              '• 法律要求的情况',
            ),
            _buildSection(
              '4. 数据安全',
              '我们采用行业标准的安全措施保护您的数据，包括：\n'
              '• 加密传输\n'
              '• 安全存储\n'
              '• 访问控制\n'
              '• 定期安全审计',
            ),
            _buildSection(
              '5. 您的权利',
              '您有权：\n'
              '• 访问您的数据\n'
              '• 更正不准确的数据\n'
              '• 删除您的账户\n'
              '• 导出您的数据\n'
              '• 拒绝营销通讯',
            ),
            _buildSection(
              '6. 联系我们',
              '如有任何隐私问题，请联系：\n'
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
