import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import '../models/quiz_question_model.dart';
import 'quiz_screen.dart';

class QuizHistoryScreen extends StatelessWidget {
  const QuizHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HealthController c = Get.find<HealthController>();

    return Scaffold(
      appBar: AppBar(title: Text('home.action.quiz'.tr.replaceAll('\n', ' '))),
      body: Obx(() {
        final quizVisits = c.consultations
            .asMap()
            .entries
            .where((e) {
              final quiz = e.value['quiz'] as List?;
              return quiz != null && quiz.isNotEmpty;
            })
            .toList();

        if (quizVisits.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.quiz_rounded,
                      size: 80, color: Colors.grey.withOpacity(0.3)),
                  const SizedBox(height: 20),
                  Text('quiz.history_empty'.tr,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E293B))),
                  const SizedBox(height: 10),
                  Text('quiz.history_empty_desc'.tr,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF64748B),
                          height: 1.5)),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(15),
          itemCount: quizVisits.length,
          itemBuilder: (context, i) {
            final index = quizVisits[i].key;
            final visit = quizVisits[i].value;
            final date = visit['date'] as String? ?? '';
            final title =
                visit['doctorName'] as String? ?? 'consult.general'.tr;
            final raw = visit['quiz'] as List;
            final count = raw.length;

            return Card(
              margin: const EdgeInsets.only(bottom: 15),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              elevation: 2,
              child: ListTile(
                contentPadding: const EdgeInsets.all(20),
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.quiz_rounded,
                      color: Colors.amber.shade800, size: 26),
                ),
                title: Text(
                  title,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    Text(
                      date.isNotEmpty
                          ? 'consult.date'.trParams({'date': date})
                          : 'consult.date'
                              .trParams({'date': 'consult.recent'.tr}),
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'quiz.n_questions'
                            .trParams({'count': '$count'}),
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                    size: 18, color: Color(0xFF94A3B8)),
                onTap: () => _openQuiz(raw),
                isThreeLine: true,
              ),
            );
          },
        );
      }),
    );
  }

  void _openQuiz(List raw) {
    final questions = raw
        .whereType<Map<String, dynamic>>()
        .map(QuizQuestion.fromJson)
        .where((q) => q.question.isNotEmpty && q.options.length >= 2)
        .toList();
    if (questions.isNotEmpty) {
      Get.to(() => QuizScreen(questions: questions));
    }
  }
}
