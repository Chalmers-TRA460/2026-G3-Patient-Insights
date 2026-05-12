import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import '../widgets/viewing_banner.dart';
import 'edit_profile_screen.dart';

class HealthProfileScreen extends StatelessWidget {
  const HealthProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HealthController controller = Get.find<HealthController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('profile.title'.tr),
        actions: [
          Obx(() => controller.isViewingOther
              ? const SizedBox.shrink()
              : TextButton(
                  onPressed: () => Get.to(
                        () => const EditProfileScreen(),
                        fullscreenDialog: true,
                      ),
                  child: Text('profile.edit'.tr,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                )),
        ],
      ),
      body: Obx(() {
        final patient = controller.effectivePatient;
        if (patient == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // When viewing a family member, use their stored name directly.
        // For own profile, prefer the Firebase Auth displayName.
        final authName = controller.isViewingOther
            ? ''
            : (FirebaseAuth.instance.currentUser?.displayName ?? '');
        final displayName = authName.isNotEmpty
            ? authName
            : (patient.name != 'User' ? patient.name : 'User');
        final initial = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'U';

        return Column(
          children: [
            const ViewingBanner(),
            Expanded(child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor:
                        Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Text(initial,
                        style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor)),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                            style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold)),
                        Text(
                            'profile.age_blood'.trParams({
                              'age': patient.age.toString(),
                              'blood': patient.bloodType,
                            }),
                            style: const TextStyle(
                                fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Vitals
              Text('profile.vitals'.tr,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildVitalCard('profile.bp'.tr,
                        patient.vitals['bp'] ?? '120/80', 'mmHg',
                        Icons.speed_rounded, Colors.blue),
                    _buildVitalCard('profile.hr'.tr,
                        patient.vitals['hr'] ?? '72', 'bpm',
                        Icons.favorite_rounded, Colors.red),
                    _buildVitalCard('profile.glucose'.tr,
                        patient.vitals['glucose'] ?? '98', 'mg/dL',
                        Icons.water_drop_rounded, Colors.orange),
                    _buildVitalCard('profile.oxygen'.tr,
                        patient.vitals['spo2'] ?? '98', '%',
                        Icons.air_rounded, Colors.teal),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // BMI
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('profile.bmi'.tr,
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              '${patient.bmi.toStringAsFixed(1)} - ${patient.bmiStatus}',
                              style: TextStyle(
                                  fontSize: 22,
                                  color: Theme.of(context).primaryColor,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Icon(Icons.monitor_weight_rounded,
                        size: 40, color: Colors.blueGrey),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              _buildSectionHeader('profile.conditions'.tr),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: patient.conditions
                    .map((c) => Chip(
                          label: Text(c,
                              style: const TextStyle(fontSize: 16)),
                          backgroundColor:
                              Colors.blue.withOpacity(0.05),
                          side: BorderSide(
                              color: Colors.blue.withOpacity(0.2)),
                        ))
                    .toList(),
              ),

              const SizedBox(height: 30),

              _buildSectionHeader('profile.medications'.tr),
              ...patient.medications.map((m) => ListTile(
                    leading: const Icon(Icons.medication_rounded,
                        color: Colors.purple),
                    title: Text(m['name'] ?? '',
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${m['dosage']} - ${m['frequency']}',
                        style: const TextStyle(fontSize: 16)),
                  )),

              const SizedBox(height: 30),

              _buildSectionHeader('profile.emergency'.tr),
              if (patient.emergencyContact != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.red.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.contact_phone_rounded,
                          color: Colors.red, size: 30),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              patient.emergencyContact!['name'] ?? '',
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          Text(
                              patient.emergencyContact!['phone'] ?? '',
                              style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Get.toNamed('/history'),
                  icon: const Icon(Icons.history_rounded),
                  label: Text('profile.view_summaries'.tr),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        )),  // closes Expanded + SingleChildScrollView
          ],
        );  // closes outer Column
      }),
    );
  }

  Widget _buildVitalCard(String label, String value, String unit,
      IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(title,
          style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.bold)),
    );
  }
}
