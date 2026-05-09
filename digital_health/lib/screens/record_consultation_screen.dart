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

enum _Stage { idle, recording, transcribing, transcribed, summarizing }

class RecordConsultationScreen extends StatefulWidget {
  const RecordConsultationScreen({super.key});

  @override
  State<RecordConsultationScreen> createState() =>
      _RecordConsultationScreenState();
}

class _RecordConsultationScreenState extends State<RecordConsultationScreen> {
<<<<<<< HEAD
  final _recorder = AudioRecorder();
  final _healthController = Get.find<HealthController>();
  final _transcriptController = TextEditingController();

  _Stage _stage = _Stage.idle;
  String? _audioPath;
  String _errorMessage = '';

  // Recording timer
  Timer? _timer;
  int _recordSeconds = 0;
=======
  final SpeechToText _speechToText = SpeechToText();
  final HealthController _healthController = Get.find<HealthController>();

  String _status = '';
  bool _hasSpeech = false;
  bool _isListening = false;
  bool _isSummarizing = false;
  bool _wantsToListen = false;
  double _soundLevel = 0.0;
  String _currentLocaleId = '';

  String _allWords = '';
  String _currentSessionWords = '';

  bool _isManualMode = false;
  final TextEditingController _manualController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _status = 'record.ready'.tr;
    _initSpeech();
  }
>>>>>>> 9c63e522f0a378ab15b44edda15be9df8e7ef287

  @override
  void dispose() {
    _recorder.dispose();
    _transcriptController.dispose();
    _timer?.cancel();
    super.dispose();
  }

<<<<<<< HEAD
  // ── Recording ─────────────────────────────────────────────────────────────

  Future<void> _startRecording() async {
    final hasPermission = await _recorder.hasPermission();
    if (!hasPermission) {
      setState(() => _errorMessage = 'Microphone permission denied.');
=======
  void _initSpeech() async {
    try {
      var status = await Permission.microphone.request();
      if (status.isDenied) {
        setState(() => _status = 'record.mic_denied'.tr);
        return;
      }

      _hasSpeech = await _speechToText.initialize(
        onError: (error) {
          if (!error.permanent && error.errorMsg != 'error_busy' && _wantsToListen && mounted) {
            _startListenSession();
          }
        },
        onStatus: (status) {
          if (status == 'done' && _wantsToListen && mounted && !_speechToText.isListening) {
            _startListenSession();
          }
        },
      );

      if (_hasSpeech) {
        var systemLocale = await _speechToText.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
        _status = 'record.ready'.tr;
      } else {
        _status = 'record.no_speech'.tr;
      }
    } catch (e) {
      _status = 'Failed to init: $e';
    }
    setState(() {});
  }

  void _toggleManualMode() {
    setState(() {
      _isManualMode = !_isManualMode;
      if (_isManualMode) {
        _manualController.text = _allWords;
        if (_wantsToListen) _stopListening();
      }
    });
  }

  void _startListenSession() async {
    if (!_hasSpeech || !_wantsToListen || !mounted) return;
    if (_speechToText.isListening) return;

    try {
      await _speechToText.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() => _currentSessionWords = result.recognizedWords);

          if (result.finalResult && _wantsToListen) {
            final chunk = result.recognizedWords;
            if (chunk.isNotEmpty) {
              setState(() {
                _allWords = _allWords.isEmpty ? chunk : '$_allWords $chunk';
                _currentSessionWords = '';
              });
            }
            _startListenSession();
          }
        },
        onSoundLevelChange: (level) => setState(() => _soundLevel = level),
        listenFor: const Duration(seconds: 59),
        pauseFor: const Duration(seconds: 30),
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
        localeId: _currentLocaleId,
      );
      setState(() => _isListening = true);
    } catch (e) {
      if (_wantsToListen && mounted) _startListenSession();
    }
  }

  void _startListening() {
    if (!_hasSpeech) {
      Get.snackbar('snackbar.error'.tr, 'record.mic_error'.tr);
      return;
    }
    setState(() {
      _wantsToListen = true;
      _currentSessionWords = '';
    });
    _startListenSession();
  }

  void _stopListening() async {
    _wantsToListen = false;
    _speechToText.stop();

    if (_currentSessionWords.isNotEmpty) {
      _allWords = _allWords.isEmpty
          ? _currentSessionWords
          : '$_allWords $_currentSessionWords';
      _currentSessionWords = '';
    }

    setState(() {
      _isListening = false;
      _status = _allWords.isEmpty ? 'record.ready'.tr : 'record.saved'.tr;
    });
  }

  String get _displayText {
    if (_currentSessionWords.isNotEmpty && _allWords.isNotEmpty) {
      return '$_allWords $_currentSessionWords';
    }
    if (_currentSessionWords.isNotEmpty) return _currentSessionWords;
    return _allWords;
  }

  Future<void> _finishAndSummarize() async {
    if (_wantsToListen) _stopListening();

    final textToSummarize =
        _isManualMode ? _manualController.text : _displayText;

    if (textToSummarize.trim().isEmpty) {
      Get.snackbar('snackbar.error'.tr, 'record.no_text'.tr);
>>>>>>> 9c63e522f0a378ab15b44edda15be9df8e7ef287
      return;
    }

    final dir = await getTemporaryDirectory();
    _audioPath =
        '${dir.path}/consultation_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 64000,   // 64 kbps — ~28 MB/hour, well under Whisper's 25 MB limit
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
      // Clean up temp audio file
      try { File(_audioPath!).deleteSync(); } catch (_) {}
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
<<<<<<< HEAD
=======
      final visitReasonLabels = kVisitTaxonomy
          .where((cat) =>
              _healthController.selectedCategories.contains(cat.id))
          .map((cat) => cat.label)
          .toList();

>>>>>>> 9c63e522f0a378ab15b44edda15be9df8e7ef287
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
<<<<<<< HEAD
=======

        Get.back();
        Get.snackbar('snackbar.success'.tr, 'record.success'.tr);
>>>>>>> 9c63e522f0a378ab15b44edda15be9df8e7ef287
      }

      Get.back();
      Get.snackbar('Saved', 'Visit summary saved to history!');
    } catch (e) {
<<<<<<< HEAD
      Get.snackbar('Error', 'Failed to save summary: $e');
      setState(() => _stage = _Stage.transcribed);
=======
      Get.snackbar('snackbar.error'.tr, 'Failed to save summary: $e');
    } finally {
      setState(() => _isSummarizing = false);
>>>>>>> 9c63e522f0a378ab15b44edda15be9df8e7ef287
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
<<<<<<< HEAD
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Record Consultation')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _buildBody(),
=======
    final currentText =
        _isManualMode ? _manualController.text : _displayText;

    return Scaffold(
      appBar: AppBar(title: Text('record.title'.tr)),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ActionChip(
                  label: Text(_isManualMode
                      ? 'record.switch_mic'.tr
                      : 'record.switch_typing'.tr),
                  avatar: Icon(
                      _isManualMode ? Icons.mic : Icons.keyboard,
                      size: 16),
                  onPressed: _toggleManualMode,
                ),
              ],
            ),
            const SizedBox(height: 10),

            if (!_isManualMode) ...[
              if (_wantsToListen)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Text('record.recording'.tr,
                          style: const TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2)),
                    ],
                  ),
                )
              else
                Text(_status,
                    style: const TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
            ],
            const SizedBox(height: 15),

            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _wantsToListen
                        ? Colors.red.withOpacity(0.3)
                        : Colors.blue.withOpacity(0.1),
                    width: _wantsToListen ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 15,
                        spreadRadius: 2)
                  ],
                ),
                child: _isManualMode
                    ? TextField(
                        controller: _manualController,
                        maxLines: null,
                        expands: true,
                        decoration: InputDecoration(
                          hintText: 'record.type_hint'.tr,
                          border: InputBorder.none,
                        ),
                        style:
                            const TextStyle(fontSize: 18, height: 1.5),
                      )
                    : SingleChildScrollView(
                        child: Text(
                          _displayText.isEmpty
                              ? 'record.tap_mic'.tr
                              : _displayText,
                          style: TextStyle(
                            fontSize: 18,
                            color: _displayText.isEmpty
                                ? Colors.grey
                                : Colors.black,
                            height: 1.5,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            if (_isSummarizing)
              Column(
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 10),
                  Text('record.summarizing'.tr,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              )
            else
              Column(
                children: [
                  if (!_isManualMode)
                    FloatingActionButton.large(
                      heroTag: 'mic',
                      onPressed: _wantsToListen
                          ? _stopListening
                          : _startListening,
                      backgroundColor:
                          _wantsToListen ? Colors.red : Colors.blue,
                      child: Icon(
                          _wantsToListen ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: 36),
                    ),
                  const SizedBox(height: 15),
                  if (currentText.trim().isNotEmpty && !_wantsToListen)
                    ElevatedButton.icon(
                      onPressed: _finishAndSummarize,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: Text('record.btn.summarize'.tr,
                          style: const TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 25, vertical: 15),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 20),
          ],
        ),
>>>>>>> 9c63e522f0a378ab15b44edda15be9df8e7ef287
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
                width: 12, height: 12,
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
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()])),
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
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
            label: const Text('Summarise with AI',
                style: TextStyle(fontSize: 18)),
            onPressed: _summarize,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}
