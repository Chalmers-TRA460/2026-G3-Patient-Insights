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
            Container(
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
            const SizedBox(height: 30),
            const Text('Patient Concerns', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            if (consultation['symptoms'] != null)
              _buildInfoSection('Symptoms Reported', List<String>.from(consultation['symptoms']).join(', ')),
            if (consultation['questions'] != null)
              _buildInfoSection('Questions Asked', List<String>.from(consultation['questions']).join(', ')),
            
            const SizedBox(height: 30),
            const Text('Full Transcript', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            Text(
              consultation['transcript'] ?? 'Transcript not available.',
              style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
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
