import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';

class ConsultationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> consultation;
  final int index;

  const ConsultationDetailScreen({
    super.key,
    required this.consultation,
    required this.index,
  });

  @override
  State<ConsultationDetailScreen> createState() =>
      _ConsultationDetailScreenState();
}

class _ConsultationDetailScreenState extends State<ConsultationDetailScreen> {
  bool _beforeExpanded = false;

  @override
  Widget build(BuildContext context) {
    final HealthController c = Get.find<HealthController>();

    return Scaffold(
      appBar: AppBar(title: Text('detail.title'.tr)),
      body: Obx(() {
        final visit = widget.index < c.consultations.length
            ? c.consultations[widget.index]
            : widget.consultation;

        final linkedPrepIndex = visit['linkedVisitPrepIndex'] as int?;
        final linkedPrep = (linkedPrepIndex != null &&
                linkedPrepIndex < c.visitPreps.length)
            ? c.visitPreps[linkedPrepIndex]
            : null;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date & Doctor
              Row(
                children: [
                  const Icon(Icons.calendar_today,
                      color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    visit['date'] as String? ?? 'detail.recent'.tr,
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue),
                  ),
                  const Spacer(),
                  Text(
                    visit['doctorName'] as String? ?? 'detail.doctor'.tr,
                    style: const TextStyle(
                        fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Before the visit (collapsible) ──
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFFED7AA)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header row — always visible, tap to expand/collapse
                    InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () =>
                          setState(() => _beforeExpanded = !_beforeExpanded),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
                        child: Row(
                          children: [
                            const Icon(Icons.edit_note_rounded,
                                color: Color(0xFFC2410C)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'detail.before'.tr,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFC2410C)),
                              ),
                            ),
                            Icon(
                              _beforeExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              color: const Color(0xFFC2410C),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Expandable content
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: _beforeExpanded
                          ? Padding(
                              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Divider(height: 1),
                                  const SizedBox(height: 12),
                                  if (linkedPrep != null) ...[
                                    // Prep title chip + change button
                                    Row(
                                      children: [
                                        Expanded(
                                          child: _prepTitle(
                                            linkedPrep['title'] as String? ??
                                                linkedPrep['date'] as String? ??
                                                '',
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        OutlinedButton.icon(
                                          onPressed: () => _pickVisitPrep(
                                              context, c, linkedPrepIndex),
                                          icon: const Icon(
                                              Icons.swap_horiz_rounded,
                                              size: 16),
                                          label: const Text('Change',
                                              style: TextStyle(fontSize: 13)),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFFC2410C),
                                            side: const BorderSide(
                                                color: Color(0xFFC2410C)),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 10, vertical: 6),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if ((linkedPrep['selectedCategories'] as List? ?? [])
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      _sectionLabel('prep.section.what_brings'.tr),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: List<String>.from(
                                                linkedPrep['selectedCategories'])
                                            .map((id) => _prepChip(
                                                'visit.cat.$id'.tr))
                                            .toList(),
                                      ),
                                    ],
                                    if ((linkedPrep['duration'] as String? ?? '')
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      _sectionLabel('prep.section.how_long'.tr),
                                      const SizedBox(height: 4),
                                      Text(linkedPrep['duration'] as String,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: Color(0xFF9A3412),
                                              height: 1.5)),
                                    ],
                                    if ((linkedPrep['symptomTrend'] as String? ?? '')
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      _sectionLabel('prep.section.trend'.tr),
                                      const SizedBox(height: 4),
                                      Text(linkedPrep['symptomTrend'] as String,
                                          style: const TextStyle(
                                              fontSize: 15,
                                              color: Color(0xFF9A3412),
                                              height: 1.5)),
                                    ],
                                    if ((linkedPrep['visitGoals'] as List? ?? [])
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      _sectionLabel('prep.section.goals'.tr),
                                      const SizedBox(height: 4),
                                      Text(
                                        List<String>.from(linkedPrep['visitGoals'])
                                            .join(', '),
                                        style: const TextStyle(
                                            fontSize: 15,
                                            color: Color(0xFF9A3412),
                                            height: 1.5),
                                      ),
                                    ],
                                  ] else ...[
                                    OutlinedButton.icon(
                                      onPressed: () => _pickVisitPrep(
                                          context, c, linkedPrepIndex),
                                      icon: const Icon(
                                          Icons.add_circle_outline_rounded,
                                          size: 18),
                                      label: const Text('Add preparation',
                                          style: TextStyle(fontSize: 14)),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(0xFFC2410C),
                                        side: const BorderSide(
                                            color: Color(0xFFC2410C)),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 8),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'No preparation added yet.',
                                      style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.orange.shade700,
                                          height: 1.5),
                                    ),
                                  ],
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 25),

              // ── AI Summary Card (conditional) ──
              Builder(builder: (_) {
                final summary = visit['summary'] as String? ?? '';
                final isGenerating = c.isSummarizingVisit.value;

                if (isGenerating) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 32),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                            color: Color(0xFF15803D)),
                        const SizedBox(height: 16),
                        Text('detail.generating'.tr,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF15803D))),
                      ],
                    ),
                  );
                }

                if (summary.isNotEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.auto_awesome_rounded,
                                color: Color(0xFF15803D)),
                            const SizedBox(width: 10),
                            Text('detail.ai_summary'.tr,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF15803D))),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Text(
                          summary,
                          style: const TextStyle(
                              fontSize: 18,
                              height: 1.6,
                              color: Color(0xFF166534)),
                        ),
                      ],
                    ),
                  );
                }

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.auto_awesome_rounded),
                    label: Text('detail.generate_summary'.tr,
                        style: const TextStyle(fontSize: 17)),
                    onPressed: () => c.generateSummaryForVisit(widget.index),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF15803D),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 25),

              // ── Full Conversation Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.chat_bubble_outline_rounded,
                            color: Color(0xFF475569)),
                        const SizedBox(width: 10),
                        Text('detail.transcript'.tr,
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF334155))),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Text(
                      visit['transcript'] as String? ??
                          'detail.no_transcript'.tr,
                      style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF475569),
                          height: 1.6),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  void _pickVisitPrep(
      BuildContext context, HealthController c, int? current) {
    if (c.visitPreps.isEmpty) {
      Get.snackbar('No preparations found',
          'You have not saved any visit preparations yet.',
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Select a visit preparation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Which preparation was for this visit?',
              style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          const Divider(height: 24),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: c.visitPreps.length,
              itemBuilder: (_, i) {
                final prep = c.visitPreps[i];
                final title = prep['title'] as String? ?? '';
                final date = prep['date'] as String? ?? '';
                final isSelected = current == i;
                return ListTile(
                  leading: Icon(
                    Icons.edit_note_rounded,
                    color: isSelected
                        ? Theme.of(context).primaryColor
                        : Colors.grey,
                  ),
                  title: Text(title.isNotEmpty ? title : date,
                      style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal)),
                  subtitle: title.isNotEmpty ? Text(date) : null,
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded,
                          color: Theme.of(context).primaryColor)
                      : null,
                  onTap: () {
                    c.updateConsultation(
                        widget.index, {'linkedVisitPrepIndex': i});
                    Get.back();
                  },
                );
              },
            ),
          ),
          if (current != null)
            TextButton(
              onPressed: () {
                c.updateConsultation(
                    widget.index, {'linkedVisitPrepIndex': null});
                Get.back();
              },
              child: const Text('Remove this preparation',
                  style: TextStyle(color: Colors.red)),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: Color(0xFF9A3412),
          letterSpacing: 0.3),
    );
  }

  Widget _prepTitle(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF7C2D12),
      ),
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _prepChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDD5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Text(label,
          style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF9A3412))),
    );
  }

}
