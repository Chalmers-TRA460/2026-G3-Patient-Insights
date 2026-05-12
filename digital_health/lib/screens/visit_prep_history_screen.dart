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
      appBar: AppBar(title: Text('history.title'.tr)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Get.to(() => const PrepareVisitScreen()),
        icon: const Icon(Icons.add),
        label: Text('history.new'.tr),
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
                Text('history.empty'.tr,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  'history.empty_desc'.tr,
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
            final date = prep['date'] as String? ?? '';
            final summary = prep['summary'] as String? ?? '';

            // Build chips: new format -> question texts; old formats -> reasons.
            final List<String> chips;
            if (prep.containsKey('questions')) {
              chips = List<String>.from(prep['questions'] ?? const []);
            } else if (prep.containsKey('selectedCategories')) {
              final ids =
                  List<String>.from(prep['selectedCategories'] ?? const []);
              chips = ids.map((id) => 'visit.cat.$id'.tr).toList();
            } else {
              chips = List<String>.from(prep['visitReasons'] ?? const []);
            }

            return GestureDetector(
              onTap: () => Get.to(() => VisitPrepSummaryScreen(data: prep)),
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
                          tooltip: 'history.edit'.tr,
                          onPressed: () =>
                              Get.to(() => PrepareVisitScreen(editIndex: i)),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded,
                              size: 20, color: Colors.red[400]),
                          tooltip: 'history.delete'.tr,
                          onPressed: () => showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: Text('history.delete_title'.tr),
                              content: Text(title.isNotEmpty
                                  ? 'history.delete_named'.trParams({'title': title})
                                  : 'history.delete_generic'.tr),
                              actions: [
                                TextButton(
                                    onPressed: () => Get.back(),
                                    child: Text('history.cancel'.tr)),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red),
                                  onPressed: () {
                                    Get.back();
                                    c.deleteVisitPrep(i);
                                  },
                                  child: Text('history.delete'.tr),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (chips.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: chips
                            .map((r) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEEF2FF),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    r,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF4338CA)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
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
