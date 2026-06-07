import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import 'visit_prep_summary_screen.dart';

class PrepareVisitScreen extends StatefulWidget {
  final int? editIndex;
  const PrepareVisitScreen({super.key, this.editIndex});

  @override
  State<PrepareVisitScreen> createState() => _PrepareVisitScreenState();
}

class _PrepareVisitScreenState extends State<PrepareVisitScreen> {
  late final HealthController _c;
  late final TextEditingController _reasonController;
  final List<TextEditingController> _questionControllers = [];

  @override
  void initState() {
    super.initState();
    _c = Get.find<HealthController>();

    if (widget.editIndex != null) {
      _c.loadVisitPrepForEdit(widget.editIndex!);
      _reasonController = TextEditingController(text: _c.visitTitle.value);
      // Sync date/time from saved prep into controller
      final prep = _c.visitPreps[widget.editIndex!];
      _c.appointmentDate.value = (prep['date'] as String? ?? '');
      _c.appointmentTime.value = (prep['time'] as String? ?? '');
      if (_c.visitQuestions.isEmpty) {
        _questionControllers.add(TextEditingController());
      } else {
        for (final q in _c.visitQuestions) {
          _questionControllers.add(TextEditingController(text: q));
        }
      }
    } else {
      _reasonController = TextEditingController();
      _questionControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    for (final c in _questionControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _addQuestionField() {
    setState(() {
      _questionControllers.add(TextEditingController());
    });
  }

  void _removeQuestionField(int index) {
    setState(() {
      _questionControllers[index].dispose();
      _questionControllers.removeAt(index);
      if (_questionControllers.isEmpty) {
        _questionControllers.add(TextEditingController());
      }
    });
  }

  void _syncToController() {
    _c.visitTitle.value = _reasonController.text.trim();
    _c.visitQuestions.assignAll(
      _questionControllers
          .map((c) => c.text.trim())
          .where((q) => q.isNotEmpty)
          .toList(),
    );
  }

  Future<void> _onSubmit() async {
    _syncToController();
    if (_c.visitTitle.value.isEmpty) {
      Get.snackbar(
        'snackbar.info'.tr,
        'prep.error.no_reason'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
    await _c.submitQuestionnaire(editIndex: widget.editIndex);
    if (widget.editIndex == null) {
      Get.off(() => VisitPrepSummaryScreen(data: _c.visitPreps.first));
    } else {
      Get.back();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editIndex != null;
    final primary = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'prep.title.edit'.tr : 'prep.title.new'.tr),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Step badge + read-only date chip ─────────────────────────
            if (!isEditing) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0066CC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Step 2 of 3',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text('Prepare questions',
                      style: TextStyle(
                          fontSize: 13,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(height: 10),
              Obx(() {
                final date = _c.appointmentDate.value;
                final time = _c.appointmentTime.value;
                if (date.isEmpty) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.event_rounded,
                          size: 16, color: Color(0xFF1D4ED8)),
                      const SizedBox(width: 8),
                      Text(
                        time.isNotEmpty ? '$date · $time' : date,
                        style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF1D4ED8),
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],

            // ── Q1: Reason / title ───────────────────────────────────────
            Text(
              'prep.section.reason'.tr,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'prep.section.reason_sub'.tr,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _reasonController,
              onChanged: (v) => _c.visitTitle.value = v.trim(),
              decoration: InputDecoration(
                hintText: 'prep.section.reason_hint'.tr,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
              ),
              style: const TextStyle(fontSize: 16),
              textInputAction: TextInputAction.next,
            ),

            const SizedBox(height: 28),

            // ── Q2: Questions list ───────────────────────────────────────
            Text(
              'prep.section.questions'.tr,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'prep.section.questions_sub'.tr,
              style: TextStyle(fontSize: 15, color: Colors.grey[600], height: 1.4),
            ),
            const SizedBox(height: 18),

            ...List.generate(_questionControllers.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _questionControllers[i],
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          hintText: 'prep.section.questions_hint'.tr,
                          hintStyle: TextStyle(
                              fontSize: 17, color: Colors.grey[400]),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                        style: const TextStyle(fontSize: 18, height: 1.4),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.redAccent, size: 26),
                      tooltip: 'prep.btn.remove_question'.tr,
                      onPressed: () => _removeQuestionField(i),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: _addQuestionField,
                icon: Icon(Icons.add, color: primary),
                label: Text('prep.btn.add_question'.tr,
                    style: TextStyle(color: primary)),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 12),
                  side: BorderSide(color: primary),
                ),
              ),
            ),

            const SizedBox(height: 36),

            // ── Submit ───────────────────────────────────────────────────
            Obx(() => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed:
                        _c.isGeneratingSummary.value ? null : _onSubmit,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _c.isGeneratingSummary.value
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isEditing
                                ? 'prep.btn.save'.tr
                                : 'prep.btn.done'.tr,
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}
