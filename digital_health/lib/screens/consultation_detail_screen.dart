import 'package:flutter/material.dart';

class ConsultationDetailScreen extends StatelessWidget {
  final Map<String, dynamic> consultation;

  const ConsultationDetailScreen({super.key, required this.consultation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visit Summary')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date & Doctor
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Text(
                  consultation['date'] ?? 'Recent Visit',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
                ),
                const Spacer(),
                Text(
                  consultation['doctorName'] ?? 'Doctor Visit',
                  style: const TextStyle(fontSize: 16, color: Colors.grey),
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
                  const Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: Color(0xFF15803D)),
                      SizedBox(width: 10),
                      Text('AI Generated Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF15803D))),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    consultation['summary'] ?? 'No summary available for this visit.',
                    style: const TextStyle(fontSize: 18, height: 1.6, color: Color(0xFF166534)),
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
                  const Row(
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF475569)),
                      SizedBox(width: 10),
                      Text('Full Conversation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF334155))),
                    ],
                  ),
                  const SizedBox(height: 15),
                  Text(
                    consultation['transcript'] ?? 'Transcript not available.',
                    style: const TextStyle(fontSize: 16, color: Color(0xFF475569), height: 1.6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),

            // Patient Concerns
            if ((consultation['symptoms'] != null && (consultation['symptoms'] as List).isNotEmpty) ||
                (consultation['questions'] != null && (consultation['questions'] as List).isNotEmpty))
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
                    const Row(
                      children: [
                        Icon(Icons.assignment_ind_rounded, color: Color(0xFFC2410C)),
                        SizedBox(width: 10),
                        Text('Patient Concerns', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFFC2410C))),
                      ],
                    ),
                    const SizedBox(height: 15),
                    if (consultation['symptoms'] != null && (consultation['symptoms'] as List).isNotEmpty) ...[
                      const Text('Symptoms Reported:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF9A3412))),
                      const SizedBox(height: 5),
                      Text(List<String>.from(consultation['symptoms']).join(', '), style: const TextStyle(fontSize: 16, height: 1.5)),
                      const SizedBox(height: 12),
                    ],
                    if (consultation['questions'] != null && (consultation['questions'] as List).isNotEmpty) ...[
                      const Text('Questions Asked:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF9A3412))),
                      const SizedBox(height: 5),
                      Text(List<String>.from(consultation['questions']).join(', '), style: const TextStyle(fontSize: 16, height: 1.5)),
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

  Widget _buildInfoSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 5),
          Text(content, style: const TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}
