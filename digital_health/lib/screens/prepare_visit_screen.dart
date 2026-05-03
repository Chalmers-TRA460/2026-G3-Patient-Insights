import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import 'visit_prep_summary_screen.dart';

class PrepareVisitScreen extends StatelessWidget {
  const PrepareVisitScreen({super.key});

  static const _visitReasons = [
    'Pain or discomfort',
    'Fever or chills',
    'Fatigue or low energy',
    'Breathing difficulties',
    'Nausea or digestive issues',
    'Skin changes',
    'Mental health or mood',
    'Follow-up visit',
    'Something else',
  ];

  static const _durations = [
    'Today',
    '2–3 days',
    'About a week',
    'A few weeks',
    'Over a month',
  ];

  static const _trends = [
    'Getting better',
    'About the same',
    'Getting worse',
  ];

  static const _visitGoals = [
    'Find out what\'s wrong',
    'Get treatment or medication',
    'Have test results explained',
    'Review my medications',
    'Get a referral',
    'Just a routine check-up',
  ];

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HealthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Before your appointment')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: 'What brings you in today?',
              subtitle: 'Select all that apply',
              child: Obx(() => _buildFilterChips(
                    options: _visitReasons,
                    selected: c.visitReasons,
                    onTap: c.toggleVisitReason,
                  )),
            ),

            _buildSection(
              title: 'How long have you had this?',
              subtitle: 'Pick the closest one',
              child: Obx(() => _buildChoiceChips(
                    options: _durations,
                    selected: c.duration.value,
                    onTap: (v) => c.duration.value = v,
                  )),
            ),

            _buildSection(
              title: 'Is it getting better or worse?',
              child: Obx(() => _buildChoiceChips(
                    options: _trends,
                    selected: c.symptomTrend.value,
                    onTap: (v) => c.symptomTrend.value = v,
                  )),
            ),

            _buildSection(
              title: 'What do you want from this visit?',
              subtitle: 'Select all that apply',
              child: Obx(() => _buildFilterChips(
                    options: _visitGoals,
                    selected: c.visitGoals,
                    onTap: c.toggleVisitGoal,
                  )),
            ),

            const SizedBox(height: 16),
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: c.isGeneratingSummary.value
                        ? null
                        : () async {
                            await c.submitQuestionnaire();
                            if (c.visitPrepSummary.value.isNotEmpty) {
                              Get.off(() => const VisitPrepSummaryScreen());
                            }
                          },
                    child: c.isGeneratingSummary.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Done — I'm ready!"),
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildFilterChips({
    required List<String> options,
    required RxList<String> selected,
    required void Function(String) onTap,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map((o) => FilterChip(
                label: Text(o),
                selected: selected.contains(o),
                onSelected: (_) => onTap(o),
              ))
          .toList(),
    );
  }

  Widget _buildChoiceChips({
    required List<String> options,
    required String selected,
    required void Function(String) onTap,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map((o) => ChoiceChip(
                label: Text(o),
                selected: selected == o,
                onSelected: (_) => onTap(o),
              ))
          .toList(),
    );
  }
}
