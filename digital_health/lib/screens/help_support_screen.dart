import 'package:flutter/material.dart';
import 'package:get/get.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static List<_Faq> get _faqs => [
        _Faq(q: 'help.faq.q1'.tr, a: 'help.faq.a1'.tr),
        _Faq(q: 'help.faq.q2'.tr, a: 'help.faq.a2'.tr),
        _Faq(q: 'help.faq.q3'.tr, a: 'help.faq.a3'.tr),
        _Faq(q: 'help.faq.q4'.tr, a: 'help.faq.a4'.tr),
        _Faq(q: 'help.faq.q5'.tr, a: 'help.faq.a5'.tr),
        _Faq(q: 'help.faq.q6'.tr, a: 'help.faq.a6'.tr),
        _Faq(q: 'help.faq.q7'.tr, a: 'help.faq.a7'.tr),
        _Faq(q: 'help.faq.q8'.tr, a: 'help.faq.a8'.tr),
      ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('help.title'.tr)),
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
                  Text('help.hero.title'.tr,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  Text(
                    'help.hero.sub'.tr,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Colors.grey),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // FAQ
            Text('help.faq.title'.tr,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ..._faqs.map((faq) => _FaqTile(faq: faq)),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),

            // Contact
            Text('help.contact.title'.tr,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _ContactTile(
              icon: Icons.email_outlined,
              iconColor: Colors.blue,
              title: 'help.contact.email'.tr,
              subtitle: 'help.contact.email.value'.tr,
              onTap: () {/* mailto could be added here */},
            ),
            _ContactTile(
              icon: Icons.school_outlined,
              iconColor: Colors.indigo,
              title: 'help.contact.project'.tr,
              subtitle: 'help.contact.project.value'.tr,
              onTap: null,
            ),
            _ContactTile(
              icon: Icons.local_hospital_outlined,
              iconColor: Colors.red,
              title: 'help.contact.mentor'.tr,
              subtitle: 'help.contact.mentor.value'.tr,
              onTap: null,
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 24),

            // About
            Text('help.about.title'.tr,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _InfoRow('help.about.app'.tr, 'help.about.app.value'.tr),
            _InfoRow('help.about.version'.tr, 'help.about.version.value'.tr),
            _InfoRow('help.about.group'.tr, 'help.about.group.value'.tr),
            _InfoRow('help.about.members'.tr, 'help.about.members.value'.tr),
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
