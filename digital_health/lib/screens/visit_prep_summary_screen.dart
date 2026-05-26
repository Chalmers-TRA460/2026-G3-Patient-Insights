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

    return Scaffold(
      appBar: AppBar(
          title: Text(title.isNotEmpty ? title : 'summary.title'.tr)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (date.isNotEmpty) ...[
              Text(date,
                  style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              const SizedBox(height: 20),
            ],

            Text('summary.what_told'.tr,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            ..._buildBodyRows(data),

            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.mic_rounded),
                label: Text('summary.start_recording'.tr,
                    style: const TextStyle(fontSize: 17)),
                onPressed: _startRecording,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Get.until((route) => route.isFirst),
                child: Text('summary.back_home'.tr),
              ),
            ),
          ],
        ),
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
      const SizedBox(height: 6),
      Text('summary.questions'.tr,
          style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600])),
      const SizedBox(height: 6),
      if (questions.isEmpty)
        Text('summary.no_questions'.tr,
            style: TextStyle(
                fontSize: 15, color: Colors.grey[500], height: 1.4))
      else
        ...List.generate(questions.length, (i) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24,
                  child: Text('${i + 1}.',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                Expanded(
                  child: Text(questions[i],
                      style:
                          const TextStyle(fontSize: 16, height: 1.4)),
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
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontSize: 16, height: 1.4)),
        ],
      ),
    );
  }

}
