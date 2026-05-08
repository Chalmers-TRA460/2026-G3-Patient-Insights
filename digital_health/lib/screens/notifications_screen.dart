import 'package:flutter/material.dart';
import 'package:get/get.dart';

// In-memory notification preferences backed by GetX reactive state.
// These preferences persist for the lifetime of the app session.
class _NotifPrefs extends GetxController {
  final visitReminders      = true.obs;
  final profileReminders    = true.obs;
  final consultationAlerts  = true.obs;
  final healthTips          = false.obs;
  final weeklyDigest        = false.obs;
}

final _prefs = _NotifPrefs();

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Notifications')),
      body: Obx(() => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _SectionHeader('Visit & Consultation'),
              _ToggleTile(
                icon: Icons.event_note_rounded,
                iconColor: Colors.blue,
                title: 'Visit Reminders',
                subtitle: 'Reminders before upcoming appointments',
                value: _prefs.visitReminders.value,
                onChanged: (v) => _prefs.visitReminders.value = v,
              ),
              _ToggleTile(
                icon: Icons.mic_rounded,
                iconColor: Colors.indigo,
                title: 'Consultation Alerts',
                subtitle:
                    'Notify when a recorded consultation summary is ready',
                value: _prefs.consultationAlerts.value,
                onChanged: (v) => _prefs.consultationAlerts.value = v,
              ),

              const SizedBox(height: 24),
              _SectionHeader('Profile & Health'),
              _ToggleTile(
                icon: Icons.analytics_rounded,
                iconColor: Colors.green,
                title: 'Profile Completion Reminders',
                subtitle:
                    'Nudges to fill in missing health profile fields',
                value: _prefs.profileReminders.value,
                onChanged: (v) => _prefs.profileReminders.value = v,
              ),
              _ToggleTile(
                icon: Icons.tips_and_updates_rounded,
                iconColor: Colors.orange,
                title: 'Health Tips',
                subtitle:
                    'Occasional tips based on your health conditions',
                value: _prefs.healthTips.value,
                onChanged: (v) => _prefs.healthTips.value = v,
              ),
              _ToggleTile(
                icon: Icons.summarize_rounded,
                iconColor: Colors.teal,
                title: 'Weekly Health Digest',
                subtitle: 'A brief weekly summary of your health activity',
                value: _prefs.weeklyDigest.value,
                onChanged: (v) => _prefs.weeklyDigest.value = v,
              ),

              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(16),
                  border:
                      Border.all(color: Colors.blue.withOpacity(0.15)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.info_outline_rounded,
                        color: Colors.blue, size: 20),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'These are in-app preferences. To manage system-level '
                        'push notifications, go to your phone\'s Settings → '
                        'Patient Insights.',
                        style: TextStyle(fontSize: 14, color: Colors.blueGrey),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          )),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String text;
  const _SectionHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(text,
          style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87)),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.grey)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
