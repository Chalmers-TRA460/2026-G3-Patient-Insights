import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: const Color(0xFF0066CC),
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.bold, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded, size: 28), label: 'Home'),
            BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded, size: 28), label: 'Visits'),
            BottomNavigationBarItem(
                icon: Icon(Icons.assignment_ind_rounded, size: 28),
                label: 'Records'),
            BottomNavigationBarItem(
                icon: Icon(Icons.settings_rounded, size: 28),
                label: 'Settings'),
          ],
        ),
      ),
    );
  }
}
