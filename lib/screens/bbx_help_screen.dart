import 'package:flutter/material.dart';

class BBXHelpScreen extends StatelessWidget {
  const BBXHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('HelpWithBranch?),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'FAQ (FAQ)',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildFAQItem(
            'IfWhatReleaseWasteColTable?,
            'Click Home?"+" PressButton，Fill in waste info and submit?,
          ),
          _buildFAQItem(
            'IfWhatSubmitQuote?,
            'AtWasteColTablePage，Tap waste card for details，ThenAfterClick?SubmitQuote"PressButton?,
          ),
          _buildFAQItem(
            'IfWhatView MyPoints?,
            'OpenSideMenu，Click?RewardPoints"View?,
          ),
          _buildFAQItem(
            'IfWhatUpgradeSubscriptionPlan?,
            'OpenSideMenu，Click?SubscriptionPlan"，Select Suitable of Plan?,
          ),
          _buildFAQItem(
            'IfWhatContact Support?,
            'SendMail to support@bbx.com OrDial?+60 12-345-6789?,
          ),
          const SizedBox(height: 32),
          const Text(
            'UseTutorial',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTutorialCard(
            'ProducerPoint?,
            'Learn how to post and manage waste listings?,
            Icons.business,
            Colors.blue,
          ),
          _buildTutorialCard(
            'ProcessPersonPoint?,
            'LearnPracticeIfWhatSearchFindandQuoteWaste?,
            Icons.recycling,
            Colors.green,
          ),
          _buildTutorialCard(
            'TransactionFlowProcess',
            'edSolveDoneWhole of TransactionandPayment Process',
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
