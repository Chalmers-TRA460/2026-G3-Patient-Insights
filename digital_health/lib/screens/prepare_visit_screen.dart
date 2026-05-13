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
      if (_c.visitQuestions.isEmpty) {
        _questionControllers.add(TextEditingController());
      } else {
        for (final q in _c.visitQuestions) {
          _questionControllers.add(TextEditingController(text: q));
        }
      }
    } else {
      _c.clearVisitNotes();
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
    if (_c.visitPrepSummary.value.isNotEmpty) {
      final idx = widget.editIndex ?? 0;
      Get.off(() => VisitPrepSummaryScreen(data: _c.visitPreps[idx]));
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
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'prep.section.questions_sub'.tr,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 14),

            ...List.generate(_questionControllers.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 30,
                      child: Text(
                        '${i + 1}.',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700]),
                      ),
                    ),
                    Expanded(
                      child: TextField(
                        controller: _questionControllers[i],
                        decoration: InputDecoration(
                          hintText: 'prep.section.questions_hint'.tr,
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                        ),
                        style: const TextStyle(fontSize: 16),
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline,
                          color: Colors.redAccent),
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
