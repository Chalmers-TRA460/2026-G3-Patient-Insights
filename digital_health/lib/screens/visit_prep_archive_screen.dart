import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import 'visit_prep_summary_screen.dart';

class VisitPrepArchiveScreen extends StatelessWidget {
  const VisitPrepArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.find<HealthController>();

    return Scaffold(
      appBar: AppBar(title: Text('archive.title'.tr)),
      body: Obx(() {
        final entries = c.archivedVisitPrepsIndexed;
        if (entries.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text('archive.empty'.tr,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'archive.empty_desc'.tr,
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
          itemCount: entries.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, idx) {
            final i = entries[idx].key;
            final prep = entries[idx].value;
            final title = prep['title'] as String? ?? '';
            final date = prep['date'] as String? ?? '';

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
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
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
                          icon: const Icon(Icons.unarchive_outlined,
                              size: 20, color: Color(0xFF2563EB)),
                          tooltip: 'archive.restore'.tr,
                          onPressed: () => c.restoreVisitPrep(i),
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
                                  ? 'history.delete_named'
                                      .trParams({'title': title})
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
                                    color: const Color(0xFFE2E8F0),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    r,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF475569)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ))
                            .toList(),
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
