import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import '../models/medical_entry_model.dart';
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

              // Height & Weight
              Row(
                children: [
                  Expanded(
                    child: _buildMeasurementCard(
                      context,
                      'edit.height'.tr,
                      patient.height > 0
                          ? patient.height.toStringAsFixed(0)
                          : '—',
                      'cm',
                      Icons.height_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMeasurementCard(
                      context,
                      'edit.weight'.tr,
                      patient.weight > 0
                          ? patient.weight.toStringAsFixed(0)
                          : '—',
                      'kg',
                      Icons.monitor_weight_rounded,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

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

              _buildMedicalDisclaimer(),

              const SizedBox(height: 20),

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

              _buildMedicalChipSection(
                  'edit.medical.section.allergies'.tr, patient.allergies),
              _buildMedicalChipSection(
                  'edit.medical.section.current_diagnoses'.tr,
                  patient.currentDiagnoses),
              _buildMedicalChipSection(
                  'edit.medical.section.past_illnesses'.tr,
                  patient.pastIllnesses),
              _buildMedicalChipSection(
                  'edit.medical.section.implants'.tr, patient.implants),
              _buildMedicalChipSection(
                  'edit.medical.section.vaccinations'.tr,
                  patient.vaccinations),

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

  // Rounded card matching the BMI tile style, used to show Height / Weight
  // as a two-up row above BMI.
  Widget _buildMeasurementCard(BuildContext context, String label,
      String value, String unit, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, size: 32, color: Theme.of(context).primaryColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                    children: [
                      TextSpan(text: value),
                      TextSpan(
                        text: value == '—' ? '' : ' $unit',
                        style: const TextStyle(
                            fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
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

  // Renders a chip-Wrap section matching the style used for Medical
  // Conditions above. Hidden entirely when the category is empty so users
  // who haven't filled in (e.g.) implants don't see a stub header.
  Widget _buildMedicalChipSection(String title, List<MedicalEntry> entries) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(title),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: entries
                .map((e) => Chip(
                      label: Text(_chipLabel(e),
                          style: const TextStyle(fontSize: 16)),
                      backgroundColor: Colors.blue.withOpacity(0.05),
                      side: BorderSide(
                          color: Colors.blue.withOpacity(0.2)),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  String _chipLabel(MedicalEntry e) {
    if (e.occurredOn == null) return e.displayText;
    final d = e.occurredOn!;
    final iso =
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return '${e.displayText} · $iso';
  }

  // Mirrors the yellow self-reported disclaimer shown above the same
  // categories on the edit screen, so viewers know this data is patient-
  // reported and not clinically verified.
  Widget _buildMedicalDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: const Color(0xFFE6C200)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFF8A6D00), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'edit.medical.disclaimer'.tr,
              style: const TextStyle(
                  fontSize: 13.5,
                  color: Color(0xFF5C4A00),
                  height: 1.35),
            ),
          ),
        ],
      ),
    );
  }
}
