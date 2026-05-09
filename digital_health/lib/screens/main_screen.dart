import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import 'home_screen.dart';
import 'health_profile_screen.dart';
import 'consultation_history_screen.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _openHealthProfile() {
    final HealthController controller = Get.find<HealthController>();
    if (!controller.canAccessHealthProfile) {
      controller.promptProfileUpdate();
      return;
    }

    setState(() => _currentIndex = 2);
  }

  final List<Widget> _screens = [
    const HomeScreen(),
    const ConsultationHistoryScreen(),
    const HealthProfileScreen(),
    const SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 2) {
              _openHealthProfile();
              return;
            }

            setState(() => _currentIndex = index);
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0066CC),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: [
            BottomNavigationBarItem(
                icon: const Icon(Icons.home_rounded, size: 28),
                label: 'nav.home'.tr),
            BottomNavigationBarItem(
                icon: const Icon(Icons.history_rounded, size: 28),
                label: 'nav.visits'.tr),
            BottomNavigationBarItem(
                icon: const Icon(Icons.assignment_ind_rounded, size: 28),
                label: 'nav.profile'.tr),
            BottomNavigationBarItem(
                icon: const Icon(Icons.settings_rounded, size: 28),
                label: 'nav.settings'.tr),
          ],
        ),
      ),
    );
  }
}
