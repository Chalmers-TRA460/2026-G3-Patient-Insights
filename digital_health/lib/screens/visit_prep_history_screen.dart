import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import 'visit_prep_summary_screen.dart';
import 'prepare_visit_screen.dart';

class VisitPrepHistoryScreen extends StatelessWidget {
  const VisitPrepHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HealthController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Visit preparations')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const PrepareVisitScreen()),
        icon: const Icon(Icons.add),
        label: const Text('New preparation'),
      ),
      body: Obx(() {
        if (c.visitPreps.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.event_note_rounded,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text('No visit preparations yet',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'Fill in the questionnaire before your next appointment.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: c.visitPreps.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final prep = c.visitPreps[i];
            final title = prep['title'] as String? ?? '';
            final reasons = List<String>.from(prep['visitReasons'] ?? []);
            final date = prep['date'] as String? ?? '';
            final summary = prep['summary'] as String? ?? '';

            return GestureDetector(
              onTap: () =>
                  Get.to(() => VisitPrepSummaryScreen(data: prep)),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (title.isNotEmpty)
                                Text(title,
                                    style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                              Text(date,
                                  style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[500])),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 20, color: Color(0xFF64748B)),
                          tooltip: 'Edit',
                          onPressed: () => Get.to(
                              () => PrepareVisitScreen(editIndex: i)),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded,
                              size: 20, color: Colors.red[400]),
                          tooltip: 'Delete',
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete preparation?'),
                              content: Text(title.isNotEmpty
                                  ? 'Delete "$title"?'
                                  : 'Delete this visit preparation?'),
                              actions: [
                                TextButton(
                                    onPressed: () => Get.back(),
                                    child: const Text('Cancel')),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  onPressed: () {
                                    Get.back();
                                    c.deleteVisitPrep(i);
                                  },
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                      if (reasons.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: reasons
                              .map((r) => Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEEF2FF),
                                      borderRadius:
                                          BorderRadius.circular(20),
                                    ),
                                    child: Text(r,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF4338CA))),
                                  ))
                              .toList(),
                        ),
                      ],
                      if (summary.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          summary,
                          style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF475569),
                              height: 1.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              );
          },
        );
      }),
    );
  }
}
