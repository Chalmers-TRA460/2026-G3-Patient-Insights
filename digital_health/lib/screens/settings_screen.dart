import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/health_controller.dart';
import 'account_settings_screen.dart';
import 'notifications_screen.dart';
import 'privacy_security_screen.dart';
import 'help_support_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final HealthController healthController = Get.find<HealthController>();
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final name = user?.displayName ?? '';
    final initial = name.isNotEmpty
        ? name[0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : '?');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // User identity card
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor:
                      Theme.of(context).primaryColor.withOpacity(0.15),
                  child: Text(initial,
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name.isNotEmpty ? name : 'My Account',
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text(email,
                          style: const TextStyle(
                              fontSize: 14, color: Colors.grey)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Profile completion
          Obx(() => _buildTile(
                context,
                icon: Icons.analytics_rounded,
                iconColor: Colors.teal,
                title:
                    'Profile Completion — ${healthController.completionPercentage.toInt()}%',
                subtitle: healthController.completionPercentage < 100
                    ? 'Tap to complete your health profile'
                    : 'Your profile is complete',
                onTap: () => Get.toNamed('/edit-profile'),
              )),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),

          _buildTile(
            context,
            icon: Icons.person_outline_rounded,
            iconColor: Colors.blue,
            title: 'Account Settings',
            subtitle: 'Name, password, delete account',
            onTap: () => Get.to(() => const AccountSettingsScreen()),
          ),
          _buildTile(
            context,
            icon: Icons.notifications_none_rounded,
            iconColor: Colors.orange,
            title: 'Notifications',
            subtitle: 'Visit reminders and health alerts',
            onTap: () => Get.to(() => const NotificationsScreen()),
          ),
          _buildTile(
            context,
            icon: Icons.security_rounded,
            iconColor: Colors.green,
            title: 'Privacy & Security',
            subtitle: 'Data usage, GDPR, delete data',
            onTap: () => Get.to(() => const PrivacySecurityScreen()),
          ),
          _buildTile(
            context,
            icon: Icons.help_outline_rounded,
            iconColor: Colors.indigo,
            title: 'Help & Support',
            subtitle: 'FAQs and contact information',
            onTap: () => Get.to(() => const HelpSupportScreen()),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(),
          ),

          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child:
                  const Icon(Icons.logout_rounded, color: Colors.red, size: 22),
            ),
            title: const Text('Sign Out',
                style: TextStyle(
                    fontSize: 17,
                    color: Colors.red,
                    fontWeight: FontWeight.bold)),
            onTap: () {
              Get.defaultDialog(
                title: 'Sign Out',
                middleText: 'Are you sure you want to sign out?',
                textConfirm: 'Yes',
                textCancel: 'No',
                confirmTextColor: Colors.white,
                onConfirm: () => authController.signOut(),
              );
            },
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      subtitle:
          Text(subtitle, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      trailing:
          const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}
