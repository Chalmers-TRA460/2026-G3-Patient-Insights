import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import '../models/questionnaire_model.dart';
import 'record_consultation_screen.dart';

class VisitPrepSummaryScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const VisitPrepSummaryScreen({super.key, required this.data});

  void _startRecording() {
    Get.find<HealthController>().activateVisitPrep(data);
    Get.to(() => const RecordConsultationScreen());
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '';
    final date = data['date'] as String? ?? '';
    final time = data['time'] as String? ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          title.isNotEmpty ? title : 'summary.title'.tr,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Step 3 badge + appointment info ────────────────────
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF16A34A),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Step 3 of 3',
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text('Ready to go!',
                          style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),

                  if (date.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFBFDBFE)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.event_rounded,
                              size: 16, color: Color(0xFF1D4ED8)),
                          const SizedBox(width: 8),
                          Text(
                            time.isNotEmpty ? '$date · $time' : date,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF1D4ED8),
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // ── Questions header ───────────────────────────────────
                  const Text('Questions to Remember for Your Meeting',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 6),
                  const Text(
                    'Read these out during your visit so you don\'t forget anything.',
                    style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF64748B),
                        height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  ..._buildBodyRows(data),
                ],
              ),
            ),
          ),

          // ── Next Step: Record ──────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.mic_rounded,
                          color: Colors.red.shade600, size: 18),
                    ),
                    const SizedBox(width: 10),
                    const Text('Next Step: Record Your Visit',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B))),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'When you\'re at the doctor, start the recording so your visit can be summarised by AI.',
                  style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                      height: 1.4),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.mic_rounded, size: 20),
                    label: const Text('Start Recording Now',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                    onPressed: _startRecording,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () =>
                        Get.until((route) => route.isFirst),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF64748B),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text('summary.back_home'.tr,
                        style: const TextStyle(fontSize: 14)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Pick a renderer based on which keys the record contains.
  List<Widget> _buildBodyRows(Map<String, dynamic> d) {
    if (d.containsKey('questions')) {
      return _buildNewFormatRows(d);
    }
    if (d.containsKey('selectedCategories')) {
      return _buildCategoryFormatRows(d);
    }
    return _buildLegacyRows(d);
  }

  // ── New simplified format: reason (title) + questions list ─────────────
  List<Widget> _buildNewFormatRows(Map<String, dynamic> d) {
    final title = d['title'] as String? ?? '';
    final questions = List<String>.from(d['questions'] ?? const []);

    return [
      if (title.isNotEmpty) _buildRow('summary.reason'.tr, title),
      const SizedBox(height: 10),
      Text('summary.questions'.tr,
          style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600])),
      const SizedBox(height: 10),
      if (questions.isEmpty)
        Text('summary.no_questions'.tr,
            style: TextStyle(
                fontSize: 18, color: Colors.grey[500], height: 1.4))
      else
        ...List.generate(questions.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 32,
                  height: 32,
                  margin: const EdgeInsets.only(top: 2, right: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0066CC).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0066CC))),
                ),
                Expanded(
                  child: Text(questions[i],
                      style: const TextStyle(fontSize: 20, height: 1.5)),
                ),
              ],
            ),
          );
        }),
    ];
  }

  // ── Older category-based records ───────────────────────────────────────
  List<Widget> _buildCategoryFormatRows(Map<String, dynamic> d) {
    final selectedCats = List<String>.from(d['selectedCategories'] ?? []);
    final selectedSubs = List<String>.from(d['selectedSubItems'] ?? []);
    final notes = Map<String, String>.from(
        (d['itemNotes'] as Map? ?? {})
            .map((k, v) => MapEntry(k.toString(), v.toString())));
    final duration = d['duration'] as String? ?? '';
    final trend = d['symptomTrend'] as String? ?? '';
    final goals = List<String>.from(d['visitGoals'] ?? []);

    final widgets = <Widget>[];

    for (final cat in kVisitTaxonomy) {
      if (!selectedCats.contains(cat.id)) continue;

      final catNote = notes[cat.id] ?? '';
      final answeredSubs = cat.subQuestions
          .where((s) =>
              selectedSubs.contains(s.id) ||
              (notes[s.id]?.isNotEmpty ?? false))
          .toList();

      widgets.add(_buildCategoryBlock(
          'visit.cat.${cat.id}'.tr, catNote, answeredSubs, notes));
    }

    if (duration.isNotEmpty) {
      widgets.add(_buildRow('summary.how_long'.tr, duration));
    }
    if (trend.isNotEmpty) {
      widgets.add(_buildRow('summary.trend'.tr, trend));
    }
    if (goals.isNotEmpty) {
      widgets.add(_buildRow('summary.visit_goal'.tr, goals.join(', ')));
    }

    return widgets;
  }

  Widget _buildCategoryBlock(
    String label,
    String note,
    List<VisitSubQuestion> subs,
    Map<String, String> notes,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B))),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(note,
                style: const TextStyle(fontSize: 15, height: 1.4)),
          ],
          if (subs.isNotEmpty) ...[
            const SizedBox(height: 6),
            ...subs.map((s) {
              final sNote = notes[s.id] ?? '';
              return Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• ',
                        style: TextStyle(color: Colors.grey)),
                    Expanded(
                      child: Text(
                        sNote.isNotEmpty
                            ? '${'visit.sub.${s.id}'.tr}: $sNote'
                            : 'visit.sub.${s.id}'.tr,
                        style: const TextStyle(
                            fontSize: 14, height: 1.4),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ],
      ),
    );
  }

  List<Widget> _buildLegacyRows(Map<String, dynamic> d) {
    final reasons = List<String>.from(d['visitReasons'] ?? []);
    final duration = d['duration'] as String? ?? '';
    final trend = d['symptomTrend'] as String? ?? '';
    final goals = List<String>.from(d['visitGoals'] ?? []);

    return [
      if (reasons.isNotEmpty)
        _buildRow('summary.what_brought'.tr, reasons.join(', ')),
      if (duration.isNotEmpty)
        _buildRow('summary.how_long'.tr, duration),
      if (trend.isNotEmpty) _buildRow('summary.trend'.tr, trend),
      if (goals.isNotEmpty)
        _buildRow('summary.what_wanted'.tr, goals.join(', ')),
    ];
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600])),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(fontSize: 20, height: 1.4)),
        ],
      ),
    );
  }

}
