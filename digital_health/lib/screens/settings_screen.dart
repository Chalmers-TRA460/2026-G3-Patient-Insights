import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/health_controller.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();
    final HealthController healthController = Get.find<HealthController>();
    final SettingsController settings = Get.find<SettingsController>();

    return Obx(() {
      // Subscribing to localeCode causes this entire Scaffold to rebuild
      // whenever the language is switched, so every .tr call re-evaluates.
      final isSv = settings.localeCode.value == 'sv';

      return Scaffold(
        appBar: AppBar(title: Text('settings.title'.tr)),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSettingTile(
              Icons.analytics_rounded,
              'Profile Completion: ${healthController.completionPercentage.toInt()}%',
              onTap: () => Get.toNamed('/edit-profile'),
            ),
            _buildSettingTile(
                Icons.person_outline_rounded, 'Account Settings'),
            _buildSettingTile(
                Icons.notifications_none_rounded, 'Notifications'),
            _buildSettingTile(Icons.security_rounded, 'Privacy & Security'),
            _buildSettingTile(Icons.help_outline_rounded, 'Help & Support'),

            const Divider(height: 40),

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
              child: Row(
                children: [
                  _langOption(
                    label: 'settings.language.english'.tr,
                    flag: '🇬🇧',
                    selected: !isSv,
                    onTap: () => settings.setLocale('en'),
                  ),
                  _langOption(
                    label: 'settings.language.swedish'.tr,
                    flag: '🇸🇪',
                    selected: isSv,
                    onTap: () => settings.setLocale('sv'),
                  ),
                ],
              ),
            ),

            const Divider(height: 40),

            // ── Sign out ────────────────────────────────────────────────────
            ListTile(
              leading: const Icon(Icons.logout_rounded,
                  color: Colors.red, size: 28),
              title: Text('settings.signout'.tr,
                  style: const TextStyle(
                      fontSize: 20,
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
          ],
        ),
      );
    });
  }

  Widget _langOption({
    required String label,
    required String flag,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.all(4),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: selected
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]
                : [],
          ),
          child: Column(
            children: [
              Text(flag, style: const TextStyle(fontSize: 26)),
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: selected
                          ? const Color(0xFF0066CC)
                          : Colors.grey)),
            ],
          ),
        ),
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
