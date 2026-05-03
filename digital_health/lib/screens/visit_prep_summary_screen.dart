import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';

class VisitPrepSummaryScreen extends StatelessWidget {
  /// When opened from history, [data] holds the saved Firestore record.
  /// When opened immediately after submission, [data] is null and the
  /// screen reads live values from the controller.
  final Map<String, dynamic>? data;

  const VisitPrepSummaryScreen({super.key, this.data});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HealthController>();

    final title = data?['title'] as String? ?? c.visitTitle.value;
    final date = data?['date'] as String? ?? '';
    final reasons = data != null
        ? List<String>.from(data!['visitReasons'] ?? [])
        : c.visitReasons;
    final duration = data?['duration'] as String? ?? c.duration.value;
    final trend = data?['symptomTrend'] as String? ?? c.symptomTrend.value;
    final goals = data != null
        ? List<String>.from(data!['visitGoals'] ?? [])
        : c.visitGoals;
    final summary = data?['summary'] as String? ?? c.visitPrepSummary.value;

    return Scaffold(
      appBar: AppBar(
          title: Text(title.isNotEmpty ? title : 'Visit preparation')),
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

            // ── Answers ──
            const Text('What you told us',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),

            if (reasons.isNotEmpty)
              _buildRow('What brings you in', reasons.join(', ')),
            if (duration.isNotEmpty)
              _buildRow('How long', duration),
            if (trend.isNotEmpty)
              _buildRow('Getting better or worse', trend),
            if (goals.isNotEmpty)
              _buildRow('What you want from this visit', goals.join(', ')),

            const SizedBox(height: 28),
            const Divider(),
            const SizedBox(height: 20),

            // ── AI Summary ──
            Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: Color(0xFF4338CA), size: 20),
                const SizedBox(width: 8),
                const Text('AI summary',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
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

  Widget _summaryText(String text) {
    return Text(text,
        style: const TextStyle(fontSize: 16, height: 1.7));
  }
}
