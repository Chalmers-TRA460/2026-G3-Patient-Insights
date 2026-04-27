import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import 'consultation_detail_screen.dart';

class ConsultationHistoryScreen extends StatelessWidget {
  const ConsultationHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HealthController healthController = Get.find<HealthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Past Visits')),
      body: Obx(() {
        if (healthController.consultations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 80, color: Colors.grey.withOpacity(0.3)),
                const SizedBox(height: 20),
                const Text('No visit history yet.', style: TextStyle(fontSize: 20, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: healthController.consultations.length,
          itemBuilder: (context, index) {
            final visit = healthController.consultations[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.all(20),
                title: Text(visit['doctorName'] ?? 'General Consultation', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text('Date: ${visit['date'] ?? 'Recent'}', style: const TextStyle(fontSize: 16)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded),
                onTap: () => Get.to(() => ConsultationDetailScreen(consultation: visit)),
              ),
            );
          },
        );
      }),
    );
  }
}
