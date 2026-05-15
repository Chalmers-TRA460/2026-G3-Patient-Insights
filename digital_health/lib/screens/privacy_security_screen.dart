import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  void _confirmDeleteAccount(BuildContext context) {
    Get.defaultDialog(
      title: 'privacy.delete_all_title'.tr,
      titleStyle:
          const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
      middleText: 'privacy.delete_all_body'.tr,
      textConfirm: 'privacy.delete_all_confirm'.tr,
      textCancel: 'privacy.delete_all_cancel'.tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () async {
        Get.back();
        try {
          await FirebaseAuth.instance.currentUser?.delete();
          Get.offAllNamed('/login');
        } on FirebaseAuthException catch (e) {
          if (e.code == 'requires-recent-login') {
            Get.snackbar('privacy.delete_relogin_title'.tr,
                'privacy.delete_relogin_body'.tr,
                snackPosition: SnackPosition.BOTTOM);
          } else {
            Get.snackbar('privacy.delete_error_title'.tr,
                e.message ?? 'privacy.delete_error_body'.tr,
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
      appBar: AppBar(title: Text('privacy.title'.tr)),
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
                children: [
                  const Icon(Icons.shield_outlined,
                      size: 36, color: Colors.green),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('privacy.protected.title'.tr,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          'privacy.protected.body'.tr,
                          style: const TextStyle(
                              fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // What we collect
            _SectionTitle('privacy.section.collect'.tr),
            _BulletItem(Icons.person_outline_rounded, Colors.blue,
                'privacy.collect.account'.tr,
                'privacy.collect.account.body'.tr),
            _BulletItem(Icons.favorite_outline_rounded, Colors.red,
                'privacy.collect.health'.tr,
                'privacy.collect.health.body'.tr),
            _BulletItem(Icons.mic_none_rounded, Colors.purple,
                'privacy.collect.transcripts'.tr,
                'privacy.collect.transcripts.body'.tr),
            _BulletItem(Icons.chat_bubble_outline_rounded, Colors.orange,
                'privacy.collect.chat'.tr,
                'privacy.collect.chat.body'.tr),

            const SizedBox(height: 24),

            // How it's stored
            _SectionTitle('privacy.section.stored'.tr),
            _InfoCard(
              icon: Icons.storage_rounded,
              color: Colors.teal,
              title: 'privacy.stored.firebase.title'.tr,
              body: 'privacy.stored.firebase.body'.tr,
            ),
            const SizedBox(height: 12),
            _InfoCard(
              icon: Icons.lock_outline_rounded,
              color: Colors.indigo,
              title: 'privacy.stored.access.title'.tr,
              body: 'privacy.stored.access.body'.tr,
            ),

            const SizedBox(height: 24),

            // Third-party services
            _SectionTitle('privacy.section.third_party'.tr),
            _ThirdPartyRow(
                'privacy.tp.firebase.name'.tr,
                'privacy.tp.firebase.purpose'.tr,
                'privacy.tp.firebase.note'.tr),
            _ThirdPartyRow(
                'privacy.tp.openrouter.name'.tr,
                'privacy.tp.openrouter.purpose'.tr,
                'privacy.tp.openrouter.note'.tr),

            const SizedBox(height: 24),

            // Legal basis
            _SectionTitle('privacy.section.legal'.tr),
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
                children: [
                  Text(
                    'privacy.legal.body'.tr,
                    style: const TextStyle(fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 10),
                  _LegalRight('privacy.legal.right1'.tr),
                  _LegalRight('privacy.legal.right2'.tr),
                  _LegalRight('privacy.legal.right3'.tr),
                  _LegalRight('privacy.legal.right4'.tr),
                ],
              ),
            ),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 24),

            // Your controls
            _SectionTitle('privacy.section.controls'.tr),
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
              title: Text('privacy.controls.edit'.tr,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              subtitle: Text('privacy.controls.edit.sub'.tr,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
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
              title: Text('privacy.controls.delete'.tr,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.red)),
              subtitle: Text('privacy.controls.delete.sub'.tr,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
              onTap: () => _confirmDeleteAccount(context),
            ),

            const SizedBox(height: 32),
            Center(
              child: Text(
                'privacy.contact'.tr,
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
