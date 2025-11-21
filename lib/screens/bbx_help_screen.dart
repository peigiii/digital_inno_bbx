import 'package:flutter/material.dart';

class BBXHelpScreen extends StatelessWidget {
  const BBXHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('帮助与支?),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '常见问题 (FAQ)',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            '如何发布废料列表?,
            '点击主页?"+" 按钮，填写废料信息后提交即可?,
          ),
          _buildFAQItem(
            '如何提交Quote?,
            '在废料列表页面，点击废料卡片进入详情，然后点?提交Quote"按钮?,
          ),
          _buildFAQItem(
            '如何查看我的积分?,
            '打开侧边菜单，点?奖励积分"查看?,
          ),
          _buildFAQItem(
            '如何升级订阅计划?,
            '打开侧边菜单，点?订阅计划"，选择合适的计划?,
          ),
          _buildFAQItem(
            '如何联系客服?,
            '发送邮件至 support@bbx.com 或拨?+60 12-345-6789?,
          ),
          const SizedBox(height: 32),
          const Text(
            '使用教程',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTutorialCard(
            'Producer指?,
            '学习如何发布和管理废料列?,
            Icons.business,
            Colors.blue,
          ),
          _buildTutorialCard(
            '处理者指?,
            '学习如何寻找和Quote废?,
            Icons.recycling,
            Colors.green,
          ),
          _buildTutorialCard(
            '交易流程',
            '了解完整的交易和付款流程',
            Icons.swap_horiz,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(answer),
          ),
        ],
      ),
    );
  }

  Widget _buildTutorialCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: color, size: 40),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: () {
                  },
      ),
    );
  }
}
