import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import '../models/questionnaire_model.dart';

class VisitPrepSummaryScreen extends StatelessWidget {
  /// When opened from history [data] is the saved Firestore record.
  /// When opened immediately after submission [data] is the freshly inserted
  /// record (also from Firestore), so the live controller values are the
  /// fallback only when [data] is null.
  final Map<String, dynamic>? data;

  const VisitPrepSummaryScreen({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HealthController>();

    final title = data?['title'] as String? ?? c.visitTitle.value;
    final date = data?['date'] as String? ?? '';
    final summary = data?['summary'] as String? ?? c.visitPrepSummary.value;

    return Scaffold(
      appBar: AppBar(title: Text(title.isNotEmpty ? title : 'Visit preparation')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (date.isNotEmpty) ...[
              Text(date, style: TextStyle(fontSize: 14, color: Colors.grey[500])),
              const SizedBox(height: 20),
            ],

            const Text('What you told us',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            // Route to the appropriate summary renderer based on record format.
            if (data != null && data!.containsKey('selectedCategories'))
              ..._buildNewFormatRows(data!)
            else if (data == null)
              ..._buildLiveRows(c)
            else
              ..._buildLegacyRows(data!),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 20),

            Row(
              children: const [
                Icon(Icons.auto_awesome_rounded, color: Color(0xFF4338CA), size: 20),
                SizedBox(width: 8),
                Text('AI summary',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 14),
            data == null
                ? Obx(() => _summaryText(c.visitPrepSummary.value))
                : _summaryText(summary),

            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.until((route) => route.isFirst),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── New progressive-disclosure format ─────────────────────────────────────

  List<Widget> _buildNewFormatRows(Map<String, dynamic> d) {
    final selectedCats = List<String>.from(d['selectedCategories'] ?? []);
    final selectedSubs = List<String>.from(d['selectedSubItems'] ?? []);
    final notes = Map<String, String>.from(
        (d['itemNotes'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), v.toString())));
    final duration = d['duration'] as String? ?? '';
    final trend = d['symptomTrend'] as String? ?? '';
    final goals = List<String>.from(d['visitGoals'] ?? []);

    return _buildCategoryWidgets(selectedCats, selectedSubs, notes, duration, trend, goals);
  }

  // Live controller state (immediately after submission before navigating away).
  List<Widget> _buildLiveRows(HealthController c) {
    return _buildCategoryWidgets(
      c.selectedCategories.toList(),
      c.selectedSubItems.toList(),
      Map<String, String>.from(c.itemNotes),
      c.duration.value,
      c.symptomTrend.value,
      c.visitGoals.toList(),
    );
  }

  List<Widget> _buildCategoryWidgets(
    List<String> selectedCats,
    List<String> selectedSubs,
    Map<String, String> notes,
    String duration,
    String trend,
    List<String> goals,
  ) {
    final widgets = <Widget>[];

    for (final cat in kVisitTaxonomy) {
      if (!selectedCats.contains(cat.id)) continue;

      final catNote = notes[cat.id] ?? '';
      final answeredSubs = cat.subQuestions
          .where((s) => selectedSubs.contains(s.id) || (notes[s.id]?.isNotEmpty ?? false))
          .toList();

      widgets.add(_buildCategoryBlock(cat.label, catNote, answeredSubs, notes));
    }

    if (duration.isNotEmpty) widgets.add(_buildRow('How long', duration));
    if (trend.isNotEmpty) widgets.add(_buildRow('Getting better or worse', trend));
    if (goals.isNotEmpty) {
      widgets.add(_buildRow('What you want from this visit', goals.join(', ')));
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
                  fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B))),
          if (note.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(note, style: const TextStyle(fontSize: 15, height: 1.4)),
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
                    const Text('• ', style: TextStyle(color: Colors.grey)),
                    Expanded(
                      child: Text(
                        sNote.isNotEmpty ? '${s.label}: $sNote' : s.label,
                        style: const TextStyle(fontSize: 14, height: 1.4),
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

  // ── Legacy flat format (records saved before this update) ─────────────────

  List<Widget> _buildLegacyRows(Map<String, dynamic> d) {
    final reasons = List<String>.from(d['visitReasons'] ?? []);
    final duration = d['duration'] as String? ?? '';
    final trend = d['symptomTrend'] as String? ?? '';
    final goals = List<String>.from(d['visitGoals'] ?? []);

    return [
      if (reasons.isNotEmpty) _buildRow('What brought you in', reasons.join(', ')),
      if (duration.isNotEmpty) _buildRow('How long', duration),
      if (trend.isNotEmpty) _buildRow('Getting better or worse', trend),
      if (goals.isNotEmpty) _buildRow('What you wanted from the visit', goals.join(', ')),
    ];
  }

  // ── Shared helpers ────────────────────────────────────────────────────────

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600])),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 16, height: 1.4)),
        ],
      ),
    );
  }

  Widget _summaryText(String text) =>
      Text(text, style: const TextStyle(fontSize: 16, height: 1.7));
}
