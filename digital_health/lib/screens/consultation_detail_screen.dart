import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConsultationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> consultation;

  const ConsultationDetailScreen({super.key, required this.consultation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('detail.title'.tr)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date & Doctor
            Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  consultation['date'] as String? ??
                      'detail.recent'.tr,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue),
                ),
                const Spacer(),
                Text(
                  consultation['doctorName'] as String? ??
                      'detail.doctor'.tr,
                  style: const TextStyle(
                      fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // AI Summary Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_awesome_rounded,
                          color: Color(0xFF15803D)),
                      const SizedBox(width: 10),
                      Text('detail.ai_summary'.tr,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF15803D))),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    consultation['summary'] as String? ??
                        'detail.no_summary'.tr,
                    style: const TextStyle(
                        fontSize: 18,
                        height: 1.6,
                        color: Color(0xFF166534)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Full Conversation Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded,
                          color: Color(0xFF475569)),
                      const SizedBox(width: 10),
                      Text('detail.transcript'.tr,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155))),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    consultation['transcript'] as String? ??
                        'detail.no_transcript'.tr,
                    style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF475569),
                        height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Pre-visit notes
            if (_hasPreVisitNotes(consultation))
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.assignment_ind_rounded,
                            color: Color(0xFFC2410C)),
                        const SizedBox(width: 10),
                        Text('detail.before'.tr,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFC2410C))),
                      ],
                    ),
                    const SizedBox(height: 15),
                    if (consultation['visitReasons'] != null &&
                        (consultation['visitReasons'] as List)
                            .isNotEmpty) ...[
                      Text('detail.reason'.tr,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9A3412))),
                      const SizedBox(height: 5),
                      Text(
                          List<String>.from(
                                  consultation['visitReasons'])
                              .join(', '),
                          style: const TextStyle(
                              fontSize: 16, height: 1.5)),
                      const SizedBox(height: 12),
                    ],
                    if (consultation['duration'] != null &&
                        (consultation['duration'] as String)
                            .isNotEmpty) ...[
                      Text('detail.duration'.tr,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9A3412))),
                      const SizedBox(height: 5),
                      Text(consultation['duration'] as String,
                          style: const TextStyle(
                              fontSize: 16, height: 1.5)),
                      const SizedBox(height: 12),
                    ],
                    if (consultation['symptomTrend'] != null &&
                        (consultation['symptomTrend'] as String)
                            .isNotEmpty) ...[
                      Text('detail.trend'.tr,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9A3412))),
                      const SizedBox(height: 5),
                      Text(consultation['symptomTrend'] as String,
                          style: const TextStyle(
                              fontSize: 16, height: 1.5)),
                      const SizedBox(height: 12),
                    ],
                    if (consultation['visitGoals'] != null &&
                        (consultation['visitGoals'] as List)
                            .isNotEmpty) ...[
                      Text('detail.wanted'.tr,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF9A3412))),
                      const SizedBox(height: 5),
                      Text(
                          List<String>.from(consultation['visitGoals'])
                              .join(', '),
                          style: const TextStyle(
                              fontSize: 16, height: 1.5)),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  bool _hasPreVisitNotes(Map<String, dynamic> c) {
    return (c['visitReasons'] != null &&
            (c['visitReasons'] as List).isNotEmpty) ||
        (c['duration'] != null &&
            (c['duration'] as String).isNotEmpty) ||
        (c['symptomTrend'] != null &&
            (c['symptomTrend'] as String).isNotEmpty) ||
        (c['visitGoals'] != null &&
            (c['visitGoals'] as List).isNotEmpty);
  }
}
