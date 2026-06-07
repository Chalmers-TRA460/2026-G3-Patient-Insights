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
  bool _transcriptExpanded = false;
  bool _isGeneratingQuiz = false;
  bool _editingBrief = false;
  final TextEditingController _briefController = TextEditingController();

  @override
  void dispose() {
    _briefController.dispose();
    super.dispose();
  }

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

        // Resolve linked prep by id (preferred) or legacy index. Both lookups
        // search the full visitPreps list so an auto-archived prep is still
        // visible on its consultation.
        final linkedPrepId = visit['linkedVisitPrepId'] as String?;
        final legacyPrepIndex = visit['linkedVisitPrepIndex'] as int?;
        int? resolvedPrepIndex;
        if (linkedPrepId != null) {
          final i =
              c.visitPreps.indexWhere((p) => p['id'] == linkedPrepId);
          if (i != -1) resolvedPrepIndex = i;
        }
        resolvedPrepIndex ??= (legacyPrepIndex != null &&
                legacyPrepIndex < c.visitPreps.length)
            ? legacyPrepIndex
            : null;
        final linkedPrep =
            resolvedPrepIndex != null ? c.visitPreps[resolvedPrepIndex] : null;

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
                                              context, c, resolvedPrepIndex),
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
                                          context, c, resolvedPrepIndex),
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

              // ── Questions the doctor didn't address ──
              // Shown only when a preparation was linked AND the AI flagged
              // one or more of its questions as unanswered in the transcript.
              Builder(builder: (_) {
                if (linkedPrep == null) return const SizedBox.shrink();
                final unanswered = (visit['unansweredQuestions'] as List? ??
                        const [])
                    .whereType<String>()
                    .map((q) => q.trim())
                    .where((q) => q.isNotEmpty)
                    .toList();
                if (unanswered.isEmpty) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFFECACA), width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: Color(0xFFDC2626), size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'detail.forgotten_title'.tr,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF991B1B)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'detail.forgotten_subtitle'.tr,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7F1D1D),
                              height: 1.45),
                        ),
                        const SizedBox(height: 12),
                        ...unanswered.asMap().entries.map((e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(
                                        top: 6, right: 10),
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFDC2626),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      e.value,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          color: Color(0xFF7F1D1D),
                                          height: 1.5),
                                    ),
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 25),

              // ── AI Summary Card (conditional) ──
              Builder(builder: (_) {
                final briefSummary = visit['briefSummary'] as String? ?? '';
                final detailedSummary = visit['detailedSummary'] as String? ?? '';
                final legacySummary = visit['summary'] as String? ?? '';
                final history = List<Map<String, dynamic>>.from(
                    (visit['briefHistory'] as List? ?? const [])
                        .whereType<Map>()
                        .map((e) => Map<String, dynamic>.from(e)));
                final isGenerating = c.isSummarizingVisit.value;
                final isRegenerating = c.isRegeneratingDetailed.value;

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

                // New dual-level format — auto-expand detail when brief is empty
                if (briefSummary.isEmpty && detailedSummary.isNotEmpty && !_detailExpanded) {
                  WidgetsBinding.instance.addPostFrameCallback(
                      (_) => setState(() => _detailExpanded = true));
                }
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
                                color: Color(0xFF15803D), size: 26),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text('detail.brief_label'.tr,
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF15803D))),
                            ),
                            if (history.isNotEmpty && !_editingBrief)
                              _editedBadge(),
                          ],
                        ),

                        // Brief: view mode or edit mode
                        if (_editingBrief) ...[
                          const SizedBox(height: 14),
                          TextField(
                            controller: _briefController,
                            maxLines: null,
                            minLines: 4,
                            style: const TextStyle(
                                fontSize: 24,
                                height: 1.55,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF14532D)),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.all(14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Color(0xFFBBF7D0)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Color(0xFFBBF7D0)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                                borderSide: const BorderSide(
                                    color: Color(0xFF15803D), width: 2),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'detail.edit_hint'.tr,
                            style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF15803D),
                                fontStyle: FontStyle.italic),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: isRegenerating
                                    ? null
                                    : () => setState(() {
                                          _editingBrief = false;
                                          _briefController.clear();
                                        }),
                                child: Text('detail.cancel'.tr,
                                    style: const TextStyle(fontSize: 15)),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: isRegenerating
                                    ? null
                                    : () => _confirmAndSaveBrief(c),
                                icon: const Icon(Icons.check_rounded, size: 18),
                                label: Text('detail.save'.tr,
                                    style: const TextStyle(fontSize: 15)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF15803D),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 18, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const SizedBox(height: 18),
                          ..._buildBriefPoints(briefSummary.isNotEmpty
                              ? briefSummary
                              : '• See full summary below.'),
                          const SizedBox(height: 18),
                          const Divider(
                              color: Color(0xFFBBF7D0),
                              thickness: 1.5,
                              height: 1),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              OutlinedButton.icon(
                                onPressed: isRegenerating
                                    ? null
                                    : () => setState(() {
                                          _briefController.text = briefSummary;
                                          _editingBrief = true;
                                        }),
                                icon: const Icon(Icons.edit_rounded, size: 18),
                                label: Text('detail.edit_brief'.tr,
                                    style: const TextStyle(fontSize: 15)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF15803D),
                                  side: const BorderSide(
                                      color: Color(0xFF15803D)),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 8),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (history.isNotEmpty)
                                TextButton.icon(
                                  onPressed: isRegenerating
                                      ? null
                                      : () => _showHistorySheet(c, history),
                                  icon: const Icon(Icons.history_rounded,
                                      size: 18,
                                      color: Color(0xFF15803D)),
                                  label: Text(
                                      'detail.previous_versions'.tr,
                                      style: const TextStyle(
                                          fontSize: 15,
                                          color: Color(0xFF15803D),
                                          fontWeight: FontWeight.w600)),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 6),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                            ],
                          ),
                        ],

                        if (detailedSummary.isNotEmpty ||
                            isRegenerating) ...[
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: isRegenerating
                                ? null
                                : () => setState(
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
                                      const SizedBox(height: 12),
                                      if (isRegenerating)
                                        _regeneratingDetailedBox()
                                      else
                                        _buildDetailedSections(detailedSummary),
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

              // ── Full Conversation Card (collapsible, collapsed by default) ──
              Builder(builder: (_) {
                final transcript = visit['transcript'] as String? ??
                    'detail.no_transcript'.tr;
                return Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tappable header — toggles the conversation open/closed
                      InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => setState(
                            () => _transcriptExpanded = !_transcriptExpanded),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                          child: Row(
                            children: [
                              const Icon(Icons.chat_bubble_outline_rounded,
                                  color: Color(0xFF475569)),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text('detail.transcript'.tr,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF334155))),
                              ),
                              Icon(
                                _transcriptExpanded
                                    ? Icons.expand_less_rounded
                                    : Icons.expand_more_rounded,
                                color: const Color(0xFF475569),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // Transcript body — short preview when collapsed, full
                      // text plus a "Show less" button when expanded.
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: AnimatedSize(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          alignment: Alignment.topCenter,
                          child: _transcriptExpanded
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      transcript,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          color: Color(0xFF475569),
                                          height: 1.6),
                                    ),
                                    const SizedBox(height: 8),
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: TextButton.icon(
                                        onPressed: () => setState(() =>
                                            _transcriptExpanded = false),
                                        icon: const Icon(
                                            Icons.expand_less_rounded,
                                            color: Color(0xFF475569)),
                                        label: Text('detail.show_less'.tr,
                                            style: const TextStyle(
                                                color: Color(0xFF475569),
                                                fontWeight:
                                                    FontWeight.w600)),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          tapTargetSize: MaterialTapTargetSize
                                              .shrinkWrap,
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Text(
                                  transcript,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      color: Color(0xFF475569),
                                      height: 1.6),
                                ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
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
                    c.updateConsultation(widget.index, {
                      'linkedVisitPrepId': prep['id'],
                      'linkedVisitPrepIndex': null,
                    });
                    Get.back();
                  },
                );
              },
            ),
          ),
          if (current != null)
            TextButton(
              onPressed: () {
                c.updateConsultation(widget.index, {
                  'linkedVisitPrepId': null,
                  'linkedVisitPrepIndex': null,
                });
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

  Widget _editedBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFBBF7D0),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'detail.edited_badge'.tr,
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Color(0xFF166534),
            letterSpacing: 0.3),
      ),
    );
  }

  Widget _regeneratingDetailedBox() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      width: double.infinity,
      child: Column(
        children: [
          const CircularProgressIndicator(color: Color(0xFF15803D)),
          const SizedBox(height: 12),
          Text('detail.regenerating_detailed'.tr,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF15803D))),
        ],
      ),
    );
  }

  // Splits the brief summary into individual points and renders each as its
  // own row with a leading check icon. The brief is requested from the AI as
  // a • bullet list; if the patient has edited it free-form, we fall back to
  // splitting on newlines so points still stay visually distinct.
  List<Widget> _buildBriefPoints(String text) {
    const bodyStyle = TextStyle(
      fontSize: 24,
      height: 1.55,
      fontWeight: FontWeight.w500,
      color: Color(0xFF14532D),
    );

    List<String> parts;
    if (text.contains('•')) {
      parts = text
          .split('•')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    } else {
      parts = text
          .split(RegExp(r'\r?\n'))
          .map((s) => s.replaceFirst(RegExp(r'^[\-\*•]\s*'), '').trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    if (parts.isEmpty) parts = [text.trim()];

    return List<Widget>.generate(parts.length, (i) {
      final isLast = i == parts.length - 1;
      return Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 10,
              height: 10,
              margin: const EdgeInsets.only(top: 14, right: 14),
              decoration: const BoxDecoration(
                color: Color(0xFF15803D),
                shape: BoxShape.circle,
              ),
            ),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: _parseInlineBold(parts[i], bodyStyle),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  // Splits the detailed summary into blocks separated by blank lines, treats
  // any leading line wrapped in **...** as a section heading, and renders
  // the rest as body paragraphs. Inline **bold** within body text is parsed
  // into bold spans so the asterisks never leak into the rendered output.
  Widget _buildDetailedSections(String text) {
    final blocks = text
        .split(RegExp(r'\n\s*\n'))
        .map((b) => b.trim())
        .where((b) => b.isNotEmpty)
        .toList();

    final lineHeadingPattern = RegExp(r'^\*\*\s*(.+?)\s*\*\*\s*$');
    final widgets = <Widget>[];
    bool firstHeadingSeen = false;

    for (final block in blocks) {
      final lines = block.split('\n');
      String? heading;
      String body = block;

      final headingMatch = lineHeadingPattern.firstMatch(lines.first.trim());
      if (headingMatch != null) {
        heading = headingMatch.group(1);
        body = lines.skip(1).join('\n').trim();
      }

      if (heading != null) {
        if (firstHeadingSeen) {
          widgets.add(const SizedBox(height: 18));
        } else {
          firstHeadingSeen = true;
        }
        widgets.add(Text(
          heading,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF15803D),
              height: 1.4),
        ));
        if (body.isNotEmpty) widgets.add(const SizedBox(height: 6));
      } else if (widgets.isNotEmpty && widgets.last is! SizedBox) {
        widgets.add(const SizedBox(height: 10));
      }

      if (body.isNotEmpty) {
        const bodyStyle = TextStyle(
            fontSize: 16, height: 1.7, color: Color(0xFF166534));
        widgets.add(Text.rich(
          TextSpan(children: _parseInlineBold(body, bodyStyle)),
        ));
      }
    }

    if (widgets.isEmpty) {
      return Text(
        text,
        style: const TextStyle(
            fontSize: 16, height: 1.7, color: Color(0xFF166534)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  // Tokenises a string on **...** pairs and returns spans where the wrapped
  // text is bold. Unmatched ** at the end is preserved as-is.
  List<TextSpan> _parseInlineBold(String text, TextStyle baseStyle) {
    final pattern = RegExp(r'\*\*(.+?)\*\*', dotAll: true);
    final spans = <TextSpan>[];
    int cursor = 0;
    for (final m in pattern.allMatches(text)) {
      if (m.start > cursor) {
        spans.add(TextSpan(
            text: text.substring(cursor, m.start), style: baseStyle));
      }
      spans.add(TextSpan(
        text: m.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.bold),
      ));
      cursor = m.end;
    }
    if (cursor < text.length) {
      spans.add(TextSpan(text: text.substring(cursor), style: baseStyle));
    }
    return spans;
  }

  Future<void> _confirmAndSaveBrief(HealthController c) async {
    final newBrief = _briefController.text.trim();
    if (newBrief.isEmpty) {
      Get.snackbar('snackbar.info'.tr, 'detail.brief_label'.tr,
          snackPosition: SnackPosition.BOTTOM);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('detail.confirm_save_title'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('detail.confirm_save_body'.tr,
            style: const TextStyle(fontSize: 15, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('detail.cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
            ),
            child: Text('detail.save'.tr),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _editingBrief = false;
      _detailExpanded = true; // so the patient sees the new detailed text
    });

    await c.editBriefSummary(widget.index, newBrief);
    _briefController.clear();
  }

  Future<void> _showHistorySheet(
      HealthController c, List<Map<String, dynamic>> history) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('detail.previous_versions_title'.tr,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('detail.previous_versions_subtitle'.tr,
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 12),
            const Divider(),
            if (history.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('detail.no_previous_versions'.tr,
                      style: TextStyle(color: Colors.grey[600])),
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: history.length,
                  separatorBuilder: (_, __) => const Divider(height: 16),
                  itemBuilder: (_, i) {
                    final entry = history[i];
                    final text = (entry['text'] as String? ?? '').trim();
                    final ts = entry['timestamp'] as String? ?? '';
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        text,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, height: 1.5),
                      ),
                      subtitle: ts.isEmpty
                          ? null
                          : Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(_formatTimestamp(ts),
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.grey[600])),
                            ),
                      trailing: ElevatedButton.icon(
                        onPressed: () =>
                            _confirmAndRestore(c, i),
                        icon: const Icon(Icons.restore_rounded, size: 16),
                        label: Text('detail.restore'.tr,
                            style: const TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF15803D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndRestore(HealthController c, int historyIndex) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('detail.confirm_restore_title'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text('detail.confirm_restore_body'.tr,
            style: const TextStyle(fontSize: 15, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('detail.cancel'.tr),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D),
              foregroundColor: Colors.white,
            ),
            child: Text('detail.restore'.tr),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    Get.back(); // close the bottom sheet
    setState(() => _detailExpanded = true);
    await c.restoreBriefVersion(widget.index, historyIndex);
  }

  String _formatTimestamp(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return iso;
    final local = dt.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)}  '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
