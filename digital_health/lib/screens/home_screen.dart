import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import '../controllers/settings_controller.dart';
import '../widgets/accessible_audio_card.dart';
import 'prepare_visit_screen.dart';
import 'record_consultation_screen.dart';
import 'visit_prep_history_screen.dart';
import 'quiz_history_screen.dart';
import '../widgets/viewing_banner.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _openHealthProfile(HealthController controller) {
    if (!controller.canAccessHealthProfile) {
      controller.promptProfileUpdate();
      return;
    }
    Get.toNamed('/profile');
  }

  @override
  Widget build(BuildContext context) {
    final HealthController controller = Get.find<HealthController>();
    final SettingsController settings = Get.find<SettingsController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Obx(() {
          final name = controller.effectivePatient?.name ?? 'there';
          final firstName = name.split(' ').first;
          return Text('home.greeting'.trParams({'name': firstName}),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24));
        }),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_none_rounded, size: 28),
              onPressed: () {}),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          const ViewingBanner(),
          Expanded(child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Quick Actions ──
            Obx(() {
              final accessible = settings.isAccessibilityMode.value;
              final labelSize = accessible ? 22.0 : 15.0;
              final iconSize = accessible ? 56.0 : 42.0;

              Widget card(IconData icon, String translationKey, Color bg,
                  Color fg, VoidCallback onTap) {
                final label = translationKey.tr;
                final inner = Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: iconSize, color: fg),
                      const SizedBox(height: 12),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: labelSize,
                                fontWeight: FontWeight.bold,
                                color: fg.withOpacity(0.85),
                                height: 1.3),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
                return AccessibleAudioCard(
                  speakText: label,
                  onTap: onTap,
                  child: inner,
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('home.quick_actions'.tr,
                      style: TextStyle(
                          fontSize: accessible ? 30.0 : 22.0,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1E293B))),
                  const SizedBox(height: 14),
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: accessible ? 1.0 : 1.1,
                    children: [
                      card(
                        Icons.edit_note_rounded,
                        'home.action.prepare',
                        Colors.blue.shade50,
                        Colors.blue.shade800,
                        () => controller.visitPreps.isNotEmpty
                            ? Get.to(() => const VisitPrepHistoryScreen())
                            : Get.to(() => const PrepareVisitScreen()),
                      ),
                      card(
                        Icons.mic_rounded,
                        'home.action.record',
                        Colors.red.shade50,
                        Colors.red.shade700,
                        () => Get.to(() => const RecordConsultationScreen()),
                      ),
                      card(
                        Icons.history_rounded,
                        'home.action.summaries',
                        Colors.teal.shade50,
                        Colors.teal.shade800,
                        () => Get.toNamed('/history'),
                      ),
                      card(
                        Icons.assignment_ind_rounded,
                        'home.action.profile',
                        Colors.deepPurple.shade50,
                        Colors.deepPurple.shade700,
                        () => _openHealthProfile(controller),
                      ),
                      card(
                        Icons.quiz_rounded,
                        'home.action.quiz',
                        Colors.amber.shade50,
                        Colors.amber.shade800,
                        () => Get.to(() => const QuizHistoryScreen()),
                      ),
                    ],
                  ),
                ],
              );
            }),

            const SizedBox(height: 30),

            // ── Visit Preparations ──
            Obx(() {
              if (controller.visitPreps.isEmpty) {
                return const SizedBox.shrink();
              }
              final latest = controller.visitPreps.first;
              final List<String> reasons;
              if (latest.containsKey('questions')) {
                reasons =
                    List<String>.from(latest['questions'] ?? const []);
              } else if (latest.containsKey('selectedCategories')) {
                final ids = List<String>.from(
                    latest['selectedCategories'] ?? const []);
                reasons = ids.map((id) => 'visit.cat.$id'.tr).toList();
              } else {
                reasons =
                    List<String>.from(latest['visitReasons'] ?? const []);
              }
              final title = latest['title'] as String? ?? '';
              final summary = latest['summary'] as String? ?? '';
              final count = controller.visitPreps.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('home.visit_preps'.tr,
                            style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B))),
                      ),
                      TextButton(
                        onPressed: () =>
                            Get.to(() => const VisitPrepHistoryScreen()),
                        child: Text('home.see_all'.trParams({'count': count.toString()})),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () =>
                        Get.to(() => const VisitPrepHistoryScreen()),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFC7D2FE)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.event_note_rounded,
                                  color: Color(0xFF4338CA), size: 22),
                              const SizedBox(width: 8),
                              Text(
                                latest['date'] as String? ?? '',
                                style: const TextStyle(
                                    fontSize: 13, color: Color(0xFF6366F1)),
                              ),
                            ],
                          ),
                          if (title.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              title,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E293B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          if (reasons.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: reasons
                                  .map((r) => Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0E7FF),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          r,
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF4338CA)),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ))
                                  .toList(),
                            ),
                          ],
                          if (summary.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              summary,
                              style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF3730A3),
                                  height: 1.5),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: 8),
                          Text('home.tap_see_all'.tr,
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF6366F1),
                                  fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              );
            }),

            // ── Health Profile Completion Card ──
            Obx(() {
              double pct = controller.completionPercentage;
              if (pct >= 100) return const SizedBox.shrink();
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
                    Text('home.medical_status'.tr,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: pct / 100,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'home.complete'.trParams({'pct': pct.toInt().toString()}),
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Get.toNamed('/edit-profile'),
                          style: TextButton.styleFrom(
                              foregroundColor: Colors.white),
                          child: Text('home.update'.tr,
                              style: const TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                    if (controller.missingFields.isNotEmpty)
                      Text(
                        'home.missing'.trParams(
                            {'fields': controller.missingFields.take(2).join(', ')}),
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                  ],
                ),
              );
            }),

            Obx(() => controller.completionPercentage >= 100
                ? const SizedBox.shrink()
                : const SizedBox(height: 30)),
          ],
        ),
      )),  // closes Expanded + SingleChildScrollView
        ],
      ),   // closes outer Column
    );
  }

}
