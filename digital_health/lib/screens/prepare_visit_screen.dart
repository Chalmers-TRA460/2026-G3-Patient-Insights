import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import 'visit_prep_summary_screen.dart';

class PrepareVisitScreen extends StatefulWidget {
  final int? editIndex;
  const PrepareVisitScreen({super.key, this.editIndex});

  @override
  State<PrepareVisitScreen> createState() => _PrepareVisitScreenState();
}

class _PrepareVisitScreenState extends State<PrepareVisitScreen> {
  late final HealthController _c;
  final _titleController = TextEditingController();

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
  void initState() {
    super.initState();
    _c = Get.find<HealthController>();
    if (widget.editIndex != null) {
      final prep = _c.visitPreps[widget.editIndex!];
      _c.visitTitle.value = prep['title'] ?? '';
      _c.visitReasons.value = List<String>.from(prep['visitReasons'] ?? []);
      _c.duration.value = prep['duration'] ?? '';
      _c.symptomTrend.value = prep['symptomTrend'] ?? '';
      _c.visitGoals.value = List<String>.from(prep['visitGoals'] ?? []);
      _titleController.text = _c.visitTitle.value;
    } else {
      _c.clearVisitNotes();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editIndex != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit preparation' : 'Before your appointment'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title ──
            _buildSection(
              title: 'Title',
              subtitle: 'Give this preparation a name so you can find it easily',
              child: TextField(
                controller: _titleController,
                onChanged: (v) => _c.visitTitle.value = v,
                decoration: InputDecoration(
                  hintText: 'e.g. GP visit – back pain',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
            ),

            _buildSection(
              title: 'What brings you in today?',
              subtitle: 'Select all that apply',
              child: Obx(() => _buildFilterChips(
                    options: _visitReasons,
                    selected: _c.visitReasons,
                    onTap: _c.toggleVisitReason,
                  )),
            ),

            _buildSection(
              title: 'How long have you had this?',
              subtitle: 'Pick the closest one',
              child: Obx(() => _buildChoiceChips(
                    options: _durations,
                    selected: _c.duration.value,
                    onTap: (v) => _c.duration.value = v,
                  )),
            ),

            _buildSection(
              title: 'Is it getting better or worse?',
              child: Obx(() => _buildChoiceChips(
                    options: _trends,
                    selected: _c.symptomTrend.value,
                    onTap: (v) => _c.symptomTrend.value = v,
                  )),
            ),

            _buildSection(
              title: 'What do you want from this visit?',
              subtitle: 'Select all that apply',
              child: Obx(() => _buildFilterChips(
                    options: _visitGoals,
                    selected: _c.visitGoals,
                    onTap: _c.toggleVisitGoal,
                  )),
            ),

            const SizedBox(height: 16),
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _c.isGeneratingSummary.value
                        ? null
                        : () async {
                            await _c.submitQuestionnaire(
                                editIndex: widget.editIndex);
                            if (_c.visitPrepSummary.value.isNotEmpty) {
                              final idx = widget.editIndex ?? 0;
                              Get.off(() => VisitPrepSummaryScreen(
                                  data: _c.visitPreps[idx]));
                            }
                          },
                    child: _c.isGeneratingSummary.value
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'Save changes' : "Done — I'm ready!"),
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
