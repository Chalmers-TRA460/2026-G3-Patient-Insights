import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  void _confirmDeleteAccount(BuildContext context) {
    Get.defaultDialog(
      title: 'Delete All Data',
      titleStyle:
          const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      middleText:
          'This will permanently delete your account and all health data stored on our servers. This action cannot be undone.',
      textConfirm: 'Delete Everything',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        try {
          await FirebaseAuth.instance.currentUser?.delete();
          Get.offAllNamed('/login');
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            Get.snackbar('Re-login Required',
                'Sign out and sign back in before deleting your account.',
                snackPosition: SnackPosition.BOTTOM);
          } else {
            Get.snackbar('Error', e.message ?? 'Could not delete account.',
                snackPosition: SnackPosition.BOTTOM);
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Privacy & Security')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: const [
                  Icon(Icons.shield_outlined, size: 36, color: Colors.green),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your data is protected',
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                        SizedBox(height: 4),
                        Text(
                          'We follow GDPR and the Swedish Patient Data Act (PDL).',
                          style:
                              TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // What we collect
            _SectionTitle('What Data We Collect'),
            _BulletItem(Icons.person_outline_rounded, Colors.blue,
                'Account information',
                'Name, email address, and sign-in provider (used to identify your account).'),
            _BulletItem(Icons.favorite_outline_rounded, Colors.red,
                'Health profile data',
                'Height, weight, blood type, medical conditions, medications, and vitals that you enter manually.'),
            _BulletItem(Icons.mic_none_rounded, Colors.purple,
                'Consultation transcripts',
                'Voice recordings are transcribed locally on your device. Only the text transcript and AI summary are stored.'),
            _BulletItem(Icons.chat_bubble_outline_rounded, Colors.orange,
                'AI chat messages',
                'Questions you ask the AI assistant, used only to generate a response. Conversations are not stored.'),

            const SizedBox(height: 24),

            // How it's stored
            _SectionTitle('How It Is Stored'),
            _InfoCard(
              icon: Icons.storage_rounded,
              color: Colors.teal,
              title: 'Firebase Firestore (Google Cloud)',
              body:
                  'Your health profile and consultation summaries are stored in Firebase Firestore, a secure cloud database. Data is encrypted at rest and in transit. Firebase is GDPR-compliant and its servers are located in the EU.',
            ),
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.lock_outline_rounded,
              color: Colors.indigo,
              title: 'Access Control',
              body:
                  'Your data is protected by Firebase Security Rules — only your authenticated account can read or write your documents. No one else, including the development team, has routine access to your personal health data.',
            ),

            const SizedBox(height: 24),

            // Third-party services
            _SectionTitle('Third-Party Services'),
            _ThirdPartyRow('Firebase (Google)', 'Authentication & database storage',
                'GDPR-compliant, EU servers'),
            _ThirdPartyRow('OpenRouter / Nvidia Nemotron',
                'AI-powered Q&A and consultation summarisation',
                'Queries contain health context — see OpenRouter\'s privacy policy.'),

            const SizedBox(height: 24),

            // Legal basis
            _SectionTitle('Legal Basis (GDPR / PDL)'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: Colors.amber.withOpacity(0.25)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'This is a university research project (TRA460, Chalmers University of Technology). '
                    'Data is processed on the basis of your explicit consent when you create an account. '
                    'Under GDPR (Art. 17) and the Swedish Patient Data Act, you have the right to:',
                    style: TextStyle(fontSize: 14, height: 1.5),
                  ),
                  SizedBox(height: 10),
                  _LegalRight('Access a copy of your data'),
                  _LegalRight('Correct inaccurate data'),
                  _LegalRight('Request erasure ("right to be forgotten")'),
                  _LegalRight('Withdraw consent at any time'),
                ],
              ),
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 24),

            // Your controls
            _SectionTitle('Your Controls'),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.edit_outlined,
                    color: Colors.blue, size: 22),
              ),
              title: const Text('Edit your health data',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              subtitle: const Text('Go to Health Profile → Edit',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              onTap: () => Get.toNamed('/edit-profile'),
            ),
            const SizedBox(height: 8),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_forever_rounded,
                    color: Colors.red, size: 22),
              ),
              title: const Text('Delete all my data',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red)),
              subtitle: const Text(
                  'Permanently removes your account and all stored health information.',
                  style: TextStyle(fontSize: 13, color: Colors.grey)),
              onTap: () => _confirmDeleteAccount(context),
            ),

            const SizedBox(height: 32),
            Center(
              child: Text(
                'For privacy enquiries: tra460.group3@chalmers.se\n'
                'Supervisory authority: IMY (Integritetsskyddsmyndigheten)',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// ── Reusable sub-widgets ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Text(text,
          style: const TextStyle(
              fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }
}

class _BulletItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _BulletItem(this.icon, this.color, this.title, this.body);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(body,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.black54, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  const _InfoCard(
      {required this.icon,
      required this.color,
      required this.title,
      required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(body,
                    style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                        height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThirdPartyRow extends StatelessWidget {
  final String name;
  final String purpose;
  final String note;
  const _ThirdPartyRow(this.name, this.purpose, this.note);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(name,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
          Text(purpose,
              style: const TextStyle(fontSize: 13, color: Colors.black54)),
          Text(note,
              style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontStyle: FontStyle.italic)),
          const SizedBox(height: 4),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class _LegalRight extends StatelessWidget {
  final String text;
  const _LegalRight(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 16, color: Colors.amber),
          const SizedBox(width: 8),
          Text(text, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}
