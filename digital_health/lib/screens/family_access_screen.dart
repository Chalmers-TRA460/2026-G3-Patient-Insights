import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import '../models/patient_model.dart';

class FamilyAccessScreen extends StatefulWidget {
  const FamilyAccessScreen({super.key});

  @override
  State<FamilyAccessScreen> createState() => _FamilyAccessScreenState();
}

class _FamilyAccessScreenState extends State<FamilyAccessScreen> {
  @override
  void initState() {
    super.initState();
    Get.find<HealthController>().fetchAccessiblePatients();
  }

  @override
  Widget build(BuildContext context) {
    final HealthController c = Get.find<HealthController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('family.screen_title'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Obx(() {
        if (c.isFetchingAccessible.value) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(),
                const SizedBox(height: 20),
                Text('family.loading'.tr,
                    style: const TextStyle(
                        fontSize: 16, color: Color(0xFF64748B))),
              ],
            ),
          );
        }

        if (c.accessiblePatients.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.family_restroom_rounded,
                      size: 80, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 20),
                  Text('family.empty'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 12),
                  Text('family.empty_desc'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF64748B),
                          height: 1.5)),
                ],
              ),
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Info banner
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFF1D4ED8), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text('family.info'.tr,
                        style: const TextStyle(
                            fontSize: 15,
                            color: Color(0xFF1E3A8A),
                            height: 1.4)),
                  ),
                ],
              ),
            ),

            ...c.accessiblePatients.map((p) => _buildProfileCard(c, p)),
          ],
        );
      }),
    );
  }

  Widget _buildProfileCard(HealthController c, Patient p) {
    final initial =
        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?';
    final isCurrentlyViewing = c.currentViewedPatient.value?.id == p.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: isCurrentlyViewing ? 4 : 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _switchAndReturn(c, p),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: const Color(0xFFEFF6FF),
                child: Text(initial,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1D4ED8))),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.name,
                        style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B))),
                    const SizedBox(height: 4),
                    Text(p.email,
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF64748B))),
                    if (p.age > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Age ${p.age}  ·  ${p.bloodType}',
                        style: const TextStyle(
                            fontSize: 14, color: Color(0xFF64748B)),
                      ),
                    ],
                  ],
                ),
              ),
              if (isCurrentlyViewing)
                const Icon(Icons.check_circle_rounded,
                    color: Color(0xFF0066CC), size: 26)
              else
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Color(0xFF94A3B8), size: 18),
            ],
          ),
        ),
      ),
    );
  }

  void _switchAndReturn(HealthController c, Patient p) {
    c.switchToPatient(p);
    Get.snackbar(
      'family.switched_title'.tr,
      'family.switched_body'.trParams({'name': p.name}),
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
    );
    // Navigate back to the root (home) so the banner is immediately visible.
    Get.until((route) => route.isFirst);
  }
}
