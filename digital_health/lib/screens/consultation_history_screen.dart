import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import 'consultation_detail_screen.dart';

class ConsultationHistoryScreen extends StatelessWidget {
  const ConsultationHistoryScreen({super.key});

  void _editTitle(BuildContext context, HealthController c, int index, String current) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Edit title'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newTitle = ctrl.text.trim();
              if (newTitle.isNotEmpty) {
                c.updateConsultation(index, {'doctorName': newTitle});
              }
              Get.back();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

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
            final title = visit['doctorName'] as String? ?? 'consult.general'.tr;
            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.all(20),
                title: Text(title,
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
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: () => _editTitle(context, healthController, index, title),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded),
                  ],
                ),
                onTap: () => Get.to(() => ConsultationDetailScreen(
                    consultation: visit, index: index)),
              ),
            );
          },
        );
      }),
    );
  }
}
