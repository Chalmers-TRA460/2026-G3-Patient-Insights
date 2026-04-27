import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import 'nutrition_screen.dart';
import 'prepare_visit_screen.dart';
import 'record_consultation_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HealthController controller = Get.find<HealthController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Obx(() {
          final name = controller.patient.value?.name ?? 'there';
          final firstName = name.split(' ').first;
          return Text('Hello, $firstName 👋',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 24));
        }),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_none_rounded, size: 28),
              onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Medical Record Completion Card ──
            Obx(() {
              double pct = controller.completionPercentage;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0066CC), Color(0xFF004D99)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0066CC).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Medical Record Status',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.white),
                        minHeight: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${pct.toInt()}% Complete',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () => Get.toNamed('/edit-profile'),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.white),
                          child: const Text('Update →',
                              style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                    if (controller.missingFields.isNotEmpty)
                      Text(
                        'Missing: ${controller.missingFields.take(2).join(', ')}...',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 30),

            // ── AI Health Chat ──
            const Text('Your Health Assistant',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Get.to(() => const NutritionScreen()),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDBEAFE),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(Icons.auto_awesome_rounded,
                          color: Color(0xFF1D4ED8), size: 34),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('AI Health Chat',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A))),
                          SizedBox(height: 4),
                          Text(
                              'Ask about your medications, vitals, or symptoms.',
                              style: TextStyle(
                                  fontSize: 14, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF94A3B8), size: 18),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            // ── Quick Actions ──
            const Text('Quick Actions',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 14),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _actionCard(
                  Icons.medical_services_rounded,
                  'Prepare\nVisit',
                  const Color(0xFFEEF2FF),
                  const Color(0xFF4338CA),
                  onTap: () => Get.to(() => const PrepareVisitScreen()),
                ),
                _actionCard(
                  Icons.mic_rounded,
                  'Record\nLive Visit',
                  const Color(0xFFFEF2F2),
                  const Color(0xFFDC2626),
                  onTap: () => Get.to(() => const RecordConsultationScreen()),
                ),
                _actionCard(
                  Icons.history_rounded,
                  'Visit\nSummaries',
                  const Color(0xFFF0FDF4),
                  const Color(0xFF15803D),
                  onTap: () => Get.toNamed('/history'),
                ),
                _actionCard(
                  Icons.assignment_ind_rounded,
                  'My Health\nProfile',
                  const Color(0xFFFFF7ED),
                  const Color(0xFFC2410C),
                  onTap: () => Get.toNamed('/profile'),
                ),
                _actionCard(
                  Icons.medication_rounded,
                  'Update\nRecord',
                  const Color(0xFFFFFBEB),
                  const Color(0xFFB45309),
                  onTap: () => Get.toNamed('/edit-profile'),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _actionCard(IconData icon, String title, Color bg, Color fg,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 42, color: fg),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: fg.withOpacity(0.85),
                  height: 1.3),
            ),
          ],
        ),
      ),
    );
  }
}
