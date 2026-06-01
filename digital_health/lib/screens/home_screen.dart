import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import '../controllers/settings_controller.dart';
import '../widgets/accessible_audio_card.dart';
import 'ai_chat_screen.dart';
import 'appointment_setup_screen.dart';
import 'record_consultation_screen.dart';
import 'visit_prep_history_screen.dart';
import 'quiz_history_screen.dart';
import '../widgets/viewing_banner.dart';
import 'visit_prep_summary_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final HealthController controller;
  late final SettingsController settings;

  @override
  void initState() {
    super.initState();
    controller = Get.find<HealthController>();
    settings = Get.find<SettingsController>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowPrepReminder();
    });
  }

  void _maybeShowPrepReminder() {
    final activePreps = controller.activeVisitPrepsIndexed;
    if (activePreps.isEmpty) return;

    final prep = activePreps.first.value;
    final reason = (prep['title'] as String? ?? '').trim();
    final date = (prep['date'] as String? ?? '').trim();
    final time = (prep['time'] as String? ?? '').trim();
    final questions = List<String>.from(prep['questions'] ?? const [])
        .map((q) => q.trim())
        .where((q) => q.isNotEmpty)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.65,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
                decoration: const BoxDecoration(
                  border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_active_rounded,
                          color: Color(0xFFEA580C), size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'You have a visit prepared!',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B)),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Here\'s a reminder of what you planned',
                            style: TextStyle(
                                fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: Color(0xFF94A3B8), size: 22),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date/time chip
                      if (date.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0FDF4),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF86EFAC)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.calendar_today_rounded,
                                  size: 15, color: Color(0xFF16A34A)),
                              const SizedBox(width: 8),
                              Text(
                                time.isNotEmpty ? '$date  ·  $time' : date,
                                style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF15803D)),
                              ),
                            ],
                          ),
                        ),

                      if (date.isNotEmpty) const SizedBox(height: 18),

                      // Reason
                      if (reason.isNotEmpty) ...[
                        const Text('REASON FOR VISIT',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF94A3B8),
                                letterSpacing: 0.8)),
                        const SizedBox(height: 6),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Text(reason,
                              style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: Color(0xFF334155))),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Questions
                      if (questions.isNotEmpty) ...[
                        Row(
                          children: [
                            const Text('QUESTIONS TO ASK',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF94A3B8),
                                    letterSpacing: 0.8)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1D4ED8),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text('${questions.length}',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ...questions.asMap().entries.map((e) => Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1D4ED8),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Center(
                                      child: Text('${e.key + 1}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(e.value,
                                        style: const TextStyle(
                                            fontSize: 15,
                                            height: 1.45,
                                            color: Color(0xFF334155))),
                                  ),
                                ],
                              ),
                            )),
                      ],

                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),

              // Action buttons
              Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.mic_rounded, size: 20),
                        label: const Text('Start Recording Now',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          controller.activateVisitPrep(prep);
                          Get.to(() => const RecordConsultationScreen());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Remind me later',
                            style: TextStyle(
                                fontSize: 15, color: Color(0xFF64748B))),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openHealthProfile() {
    if (!controller.canAccessHealthProfile) {
      controller.promptProfileUpdate();
      return;
    }
    Get.toNamed('/profile');
  }

  @override
  Widget build(BuildContext context) {
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
            // ── Upcoming Visit Reminder ──
            Obx(() {
              if (controller.isViewingOther) return const SizedBox.shrink();

              final now = DateTime.now();
              final today = DateTime(now.year, now.month, now.day);

              // Find future visit preps that are not archived
              final upcoming = controller.visitPreps.where((prep) {
                if (prep['archived'] == true) return false;
                final dateStr = prep['date'] as String? ?? '';
                if (dateStr.isEmpty) return false;
                final parsed = DateTime.tryParse(dateStr);
                if (parsed == null) return false;
                final prepDay = DateTime(parsed.year, parsed.month, parsed.day);
                return !prepDay.isBefore(today);
              }).toList();

              if (upcoming.isEmpty) return const SizedBox.shrink();

              // Sort by date ascending to get the nearest upcoming visit
              upcoming.sort((a, b) {
                final da = DateTime.tryParse(a['date'] ?? '') ?? DateTime(9999);
                final db = DateTime.tryParse(b['date'] ?? '') ?? DateTime(9999);
                return da.compareTo(db);
              });
              final nearest = upcoming.first;
              final nearestDate = DateTime.tryParse(nearest['date'] ?? '')!;
              final nearestDay = DateTime(nearestDate.year, nearestDate.month, nearestDate.day);
              final daysUntil = nearestDay.difference(today).inDays;
              final title = nearest['title'] as String? ?? '';
              final time = nearest['time'] as String? ?? '';

              String countdown;
              if (daysUntil == 0) {
                countdown = 'home.upcoming.today'.tr;
              } else if (daysUntil == 1) {
                countdown = 'home.upcoming.tomorrow'.tr;
              } else {
                countdown = 'home.upcoming.in_days'.trParams({'days': daysUntil.toString()});
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: GestureDetector(
                  onTap: () => Get.to(() => VisitPrepSummaryScreen(data: nearest)),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF97316), Color(0xFFFB923C)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF97316).withValues(alpha: 0.3),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.event_rounded,
                              color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'home.upcoming.title'.tr,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white70,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                title.isNotEmpty ? title : nearest['date'] as String? ?? '',
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    time.isNotEmpty
                                        ? '${nearest['date']} · $time'
                                        : nearest['date'] as String? ?? '',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      countdown,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded,
                            color: Colors.white70, size: 24),
                      ],
                    ),
                  ),
                ),
              );
            }),

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
                        () => Get.to(() => const AppointmentSetupScreen()),
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
                        () => _openHealthProfile(),
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
              final activePreps = controller.activeVisitPrepsIndexed;
              final totalCount = controller.visitPreps.length;

              Widget sectionHeader() => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Visit Preparations',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B)),
                  ),
                  if (totalCount > 0)
                    TextButton(
                      onPressed: () =>
                          Get.to(() => const VisitPrepHistoryScreen()),
                      child: Text('home.see_all'.trParams(
                          {'count': totalCount.toString()})),
                    ),
                ],
              );

              // ── Empty state ──────────────────────────────────────────────
              if (activePreps.isEmpty) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionHeader(),
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 32, horizontal: 20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            style: BorderStyle.solid),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(Icons.event_busy_rounded,
                                color: Color(0xFF93C5FD), size: 28),
                          ),
                          const SizedBox(height: 14),
                          const Text(
                            'No active preparations',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF64748B)),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Prepare questions before your next visit',
                            style: TextStyle(
                                fontSize: 13.5,
                                color: Color(0xFF94A3B8),
                                height: 1.4),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Prepare a visit'),
                            onPressed: () => Get.to(
                                () => const AppointmentSetupScreen()),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0066CC),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                  ],
                );
              }

              // ── Active prep card ─────────────────────────────────────────
              final latest = activePreps.first.value;
              final List<String> reasons;
              if (latest.containsKey('questions')) {
                reasons = List<String>.from(latest['questions'] ?? const []);
              } else if (latest.containsKey('selectedCategories')) {
                final ids = List<String>.from(
                    latest['selectedCategories'] ?? const []);
                reasons = ids.map((id) => 'visit.cat.$id'.tr).toList();
              } else {
                reasons =
                    List<String>.from(latest['visitReasons'] ?? const []);
              }
              final title = latest['title'] as String? ?? '';
              final date = latest['date'] as String? ?? '';
              final time = latest['time'] as String? ?? '';
              final summary = latest['summary'] as String? ?? '';

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  sectionHeader(),
                  const SizedBox(height: 14),
                  GestureDetector(
                    onTap: () => Get.to(() => const VisitPrepHistoryScreen()),
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
                              Expanded(
                                child: Text(
                                  time.isNotEmpty
                                      ? '$date  ·  $time'
                                      : date,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6366F1)),
                                ),
                              ),
                              // "Upcoming" badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.circle,
                                        size: 7,
                                        color: Color(0xFF16A34A)),
                                    SizedBox(width: 5),
                                    Text('Upcoming',
                                        style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF16A34A))),
                                  ],
                                ),
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
                                        padding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 10,
                                                vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFE0E7FF),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(r,
                                            style: const TextStyle(
                                                fontSize: 12,
                                                color:
                                                    Color(0xFF4338CA)),
                                            maxLines: 1,
                                            overflow:
                                                TextOverflow.ellipsis),
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
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text('home.tap_see_all'.tr,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF6366F1),
                                        fontWeight: FontWeight.w500)),
                              ),
                              GestureDetector(
                                onTap: () {
                                  controller.activateVisitPrep(latest);
                                  Get.to(() =>
                                      const RecordConsultationScreen());
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDC2626),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.mic_rounded,
                                          size: 15, color: Colors.white),
                                      SizedBox(width: 6),
                                      Text('Record now',
                                          style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.bold)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
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
