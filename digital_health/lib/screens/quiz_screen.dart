import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/quiz_question_model.dart';

class QuizScreen extends StatefulWidget {
  final List<QuizQuestion> questions;

  const QuizScreen({super.key, required this.questions});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _current = 0;
  int _score = 0;
  int? _selected;
  bool _answered = false;
  bool _finished = false;

  QuizQuestion get _q => widget.questions[_current];

  void _selectOption(int index) {
    if (_answered) return;
    final correct = index == _q.correctIndex;
    setState(() {
      _selected = index;
      _answered = true;
      if (correct) _score++;
    });
  }

  void _next() {
    if (_current < widget.questions.length - 1) {
      setState(() {
        _current++;
        _selected = null;
        _answered = false;
      });
    } else {
      setState(() => _finished = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('quiz.title'.tr),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: _finished ? _buildResults() : _buildQuestion(),
    );
  }

  Widget _buildQuestion() {
    final total = widget.questions.length;
    final progress = (_current + 1) / total;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF0066CC)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'quiz.question_of'
                    .trParams({'current': '${_current + 1}', 'total': '$total'}),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // "Not mentioned in visit" alert — shown when the question is
          // general best-practice advice that wasn't actually discussed.
          if (_q.notMentioned) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFECACA), width: 1.5),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFDC2626), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'quiz.not_mentioned_title'.tr,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF991B1B)),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'quiz.not_mentioned_desc'.tr,
                          style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF7F1D1D),
                              height: 1.45),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Question card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: Text(
              _q.question,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  height: 1.5),
            ),
          ),
          const SizedBox(height: 20),

          // Options
          ...List.generate(_q.options.length, (i) => _buildOption(i)),
          const SizedBox(height: 20),

          // Explanation (shown after answering)
          if (_answered) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFBAE6FD)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFF0284C7), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _q.explanation,
                      style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF0C4A6E),
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Next / Finish button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  _current < widget.questions.length - 1
                      ? 'quiz.next'.tr
                      : 'quiz.finish'.tr,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOption(int index) {
    final isSelected = _selected == index;
    final isCorrect = index == _q.correctIndex;

    Color bg = Colors.white;
    Color border = const Color(0xFFE2E8F0);
    Color textColor = const Color(0xFF1E293B);
    Widget? trailing;

    if (_answered) {
      if (isCorrect) {
        bg = const Color(0xFFF0FDF4);
        border = const Color(0xFF86EFAC);
        textColor = const Color(0xFF166534);
        trailing = const Icon(Icons.check_circle_rounded,
            color: Color(0xFF16A34A), size: 22);
      } else if (isSelected) {
        bg = const Color(0xFFFFF1F2);
        border = const Color(0xFFFDA4AF);
        textColor = const Color(0xFF9F1239);
        trailing = const Icon(Icons.cancel_rounded,
            color: Color(0xFFE11D48), size: 22);
      }
    }

    return GestureDetector(
      onTap: () => _selectOption(index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: isSelected ? 2 : 1),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _answered && isCorrect
                    ? const Color(0xFF16A34A)
                    : _answered && isSelected
                        ? const Color(0xFFE11D48)
                        : const Color(0xFFE2E8F0),
              ),
              child: Center(
                child: Text(
                  String.fromCharCode(65 + index),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: (_answered && (isCorrect || isSelected))
                          ? Colors.white
                          : const Color(0xFF64748B)),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                _q.options[index],
                style: TextStyle(
                    fontSize: 16, color: textColor, height: 1.4),
              ),
            ),
            if (trailing != null) ...[
              const SizedBox(width: 8),
              trailing,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final total = widget.questions.length;
    final pct = ((_score / total) * 100).round();
    final excellent = pct >= 80;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: excellent
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFFFF7ED),
              ),
              child: Icon(
                excellent
                    ? Icons.emoji_events_rounded
                    : Icons.school_rounded,
                size: 52,
                color: excellent
                    ? const Color(0xFF16A34A)
                    : const Color(0xFFD97706),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'quiz.result_title'.tr,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 12),
            Text(
              'quiz.result_score'
                  .trParams({'score': '$_score', 'total': '$total'}),
              style: const TextStyle(
                  fontSize: 18, color: Color(0xFF475569), height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              '$pct%',
              style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: excellent
                      ? const Color(0xFF16A34A)
                      : const Color(0xFFD97706)),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: Get.back,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('quiz.back'.tr,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => setState(() {
                _current = 0;
                _score = 0;
                _selected = null;
                _answered = false;
                _finished = false;
              }),
              child: Text('quiz.retry'.tr,
                  style: const TextStyle(
                      fontSize: 16, color: Color(0xFF0066CC))),
            ),
          ],
        ),
      ),
    );
  }
}
