import 'package:flutter/material.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const _faqs = [
    _Faq(
      q: 'What does Patient Insights do?',
      a: 'Patient Insights helps you understand your clinical records from 1177.se in plain, everyday language. You can record consultations, get AI-assisted explanations, and manage your health profile — all in one place.',
    ),
    _Faq(
      q: 'How do I record a consultation?',
      a: 'Tap the microphone icon on the home screen or go to the "Record Consultation" option. The app listens to your appointment in real time and generates a plain-language summary using AI once you stop recording.',
    ),
    _Faq(
      q: 'How do I ask the AI a health question?',
      a: 'Go to the AI Chat tab (the chat bubble icon in the bottom navigation). Type or speak your question — the AI uses your health profile to give you personalised answers.',
    ),
    _Faq(
      q: 'How do I add a medical condition or medication?',
      a: 'Go to Settings → Profile Completion, or open your Health Profile and tap "Edit". You can add conditions and medications from there.',
    ),
    _Faq(
      q: 'Is my health data private?',
      a: 'Yes. Your data is stored securely in Firebase Firestore and is only accessible to your account. We do not share your personal health information with third parties. See Privacy & Security for full details.',
    ),
    _Faq(
      q: 'Can I delete my account and data?',
      a: 'Yes. Go to Settings → Account Settings → Delete Account. This permanently removes your account and all associated health data.',
    ),
    _Faq(
      q: 'The AI summary doesn\'t look right — what should I do?',
      a: 'AI summaries are for informational purposes only and may not be fully accurate. Always verify health information with your doctor. You can re-record the consultation or contact support if you notice a systematic issue.',
    ),
    _Faq(
      q: 'Which languages does the app support?',
      a: 'The app interface is currently in English. The AI can understand and respond in both English and Swedish, making it suitable for patients who receive care in Sweden.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Help & Support')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.primaryColor.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(Icons.support_agent_rounded,
                      size: 48, color: theme.primaryColor),
                  const SizedBox(height: 12),
                  const Text('How can we help?',
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text(
                    'Find answers below or reach out to us directly.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // FAQ
            const Text('Frequently Asked Questions',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._faqs.map((faq) => _FaqTile(faq: faq)),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),

            // Contact
            const Text('Contact Us',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _ContactTile(
              icon: Icons.email_outlined,
              iconColor: Colors.blue,
              title: 'Email Support',
              subtitle: 'tra460.group3@chalmers.se',
              onTap: () {/* mailto could be added here */},
            ),
            _ContactTile(
              icon: Icons.school_outlined,
              iconColor: Colors.indigo,
              title: 'Course Project',
              subtitle: 'TRA460 — Chalmers University of Technology',
              onTap: null,
            ),
            _ContactTile(
              icon: Icons.local_hospital_outlined,
              iconColor: Colors.red,
              title: 'Clinical Mentor',
              subtitle:
                  'Sara Hansson — Specialist in Anesthesia & Intensive Care\nSahlgrenska University Hospital',
              onTap: null,
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),

            // About
            const Text('About',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _InfoRow('App name', 'Patient Insights'),
            _InfoRow('Version', '1.0.0'),
            _InfoRow('Group', 'TRA460 Group 3 — Chalmers University'),
            _InfoRow('Members',
                'Xiaoyu Chen · Xiyu Du · Nathalie Hogberg · Sugash Krishnamoorthy'),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Faq {
  final String q;
  final String a;
  const _Faq({required this.q, required this.a});
}

class _FaqTile extends StatelessWidget {
  final _Faq faq;
  const _FaqTile({required this.faq});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: ExpansionTile(
        tilePadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding:
            const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Text(faq.q,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600)),
        children: [
          Text(faq.a,
              style:
                  const TextStyle(fontSize: 14, color: Colors.black87, height: 1.5)),
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const _ContactTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding:
          const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(
              fontSize: 16, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: const TextStyle(fontSize: 13, color: Colors.grey)),
      onTap: onTap,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
