import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';

class VisitPrepSummaryScreen extends StatelessWidget {
  const VisitPrepSummaryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HealthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('You\'re all set!')),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 56),
            const SizedBox(height: 20),
            const Text('Here\'s what you told us',
                style:
                    TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Saved for your upcoming visit',
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Obx(() => Text(
                      c.visitPrepSummary.value,
                      style: const TextStyle(fontSize: 17, height: 1.7),
                    )),
              ),
            ),
            const SizedBox(height: 24),
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
}
