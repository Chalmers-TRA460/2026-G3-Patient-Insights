import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import '../models/questionnaire_model.dart';
import 'visit_prep_summary_screen.dart';

class PrepareVisitScreen extends StatefulWidget {
  final int? editIndex;
  const PrepareVisitScreen({super.key, this.editIndex});

  @override
  State<PrepareVisitScreen> createState() => _PrepareVisitScreenState();
}

class _PrepareVisitScreenState extends State<PrepareVisitScreen> {
  late final HealthController _c;
  late final TextEditingController _titleController;
  final Map<String, TextEditingController> _noteControllers = {};
  late final PageController _pageController;
  int _currentPage = 0;
  static const int _totalPages = 5;

  // Canonical English values stored in Firestore — display via translation key.
  static const _durations = [
    'Today', '2–3 days', 'About a week', 'A few weeks', 'Over a month',
  ];
  static const _durationKeys = {
    'Today': 'prep.duration.today',
    '2–3 days': 'prep.duration.few_days',
    'About a week': 'prep.duration.week',
    'A few weeks': 'prep.duration.weeks',
    'Over a month': 'prep.duration.month',
  };

  static const _trends = ['Getting better', 'About the same', 'Getting worse'];
  static const _trendKeys = {
    'Getting better': 'prep.trend.better',
    'About the same': 'prep.trend.same',
    'Getting worse': 'prep.trend.worse',
  };

  static const _visitGoals = [
    "Find out what's wrong",
    'Get treatment or medication',
    'Have test results explained',
    'Review my medications',
    'Get a referral',
    'Just a routine check-up',
  ];
  static const _goalKeys = {
    "Find out what's wrong": 'prep.goal.find_out',
    'Get treatment or medication': 'prep.goal.treatment',
    'Have test results explained': 'prep.goal.test_results',
    'Review my medications': 'prep.goal.medications',
    'Get a referral': 'prep.goal.referral',
    'Just a routine check-up': 'prep.goal.checkup',
  };

  @override
  void initState() {
    super.initState();
    _c = Get.find<HealthController>();
    _pageController = PageController();

    for (final cat in kVisitTaxonomy) {
      _noteControllers[cat.id] = TextEditingController();
      for (final sub in cat.subQuestions) {
        _noteControllers[sub.id] = TextEditingController();
      }
    }

    if (widget.editIndex != null) {
      _c.loadVisitPrepForEdit(widget.editIndex!);
      _titleController = TextEditingController(text: _c.visitTitle.value);
      for (final entry in _c.itemNotes.entries) {
        _noteControllers[entry.key]?.text = entry.value;
      }
    } else {
      _c.clearVisitNotes();
      _titleController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _pageController.dispose();
    for (final ctrl in _noteControllers.values) ctrl.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editIndex != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'prep.title.edit'.tr : 'prep.title.new'.tr),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (_currentPage + 1) / _totalPages,
            backgroundColor: Colors.grey[200],
          ),
        ),
      ),
      body: Column(
        children: [
          // Step dots
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_totalPages, (i) {
                final active = i == _currentPage;
                final done = i < _currentPage;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: active ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: done || active
                        ? Theme.of(context).primaryColor
                        : Colors.grey[300],
                  ),
                );
              }),
            ),
          ),

          // Pages
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (p) => setState(() => _currentPage = p),
              children: [
                _buildPageWrapper(
                  title: 'prep.section.title'.tr,
                  subtitle: 'prep.section.title_sub'.tr,
                  child: TextField(
                    controller: _titleController,
                    onChanged: (v) => _c.visitTitle.value = v,
                    decoration: InputDecoration(
                      hintText: 'prep.section.title_hint'.tr,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                _buildPageWrapper(
                  title: 'prep.section.what_brings'.tr,
                  subtitle: 'prep.section.what_brings_sub'.tr,
                  child: Obx(() => Column(
                        children: kVisitTaxonomy
                            .map((cat) => _buildCategoryTile(cat, context))
                            .toList(),
                      )),
                ),
                _buildPageWrapper(
                  title: 'prep.section.how_long'.tr,
                  subtitle: 'prep.section.how_long_sub'.tr,
                  child: Obx(() => _buildChoiceChips(
                        options: _durations,
                        selected: _c.duration.value,
                        onTap: (v) => _c.duration.value = v,
                        labelFor: (o) => (_durationKeys[o] ?? o).tr,
                      )),
                ),
                _buildPageWrapper(
                  title: 'prep.section.trend'.tr,
                  child: Obx(() => _buildChoiceChips(
                        options: _trends,
                        selected: _c.symptomTrend.value,
                        onTap: (v) => _c.symptomTrend.value = v,
                        labelFor: (o) => (_trendKeys[o] ?? o).tr,
                      )),
                ),
                _buildPageWrapper(
                  title: 'prep.section.goals'.tr,
                  subtitle: 'prep.section.goals_sub'.tr,
                  child: Obx(() => _buildFilterChips(
                        options: _visitGoals,
                        selected: _c.visitGoals,
                        onTap: _c.toggleVisitGoal,
                        labelFor: (o) => (_goalKeys[o] ?? o).tr,
                      )),
                ),
              ],
            ),
          ),

          // Navigation buttons
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _goToPage(_currentPage - 1),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentPage > 0) const SizedBox(width: 12),
                  Expanded(
                    child: _currentPage < _totalPages - 1
                        ? ElevatedButton(
                            onPressed: () => _goToPage(_currentPage + 1),
                            child: const Text('Next'),
                          )
                        : Obx(() => ElevatedButton(
                              onPressed: _c.isGeneratingSummary.value
                                  ? null
                                  : () async {
                                      await _c.submitQuestionnaire(
                                          editIndex: widget.editIndex);
                                      if (_c.visitPrepSummary.value.isNotEmpty) {
                                        final idx = widget.editIndex ?? 0;
                                        Get.off(() => VisitPrepSummaryScreen(
                                            data: _c.visitPreps[idx]));
                                      }
                                    },
                              child: _c.isGeneratingSummary.value
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    )
                                  : Text(isEditing
                                      ? 'prep.btn.save'.tr
                                      : 'prep.btn.done'.tr),
                            )),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageWrapper({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle,
                style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildCategoryTile(VisitCategory cat, BuildContext context) {
    final isSelected = _c.selectedCategories.contains(cat.id);
    final isExpanded = _c.expandedCategories.contains(cat.id);
    final accent = Theme.of(context).colorScheme.secondary; // green #2ECC71

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? accent : Colors.grey.withOpacity(0.25),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(11)),
            onTap: () => _c.toggleCategory(cat.id),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Row(
                children: [
                  Checkbox(
                    value: isSelected,
                    onChanged: (_) => _c.toggleCategory(cat.id),
                    visualDensity: VisualDensity.compact,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'visit.cat.${cat.id}'.tr,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: null,
                      ),
                    ),
                  ),
                  if (isSelected)
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => _c.toggleExpanded(cat.id),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Icon(
                          isExpanded
                              ? Icons.expand_less
                              : Icons.expand_more,
                          color: Colors.grey[600],
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (isSelected)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: TextField(
                controller: _noteControllers[cat.id],
                onChanged: (v) => _c.setNote(cat.id, v),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'prep.note.category'.tr,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  isDense: true,
                ),
              ),
            ),
          if (isExpanded) ...[
            Divider(height: 1, indent: 16, endIndent: 16,
                color: accent.withOpacity(0.3)),
            ...cat.subQuestions.map((sub) => _buildSubQuestion(sub)),
            const SizedBox(height: 4),
          ],
        ],
      ),
      ),
    );
  }

  Widget _buildSubQuestion(VisitSubQuestion sub) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'visit.sub.${sub.id}'.tr,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _noteControllers[sub.id],
            onChanged: (v) => _c.setNote(sub.id, v),
            decoration: InputDecoration(
              hintText: 'prep.note.sub'.tr,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10)),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              isDense: true,
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildFilterChips({
    required List<String> options,
    required RxList<String> selected,
    required void Function(String) onTap,
    String Function(String)? labelFor,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map((o) => FilterChip(
                label: Text(labelFor != null ? labelFor(o) : o),
                selected: selected.contains(o),
                onSelected: (_) => onTap(o),
              ))
          .toList(),
    );
  }

  Widget _buildChoiceChips({
    required List<String> options,
    required String selected,
    required void Function(String) onTap,
    String Function(String)? labelFor,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map((o) => ChoiceChip(
                label: Text(labelFor != null ? labelFor(o) : o),
                selected: selected == o,
                onSelected: (_) => onTap(o),
              ))
          .toList(),
    );
  }
}
