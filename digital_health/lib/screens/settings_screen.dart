import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/health_controller.dart';
import '../controllers/settings_controller.dart';
import 'account_settings_screen.dart';
import 'notifications_screen.dart';
import 'privacy_security_screen.dart';
import 'caregiver_screen.dart';
import 'family_access_screen.dart';
import 'help_support_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final HealthController healthController = Get.find<HealthController>();
    final SettingsController settings = Get.find<SettingsController>();

    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? '';
    final name = user?.displayName ?? '';
    final initial = name.isNotEmpty
        ? name[0].toUpperCase()
        : (email.isNotEmpty ? email[0].toUpperCase() : '?');

    return Obx(() {
      final localeCode = settings.localeCode.value;

      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: Text('settings.title'.tr)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── User identity card ──────────────────────────────────────────
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
                        Text(name.isNotEmpty ? name : 'settings.my_account'.tr,
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

            // ── Profile completion ──────────────────────────────────────────
            Obx(() => _buildTile(
                  context,
                  icon: Icons.analytics_rounded,
                  iconColor: Colors.teal,
                  title: 'settings.profile_completion'.trParams({
                    'pct': healthController.completionPercentage.toInt().toString(),
                  }),
                  subtitle: healthController.completionPercentage < 100
                      ? 'settings.profile_completion.tap'.tr
                      : 'settings.profile_completion.done'.tr,
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
              title: 'settings.account'.tr,
              subtitle: 'settings.account.sub'.tr,
              onTap: () => Get.to(() => const AccountSettingsScreen()),
            ),
            _buildTile(
              context,
              icon: Icons.notifications_none_rounded,
              iconColor: Colors.orange,
              title: 'settings.notifications'.tr,
              subtitle: 'settings.notifications.sub'.tr,
              onTap: () => Get.to(() => const NotificationsScreen()),
            ),
            _buildTile(
              context,
              icon: Icons.security_rounded,
              iconColor: Colors.green,
              title: 'settings.privacy'.tr,
              subtitle: 'settings.privacy.sub'.tr,
              onTap: () => Get.to(() => const PrivacySecurityScreen()),
            ),
            _buildTile(
              context,
              icon: Icons.people_rounded,
              iconColor: Colors.purple,
              title: 'caregiver.settings_title'.tr,
              subtitle: 'caregiver.settings_subtitle'.tr,
              onTap: () => Get.to(() => const CaregiverScreen()),
            ),
            _buildTile(
              context,
              icon: Icons.family_restroom_rounded,
              iconColor: Colors.teal,
              title: 'family.settings_title'.tr,
              subtitle: 'family.settings_subtitle'.tr,
              onTap: () => Get.to(() => const FamilyAccessScreen()),
            ),
            _buildTile(
              context,
              icon: Icons.help_outline_rounded,
              iconColor: Colors.indigo,
              title: 'settings.help'.tr,
              subtitle: 'settings.help.sub'.tr,
              onTap: () => Get.to(() => const HelpSupportScreen()),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(),
            ),

            // ── Accessibility / Senior Mode ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('settings.accessibility'.tr,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SwitchListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                secondary: const Icon(Icons.accessibility_new_rounded,
                    size: 28, color: Color(0xFF0066CC)),
                title: Text('settings.accessibility.senior'.tr,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                subtitle: Text('settings.accessibility.desc'.tr,
                    style: const TextStyle(fontSize: 13)),
                value: settings.isAccessibilityMode.value,
                activeColor: const Color(0xFF0066CC),
                onChanged: (_) => settings.toggleAccessibilityMode(),
              ),
            ),

            const Divider(height: 40),

            // ── Language ────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('settings.language'.tr,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey)),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: Text(
                  localeCode == 'sv' ? '🇸🇪' : localeCode == 'default' ? '🌐' : '🇬🇧',
                  style: const TextStyle(fontSize: 28),
                ),
                title: Text(
                  localeCode == 'sv'
                      ? 'settings.language.swedish'.tr
                      : localeCode == 'default'
                          ? 'settings.language.default'.tr
                          : 'settings.language.english'.tr,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                onTap: settings.showLanguageSheet,
              ),
            ),

            const Divider(height: 40),

            // ── Sign out ────────────────────────────────────────────────────
            ListTile(
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout_rounded, color: Colors.red, size: 22),
              ),
              title: Text('settings.signout'.tr,
                  style: const TextStyle(
                      fontSize: 17,
                      color: Colors.red,
                      fontWeight: FontWeight.bold)),
              onTap: () {
                Get.defaultDialog(
                  title: 'settings.signout'.tr,
                  middleText: 'settings.signout.confirm'.tr,
                  textConfirm: 'settings.signout.yes'.tr,
                  textCancel: 'settings.signout.no'.tr,
                  confirmTextColor: Colors.white,
                  onConfirm: () => authController.signOut(),
                );
              },
            ),

            const SizedBox(height: 40),
          ],
        ),
      );
    });
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
