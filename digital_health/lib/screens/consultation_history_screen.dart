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
      appBar: AppBar(title: Text('consult.title'.tr)),
      body: Obx(() {
        if (healthController.consultations.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded,
                    size: 80, color: Colors.grey.withOpacity(0.3)),
                const SizedBox(height: 20),
                Text('consult.empty'.tr,
                    style: const TextStyle(
                        fontSize: 20, color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: healthController.consultations.length,
          itemBuilder: (context, index) {
            final visit = healthController.consultations[index];
            final date = visit['date'] as String? ?? '';
            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.all(20),
                title: Text(
                    visit['doctorName'] as String? ??
                        'consult.general'.tr,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                      date.isNotEmpty
                          ? 'consult.date'.trParams({'date': date})
                          : 'consult.date'.trParams({'date': 'consult.recent'.tr}),
                      style: const TextStyle(fontSize: 16)),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded),
                onTap: () => Get.to(
                    () => ConsultationDetailScreen(consultation: visit)),
              ),
            );
          },
        );
      }),
    );
  }
}
