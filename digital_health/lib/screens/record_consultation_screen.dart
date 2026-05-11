import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../controllers/health_controller.dart';
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
  String? _audioPath;
  String _errorMessage = '';

  Timer? _timer;
  int _recordSeconds = 0;

  @override
  void dispose() {
    _recorder.dispose();
    _transcriptController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // ── Recording ─────────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      setState(() => _errorMessage = 'Microphone permission denied.');
      return;
    }

    final dir = await getTemporaryDirectory();
    _audioPath =
        '${dir.path}/consultation_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,
        sampleRate: 16000,
      ),
      path: _audioPath!,
    );

    _recordSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _recordSeconds++);
    });

    setState(() {
      _stage = _Stage.recording;
      _errorMessage = '';
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    _audioPath = await _recorder.stop();
    setState(() => _stage = _Stage.transcribing);
    await _transcribeAudio();
  }

  // ── Whisper transcription ─────────────────────────────────────────────────

  Future<void> _transcribeAudio() async {
    if (_audioPath == null) return;
    try {
      final transcript = await AiService.transcribeAudio(_audioPath!);
      _transcriptController.text = transcript;
      setState(() => _stage = _Stage.transcribed);
    } catch (e) {
      setState(() {
        _errorMessage = 'Transcription failed: $e';
        _stage = _Stage.idle;
      });
    } finally {
      try {
        File(_audioPath!).deleteSync();
      } catch (_) {}
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
      await _healthController.saveConsultationTranscript(text);
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
      final summary = await AiService.summarizeConsultation(
        text,
        patient: _healthController.patient.value,
        duration: _healthController.duration.value,
        symptomTrend: _healthController.symptomTrend.value,
        visitGoals: _healthController.visitGoals.toList(),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('consultations')
            .add({
          'doctorName': 'record.doctor'.tr,
          'date': DateTime.now().toIso8601String().split('T')[0],
          'timestamp': FieldValue.serverTimestamp(),
          'transcript': text,
          'summary': summary,
          'duration': _healthController.duration.value,
          'symptomTrend': _healthController.symptomTrend.value,
          'visitGoals': _healthController.visitGoals.toList(),
        });

        await _healthController.fetchConsultations();
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

  // ── UI helpers ────────────────────────────────────────────────────────────

  String get _timerLabel {
    final m = _recordSeconds ~/ 60;
    final s = _recordSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Record Consultation')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    switch (_stage) {
      case _Stage.idle:
        return _buildIdle();
      case _Stage.recording:
        return _buildRecording();
      case _Stage.transcribing:
        return _buildSpinner('Transcribing with Whisper…');
      case _Stage.transcribed:
        return _buildTranscribed();
      case _Stage.summarizing:
        return _buildSpinner('AI is summarising your visit…');
    }
  }

  // idle ─────────────────────────────────────────────────────────────────────
  Widget _buildIdle() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.mic_none_rounded, size: 80, color: Colors.blueGrey),
        const SizedBox(height: 24),
        const Text('Tap to start recording',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Record your consultation, then Whisper will transcribe it\nand the AI will summarise it for you.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, color: Colors.grey),
        ),
        if (_errorMessage.isNotEmpty) ...[
          const SizedBox(height: 20),
          Text(_errorMessage,
              style: const TextStyle(color: Colors.red, fontSize: 14),
              textAlign: TextAlign.center),
        ],
        const SizedBox(height: 40),
        FloatingActionButton.large(
          heroTag: 'start',
          onPressed: _startRecording,
          backgroundColor: Colors.blue,
          child: const Icon(Icons.mic, color: Colors.white, size: 36),
        ),
      ],
    );
  }

  // recording ────────────────────────────────────────────────────────────────
  Widget _buildRecording() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.red.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
              ),
              const SizedBox(width: 10),
              const Text('RECORDING',
                  style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(_timerLabel,
            style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Speak naturally — recording continuously',
            style: TextStyle(fontSize: 15, color: Colors.grey)),
        const SizedBox(height: 48),
        FloatingActionButton.large(
          heroTag: 'stop',
          onPressed: _stopRecording,
          backgroundColor: Colors.red,
          child: const Icon(Icons.stop_rounded, color: Colors.white, size: 36),
        ),
        const SizedBox(height: 16),
        const Text('Tap to stop',
            style: TextStyle(fontSize: 14, color: Colors.grey)),
      ],
    );
  }

  // spinner ──────────────────────────────────────────────────────────────────
  Widget _buildSpinner(String label) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(label,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  // transcribed ──────────────────────────────────────────────────────────────
  Widget _buildTranscribed() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.green, size: 22),
            const SizedBox(width: 8),
            const Text('Transcript ready',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() => _stage = _Stage.idle),
              child: const Text('Re-record'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text('Review and edit if needed, then tap Summarise.',
            style: TextStyle(fontSize: 13, color: Colors.grey)),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.withOpacity(0.2)),
            ),
            child: TextField(
              controller: _transcriptController,
              maxLines: null,
              expands: true,
              style: const TextStyle(fontSize: 16, height: 1.6),
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'Transcript will appear here…',
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.auto_awesome_rounded),
            label: Text('record.btn.summarize'.tr,
                style: const TextStyle(fontSize: 18)),
            onPressed: _summarize,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.save_alt_rounded),
            label: Text('record.btn.save_transcript'.tr,
                style: const TextStyle(fontSize: 16)),
            onPressed: _saveTranscript,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blueGrey,
              side: const BorderSide(color: Colors.blueGrey),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}
