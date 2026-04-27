import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/health_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final HealthController healthController = Get.find<HealthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Obx(() => _buildSettingTile(
            Icons.analytics_rounded, 
            'Profile Completion: ${healthController.completionPercentage.toInt()}%',
            onTap: () => Get.toNamed('/edit-profile'),
          )),
          _buildSettingTile(Icons.person_outline_rounded, 'Account Settings'),
          _buildSettingTile(Icons.notifications_none_rounded, 'Notifications'),
          _buildSettingTile(Icons.security_rounded, 'Privacy & Security'),
          _buildSettingTile(Icons.help_outline_rounded, 'Help & Support'),
          const Divider(height: 40),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.red, size: 28),
            title: const Text('Sign Out', style: TextStyle(fontSize: 20, color: Colors.red, fontWeight: FontWeight.bold)),
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
        ],
      ),
    );
  }

  Widget _buildSettingTile(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, size: 28),
      title: Text(title, style: const TextStyle(fontSize: 20)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 18),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      onTap: onTap ?? () {},
    );
  }
}
