import 'package:flutter/material.dart';

/// 安全提示和教育页�?
/// 提供交易安全指南和防欺诈教育
class BBXSafetyTipsScreen extends StatelessWidget {
  const BBXSafetyTipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('安全指南'),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 头部提示
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
                        '安全交易',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        '保护您的账户和资金安�?,
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // 交易安全提示
          _buildSection(
            title: '交易安全提示',
            icon: Icons.shopping_cart,
            color: Colors.green,
            tips: [
              SafetyTip(
                icon: Icons.check_circle,
                title: '使用平台托管交易',
                description: '所有交易应通过平台托管系统进行，确保资金安全�?,
              ),
              SafetyTip(
                icon: Icons.verified_user,
                title: '选择认证用户',
                description: '优先与已完成身份认证和企业认证的用户交易�?,
              ),
              SafetyTip(
                icon: Icons.rate_review,
                title: '查看评价记录',
                description: '交易前查看对方的评价和信用评分�?,
              ),
              SafetyTip(
                icon: Icons.photo_camera,
                title: '保留交易凭证',
                description: '保存聊天记录、照片和发货凭证作为证据�?,
              ),
              SafetyTip(
                icon: Icons.local_shipping,
                title: '确认收货后再付款',
                description: '收到商品并确认无误后，再确认收货释放资金�?,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 防欺诈指�?
          _buildSection(
            title: '防欺诈指�?,
            icon: Icons.warning,
            color: Colors.orange,
            tips: [
              SafetyTip(
                icon: Icons.block,
                title: '不要线下交易',
                description: '拒绝任何要求线下交易、直接转账的请求�?,
              ),
              SafetyTip(
                icon: Icons.money_off,
                title: '警惕超低价格',
                description: '明显低于市场价的商品可能是欺诈，需谨慎�?,
              ),
              SafetyTip(
                icon: Icons.link_off,
                title: '不要点击外部链接',
                description: '不要点击陌生链接或下载未知文件�?,
              ),
              SafetyTip(
                icon: Icons.phone_disabled,
                title: '保护个人信息',
                description: '不要随意透露银行卡号、密码等敏感信息�?,
              ),
              SafetyTip(
                icon: Icons.report,
                title: '遇到问题及时举报',
                description: '发现可疑行为立即向平台举报�?,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 常见骗术识别
          _buildSection(
            title: '常见骗术识别',
            icon: Icons.psychology,
            color: Colors.red,
            tips: [
              SafetyTip(
                icon: Icons.credit_card,
                title: '虚假付款截图',
                description: '要求先发货后付款，提供假的付款凭证�?,
                danger: true,
              ),
              SafetyTip(
                icon: Icons.settings_overscan,
                title: '二维码诈�?,
                description: '发送假的收款码或支付码进行诈骗�?,
                danger: true,
              ),
              SafetyTip(
                icon: Icons.swap_horiz,
                title: '以次充好',
                description: '用假冒伪劣商品替代真品�?,
                danger: true,
              ),
              SafetyTip(
                icon: Icons.person_off,
                title: '虚假身份',
                description: '冒充平台客服或管理员进行诈骗�?,
                danger: true,
              ),
              SafetyTip(
                icon: Icons.email,
                title: '钓鱼信息',
                description: '发送假冒的系统通知诱导点击链接�?,
                danger: true,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 账户安全
          _buildSection(
            title: '账户安全',
            icon: Icons.lock,
            color: Colors.purple,
            tips: [
              SafetyTip(
                icon: Icons.password,
                title: '使用强密�?,
                description: '设置复杂密码，包含字母、数字和特殊字符�?,
              ),
              SafetyTip(
                icon: Icons.fingerprint,
                title: '启用生物识别',
                description: '开启指纹或面容识别登录，提升安全性�?,
              ),
              SafetyTip(
                icon: Icons.phone_android,
                title: '绑定手机�?,
                description: '绑定手机号以便找回密码和接收安全提醒�?,
              ),
              SafetyTip(
                icon: Icons.logout,
                title: '定期退出登�?,
                description: '在公共设备使用后及时退出账号�?,
              ),
              SafetyTip(
                icon: Icons.update,
                title: '及时更新应用',
                description: '保持应用为最新版本，获取安全更新�?,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // 紧急联�?
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
                        '遇到问题�?,
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
                    '如果您遇到安全问题或发现可疑行为�?,
                    style: TextStyle(color: Colors.red[900]),
                  ),
                  const SizedBox(height: 8),
                  _buildContactItem(
                    Icons.report_problem,
                    '立即举报',
                    '使用举报功能向平台举�?,
                  ),
                  _buildContactItem(
                    Icons.chat,
                    '联系客服',
                    '通过在线客服获取帮助',
                  ),
                  _buildContactItem(
                    Icons.email,
                    '邮件联系',
                    'support@bbx.com',
                  ),
                  _buildContactItem(
                    Icons.phone,
                    '客服热线',
                    '1-800-BBX-HELP',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 底部提示
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
                    '平台永远不会要求您提供密码或进行线下交易。保持警惕，保护自己�?,
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

/// 安全提示数据模型
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
