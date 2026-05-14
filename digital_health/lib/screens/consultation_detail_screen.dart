import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import '../controllers/settings_controller.dart';
import '../models/quiz_question_model.dart';
import '../services/ai_service.dart';
import 'edit_consultation_screen.dart';
import 'quiz_screen.dart';

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
  bool _detailExpanded = false;
  bool _isGeneratingQuiz = false;

  @override
  Widget build(BuildContext context) {
    final HealthController c = Get.find<HealthController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('detail.title'.tr),
        actions: [
          Obx(() {
            if (c.isViewingOther) return const SizedBox.shrink();
            final visit = widget.index < c.consultations.length
                ? c.consultations[widget.index]
                : widget.consultation;
            return IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'edit_consult.title'.tr,
              onPressed: () => Get.to(
                () => EditConsultationScreen(
                    visit: visit, index: widget.index),
                fullscreenDialog: true,
              ),
            );
          }),
        ],
      ),
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
                                    if ((linkedPrep['questions'] as List? ?? [])
                                        .isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      _sectionLabel('summary.questions'.tr),
                                      const SizedBox(height: 6),
                                      ...List<String>.from(
                                              linkedPrep['questions'])
                                          .asMap()
                                          .entries
                                          .map((e) => Padding(
                                                padding:
                                                    const EdgeInsets.only(
                                                        bottom: 4),
                                                child: Text(
                                                  '${e.key + 1}. ${e.value}',
                                                  style: const TextStyle(
                                                      fontSize: 15,
                                                      color: Color(
                                                          0xFF9A3412),
                                                      height: 1.5),
                                                ),
                                              )),
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
                final briefSummary = visit['briefSummary'] as String? ?? '';
                final detailedSummary = visit['detailedSummary'] as String? ?? '';
                final legacySummary = visit['summary'] as String? ?? '';
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

                // New dual-level format
                if (briefSummary.isNotEmpty || detailedSummary.isNotEmpty) {
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
                            Text('detail.brief_label'.tr,
                                style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF15803D))),
                          ],
                        ),
                        if (briefSummary.isNotEmpty) ...[
                          const SizedBox(height: 14),
                          Text(
                            briefSummary,
                            style: const TextStyle(
                                fontSize: 16,
                                height: 1.7,
                                color: Color(0xFF166534)),
                          ),
                        ],
                        if (detailedSummary.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: () => setState(
                                () => _detailExpanded = !_detailExpanded),
                            icon: Icon(
                              _detailExpanded
                                  ? Icons.expand_less_rounded
                                  : Icons.expand_more_rounded,
                              color: const Color(0xFF15803D),
                            ),
                            label: Text(
                              _detailExpanded
                                  ? 'detail.show_less'.tr
                                  : 'detail.read_more'.tr,
                              style: const TextStyle(
                                  color: Color(0xFF15803D),
                                  fontWeight: FontWeight.w600),
                            ),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            child: _detailExpanded
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Divider(
                                          color: Color(0xFFBBF7D0),
                                          height: 24),
                                      Text(
                                        'detail.full_label'.tr,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF15803D),
                                            letterSpacing: 0.3),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        detailedSummary,
                                        style: const TextStyle(
                                            fontSize: 16,
                                            height: 1.7,
                                            color: Color(0xFF166534)),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                // Legacy format (single summary string)
                if (legacySummary.isNotEmpty) {
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
                          legacySummary,
                          style: const TextStyle(
                              fontSize: 16,
                              height: 1.7,
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
              const SizedBox(height: 20),

              // ── Test My Knowledge ──
              Builder(builder: (_) {
                final transcript = visit['transcript'] as String? ?? '';
                if (transcript.isEmpty) return const SizedBox.shrink();

                final storedQuiz = visit['quiz'] as List?;
                final hasQuiz =
                    storedQuiz != null && storedQuiz.isNotEmpty;

                if (_isGeneratingQuiz) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      children: [
                        const CircularProgressIndicator(
                            color: Color(0xFFD97706)),
                        const SizedBox(height: 14),
                        Text('quiz.generating'.tr,
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF92400E))),
                      ],
                    ),
                  );
                }

                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(hasQuiz
                        ? Icons.play_arrow_rounded
                        : Icons.quiz_rounded),
                    label: Text(
                        hasQuiz
                            ? 'quiz.take'.tr
                            : 'detail.test_knowledge'.tr,
                        style: const TextStyle(fontSize: 17)),
                    onPressed: () => hasQuiz
                        ? _openStoredQuiz(storedQuiz!)
                        : _generateQuiz(c, transcript),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD97706),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 32),

              // ── Delete visit ──
              if (!c.isViewingOther) ...[
                const Divider(),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: Colors.red),
                    label: Text('delete_visit.btn'.tr,
                        style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                            fontWeight: FontWeight.w600)),
                    onPressed: () => _confirmDelete(c),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  void _confirmDelete(HealthController c) {
    Get.defaultDialog(
      title: 'delete_visit.title'.tr,
      middleText: 'delete_visit.body'.tr,
      textCancel: 'delete_visit.cancel'.tr,
      textConfirm: 'delete_visit.confirm'.tr,
      confirmTextColor: Colors.white,
      buttonColor: Colors.red,
      onConfirm: () {
        Get.back();
        c.deleteConsultation(widget.index);
      },
    );
  }

  void _openStoredQuiz(List raw) {
    final questions = raw
        .whereType<Map<String, dynamic>>()
        .map(QuizQuestion.fromJson)
        .where((q) => q.question.isNotEmpty && q.options.length >= 2)
        .toList();
    if (questions.isNotEmpty) {
      Get.to(() => QuizScreen(questions: questions));
    }
  }

  Future<void> _generateQuiz(HealthController c, String transcript) async {
    setState(() => _isGeneratingQuiz = true);
    try {
      final lang = Get.find<SettingsController>().resolvedLanguageName;
      final questions = await AiService.generateVisitQuiz(
        transcript,
        patient: c.patient.value,
        targetLanguage: lang,
      );
      if (questions.isEmpty) {
        Get.snackbar('quiz.title'.tr, 'quiz.empty'.tr,
            snackPosition: SnackPosition.BOTTOM);
        return;
      }
      await c.updateConsultation(widget.index, {
        'quiz': questions.map((q) => q.toJson()).toList(),
      });
      Get.to(() => QuizScreen(questions: questions));
    } catch (e) {
      Get.snackbar('quiz.title'.tr, 'quiz.error'.tr,
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      setState(() => _isGeneratingQuiz = false);
    }
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


}
