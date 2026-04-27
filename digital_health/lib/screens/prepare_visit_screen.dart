import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';

class PrepareVisitScreen extends StatelessWidget {
  const PrepareVisitScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HealthController controller = Get.find<HealthController>();
    final TextEditingController symptomController = TextEditingController();
    final TextEditingController questionController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('Prepare for Visit')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('What are you feeling?', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: symptomController,
              decoration: InputDecoration(
                hintText: 'Enter a symptom...',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    controller.addSymptom(symptomController.text);
                    symptomController.clear();
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Obx(() => Wrap(
              spacing: 8,
              children: controller.symptoms.map((s) => Chip(
                label: Text(s),
                onDeleted: () => controller.removeSymptom(s),
              )).toList(),
            )),

            const SizedBox(height: 30),
            const Text('Questions for Doctor', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TextField(
              controller: questionController,
              decoration: InputDecoration(
                hintText: 'What do you want to ask?',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () {
                    controller.addQuestion(questionController.text);
                    questionController.clear();
                  },
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 10),
            Obx(() => Column(
              children: controller.questionsForDoctor.map((q) => ListTile(
                title: Text(q, style: const TextStyle(fontSize: 18)),
                trailing: IconButton(icon: const Icon(Icons.remove_circle_outline), onPressed: () => controller.removeQuestion(q)),
              )).toList(),
            )),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                child: const Text('Done - I\'m Ready!'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
