import 'dart:async';
import 'dart:io' show File;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../controllers/health_controller.dart';
import '../controllers/settings_controller.dart';
import '../services/ai_service.dart';
import 'consultation_detail_screen.dart';
import 'consultation_history_screen.dart';

enum _Stage { idle, recording, transcribing, transcribed, summarizing }

class RecordConsultationScreen extends StatefulWidget {
  const RecordConsultationScreen({super.key});

  @override
  State<RecordConsultationScreen> createState() =>
      _RecordConsultationScreenState();
}

class _RecordConsultationScreenState extends State<RecordConsultationScreen> {
  final _recorder = AudioRecorder();
  final _healthController = Get.find<HealthController>();
  final _transcriptController = TextEditingController();

  _Stage _stage = _Stage.idle;
  bool _isPaused = false;
  String? _audioPath;
  Uint8List? _audioBytes;
  String _errorMessage = '';

  Timer? _timer;
  int _recordSeconds = 0;

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _recordSeconds++);
    });
  }

  @override
  void dispose() {
    _recorder.dispose();
    _transcriptController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Recording ─────────────────────────────────────────────────────────────

  Future<bool> _askConsent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.privacy_tip_rounded, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Text('record.consent_title'.tr,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          ],
        ),
        content: Text('record.consent_body'.tr,
            style: const TextStyle(fontSize: 15, height: 1.5)),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('record.consent_cancel'.tr,
                style: const TextStyle(fontSize: 15)),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text('record.consent_confirm'.tr,
                style: const TextStyle(fontSize: 15)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _startRecording() async {
    final consented = await _askConsent();
    if (!consented) return;

    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      setState(() => _errorMessage = 'Microphone permission denied.');
      return;
    }

    String path = '';
    if (!kIsWeb) {
      final dir = await getTemporaryDirectory();
      path =
          '${dir.path}/consultation_${DateTime.now().millisecondsSinceEpoch}.m4a';
    }
    _audioPath = path;
    _audioBytes = null;

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 16000,
      ),
      path: path,
    );

    _recordSeconds = 0;
    _startTimer();

    setState(() {
      _stage = _Stage.recording;
      _isPaused = false;
      _errorMessage = '';
    });
  }

  Future<void> _pauseRecording() async {
    if (_isPaused) return;
    try {
      await _recorder.pause();
    } catch (e) {
      setState(() => _errorMessage = 'Pause failed: $e');
      return;
    }
    _timer?.cancel();
    setState(() => _isPaused = true);
  }

  Future<void> _resumeRecording() async {
    if (!_isPaused) return;
    try {
      await _recorder.resume();
    } catch (e) {
      setState(() => _errorMessage = 'Resume failed: $e');
      return;
    }
    _startTimer();
    setState(() => _isPaused = false);
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _isPaused = false;
    final result = await _recorder.stop();
    setState(() {
      _stage = _Stage.transcribing;
      _isPaused = false;
    });

    if (kIsWeb && result != null && result.isNotEmpty) {
      // Web: result is a blob: URL — fetch bytes from it
      try {
        final response = await http.get(Uri.parse(result));
        _audioBytes = response.bodyBytes;
        _audioPath = null;
      } catch (e) {
        setState(() {
          _errorMessage = 'Failed to process audio: $e';
          _stage = _Stage.idle;
        });
        return;
      }
    } else {
      _audioPath = result;
      _audioBytes = null;
    }

    await _transcribeAudio();
  }

  // ── Whisper transcription ─────────────────────────────────────────────────

  Future<void> _transcribeAudio() async {
    Uint8List? bytes;

    if (kIsWeb) {
      bytes = _audioBytes;
    } else if (_audioPath != null && _audioPath!.isNotEmpty) {
      try {
        bytes = await File(_audioPath!).readAsBytes();
      } catch (e) {
        setState(() {
          _errorMessage = 'Could not read audio: $e';
          _stage = _Stage.idle;
        });
        return;
      }
    }

    if (bytes == null || bytes.isEmpty) {
      setState(() {
        _errorMessage = 'No audio recorded.';
        _stage = _Stage.idle;
      });
      return;
    }

    try {
      final langCode = Get.find<SettingsController>().resolvedLanguageCode;
      final transcript =
          await AiService.transcribeAudio(bytes, languageCode: langCode);
      _transcriptController.text = transcript;
      setState(() => _stage = _Stage.transcribed);
    } catch (e) {
      setState(() {
        _errorMessage = 'Transcription failed: $e';
        _stage = _Stage.idle;
      });
    } finally {
      // Clean up temp file on mobile
      if (!kIsWeb && _audioPath != null && _audioPath!.isNotEmpty) {
        try {
          File(_audioPath!).deleteSync();
        } catch (_) {}
      }
      _audioBytes = null;
    }
  }

  // ── Save transcript only ──────────────────────────────────────────────────

  Future<void> _saveTranscript() async {
    final text = _transcriptController.text.trim();
    if (text.isEmpty) {
      Get.snackbar('snackbar.error'.tr, 'Transcript is empty.');
      return;
    }
    setState(() => _stage = _Stage.summarizing);
    try {
      final linkedId = _healthController.activeVisitPrepId.value;
      await _healthController.saveConsultationTranscript(
        text,
        linkedVisitPrepId: linkedId,
      );
      await _healthController.archiveActiveVisitPrep();
      _healthController.clearVisitNotes();
      Get.off(() => const ConsultationHistoryScreen());
    } catch (e) {
      Get.snackbar('snackbar.error'.tr, 'Failed to save: $e');
      setState(() => _stage = _Stage.transcribed);
    }
  }

  // ── Nemotron summarisation ────────────────────────────────────────────────

  Future<void> _summarize() async {
    final text = _transcriptController.text.trim();
    if (text.isEmpty) {
      Get.snackbar('Error', 'Transcript is empty.');
      return;
    }

    setState(() => _stage = _Stage.summarizing);

    try {
      final targetLanguage =
          Get.find<SettingsController>().resolvedLanguageName;
      final result = await AiService.summarizeConsultation(
        text,
        patient: _healthController.patient.value,
        reason: _healthController.visitTitle.value,
        questions: _healthController.visitQuestions.toList(),
        targetLanguage: targetLanguage,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final linkedId = _healthController.activeVisitPrepId.value;
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('consultations')
            .add({
          'doctorName': 'record.doctor'.tr,
          'date': DateTime.now().toIso8601String().split('T')[0],
          'timestamp': FieldValue.serverTimestamp(),
          'transcript': text,
          'briefSummary': result['brief_actionable'] ?? '',
          'detailedSummary': result['detailed_personalized'] ?? '',
          'reason': _healthController.visitTitle.value,
          'questions': _healthController.visitQuestions.toList(),
          if (linkedId != null) 'linkedVisitPrepId': linkedId,
        });

        await _healthController.fetchConsultations();
        await _healthController.archiveActiveVisitPrep();
        _healthController.clearVisitNotes();
      }

      if (_healthController.consultations.isNotEmpty) {
        Get.off(() => ConsultationDetailScreen(
              consultation: _healthController.consultations.first,
              index: 0,
            ));
      } else {
        Get.back();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save summary: $e');
      setState(() => _stage = _Stage.transcribed);
    }
  }

  // ── Questions reminder panel ──────────────────────────────────────────────

  Widget _buildQuestionsPanel() {
    return Obx(() {
      final questions = _healthController.visitQuestions
          .where((q) => q.trim().isNotEmpty)
          .toList();
      if (questions.isEmpty) return const SizedBox.shrink();

      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 24),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF0FDF4),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF86EFAC)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.checklist_rounded,
                    color: Color(0xFF16A34A), size: 20),
                SizedBox(width: 8),
                Text(
                  'Remember to ask:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF15803D),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...questions.asMap().entries.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${e.key + 1}. ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF16A34A),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          e.value,
                          style: const TextStyle(
                              fontSize: 16, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      );
    });
  }

  // ── UI helpers ────────────────────────────────────────────────────────────

  String get _timerLabel {
    final m = _recordSeconds ~/ 60;
    final s = _recordSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('Record Consultation',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    switch (_stage) {
      case _Stage.idle:
        return _buildIdle();
      case _Stage.recording:
        return _buildRecording();
      case _Stage.transcribing:
        return _buildSpinner(
          icon: Icons.graphic_eq_rounded,
          iconColor: const Color(0xFF6366F1),
          title: 'Transcribing Audio…',
          subtitle: 'Whisper AI is converting your recording to text',
        );
      case _Stage.transcribed:
        return _buildTranscribed();
      case _Stage.summarizing:
        return _buildSpinner(
          icon: Icons.auto_awesome_rounded,
          iconColor: Colors.green,
          title: 'Generating Summary…',
          subtitle: 'AI is creating a personalised summary of your visit',
        );
    }
  }

  // ── idle ──────────────────────────────────────────────────────────────────
  Widget _buildIdle() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page header
          const Text('Start Recording',
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 6),
          const Text(
            'Record your consultation and get an AI-generated summary.',
            style: TextStyle(fontSize: 15, color: Color(0xFF64748B), height: 1.4),
          ),
          const SizedBox(height: 28),

          // Privacy notice card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFBFDBFE)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.privacy_tip_rounded,
                    size: 20, color: Color(0xFF1D4ED8)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Privacy Notice',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1D4ED8))),
                      const SizedBox(height: 4),
                      Text(
                        'record.consent_reminder'.tr,
                        style: const TextStyle(
                            fontSize: 13.5,
                            color: Color(0xFF1D4ED8),
                            height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          _buildQuestionsPanel(),

          if (_errorMessage.isNotEmpty) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_errorMessage,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 14)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 40),
          Center(
            child: Column(
              children: [
                FloatingActionButton.large(
                  heroTag: 'start',
                  onPressed: _startRecording,
                  backgroundColor: const Color(0xFF0066CC),
                  elevation: 4,
                  child:
                      const Icon(Icons.mic, color: Colors.white, size: 38),
                ),
                const SizedBox(height: 12),
                const Text('Tap to start recording',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF475569))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── recording ─────────────────────────────────────────────────────────────
  Widget _buildRecording() {
    final isPaused = _isPaused;
    final badgeColor = isPaused ? Colors.orange : Colors.red;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Status badge
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.08),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: badgeColor.withOpacity(0.35)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: badgeColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Text(
                  isPaused ? 'PAUSED' : 'RECORDING',
                  style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.8),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Timer
          Text(_timerLabel,
              style: const TextStyle(
                  fontSize: 56,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                  letterSpacing: 2)),
          const SizedBox(height: 8),
          Text(
            isPaused
                ? 'Recording paused — tap Resume to continue'
                : 'Speak naturally — recording in progress',
            style: const TextStyle(
                fontSize: 14, color: Color(0xFF94A3B8)),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          if (!isPaused)
            const Text(
              'Your voice is being captured. You can pause at any time.',
              style: TextStyle(fontSize: 13, color: Color(0xFFCBD5E1)),
              textAlign: TextAlign.center,
            ),

          _buildQuestionsPanel(),
          const SizedBox(height: 36),

          // Controls row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Pause / Resume
              _buildRecordButton(
                heroTag: 'pause_resume',
                onPressed: isPaused ? _resumeRecording : _pauseRecording,
                backgroundColor:
                    isPaused ? const Color(0xFF16A34A) : Colors.orange,
                icon: isPaused
                    ? Icons.play_arrow_rounded
                    : Icons.pause_rounded,
                label: isPaused ? 'Resume' : 'Pause',
                size: 64,
                iconSize: 30,
              ),
              const SizedBox(width: 44),
              // Stop — larger, centred visually
              _buildRecordButton(
                heroTag: 'stop',
                onPressed: _stopRecording,
                backgroundColor: Colors.red,
                icon: Icons.stop_rounded,
                label: 'Stop & Process',
                size: 76,
                iconSize: 36,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Tap Stop to finish and transcribe your recording',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRecordButton({
    required String heroTag,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required IconData icon,
    required String label,
    required double size,
    required double iconSize,
  }) {
    return Column(
      children: [
        SizedBox(
          width: size,
          height: size,
          child: FloatingActionButton(
            heroTag: heroTag,
            onPressed: onPressed,
            backgroundColor: backgroundColor,
            elevation: 3,
            shape: const CircleBorder(),
            child: Icon(icon, color: Colors.white, size: iconSize),
          ),
        ),
        const SizedBox(height: 10),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B))),
      ],
    );
  }

  // ── spinner ───────────────────────────────────────────────────────────────
  Widget _buildSpinner({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 38),
            ),
            const SizedBox(height: 24),
            Text(title,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 14, color: Color(0xFF94A3B8), height: 1.4),
                textAlign: TextAlign.center),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }

  // ── transcribed ───────────────────────────────────────────────────────────
  Widget _buildTranscribed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Success header banner ──────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          decoration: const BoxDecoration(
            color: Color(0xFFF0FDF4),
            border: Border(
              bottom: BorderSide(color: Color(0xFFBBF7D0)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFF16A34A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Recording Complete',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF15803D))),
                    const SizedBox(height: 3),
                    const Text(
                      'Your consultation has been transcribed successfully.',
                      style: TextStyle(
                          fontSize: 13.5,
                          color: Color(0xFF16A34A),
                          height: 1.4),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _stage = _Stage.idle),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF64748B),
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Re-record',
                    style: TextStyle(fontSize: 13)),
              ),
            ],
          ),
        ),

        // ── Transcript section ─────────────────────────────────────────────
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.subject_rounded,
                          size: 18, color: Color(0xFF475569)),
                    ),
                    const SizedBox(width: 10),
                    const Text('Your Transcript',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B))),
                    const Spacer(),
                    const Text('Tap to edit',
                        style: TextStyle(
                            fontSize: 12, color: Color(0xFF94A3B8))),
                  ],
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _transcriptController,
                      maxLines: null,
                      expands: true,
                      style: const TextStyle(
                          fontSize: 15,
                          height: 1.65,
                          color: Color(0xFF334155)),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Transcript will appear here…',
                        hintStyle:
                            TextStyle(color: Color(0xFFCBD5E1)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // ── Action buttons ─────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
                top: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('What would you like to do?',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                      letterSpacing: 0.3)),
              const SizedBox(height: 12),

              // Primary: AI Summarize
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                  label: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('record.btn.summarize'.tr,
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold)),
                      const Text(
                        'Get a structured AI summary of your visit',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.normal,
                            color: Color(0xFFBBF7D0)),
                      ),
                    ],
                  ),
                  onPressed: _summarize,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    alignment: Alignment.centerLeft,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Secondary: Save transcript only
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.save_alt_rounded, size: 20),
                  label: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('record.btn.save_transcript'.tr,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                      const Text(
                        'Save the raw transcript without a summary',
                        style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                  onPressed: _saveTranscript,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF475569),
                    side: const BorderSide(color: Color(0xFFCBD5E1)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 14),
                    alignment: Alignment.centerLeft,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
