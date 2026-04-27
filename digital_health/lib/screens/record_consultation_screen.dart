import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/ai_service.dart';
import '../controllers/health_controller.dart';
import 'package:permission_handler/permission_handler.dart';

class RecordConsultationScreen extends StatefulWidget {
  const RecordConsultationScreen({super.key});

  @override
  State<RecordConsultationScreen> createState() => _RecordConsultationScreenState();
}

class _RecordConsultationScreenState extends State<RecordConsultationScreen> {
  final SpeechToText _speechToText = SpeechToText();
  final HealthController _healthController = Get.find<HealthController>();
  
  String _status = "Initializing...";
  bool _hasSpeech = false;
  bool _isListening = false;
  bool _isSummarizing = false;
  bool _wantsToListen = false; // tracks if user wants continuous listening
  double _soundLevel = 0.0;
  String _currentLocaleId = '';

  // KEY FIX: accumulate words across multiple listen sessions
  String _allWords = "";
  String _currentSessionWords = "";

  bool _isManualMode = false;
  final TextEditingController _manualController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  @override
  void dispose() {
    _manualController.dispose();
    if (_isListening) _speechToText.stop();
    super.dispose();
  }

  void _initSpeech() async {
    try {
      var status = await Permission.microphone.request();
      if (status.isDenied) {
        setState(() => _status = "Microphone permission denied.");
        return;
      }

      _hasSpeech = await _speechToText.initialize(
        onError: (error) {
          print("Speech error: ${error.errorMsg} permanent: ${error.permanent}");
          // If error is not permanent and user wants to listen, restart
          if (!error.permanent && _wantsToListen) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_wantsToListen && mounted) _startListenSession();
            });
          }
          setState(() => _status = "Restarting...");
        },
        onStatus: (status) {
          print("Speech status: $status");
          // KEY: when Android stops listening ("notListening" or "done"), 
          // auto-restart if user still wants to record
          if ((status == "notListening" || status == "done") && _wantsToListen && mounted) {
            Future.delayed(const Duration(milliseconds: 300), () {
              if (_wantsToListen && mounted) _startListenSession();
            });
          }
          setState(() => _status = "Status: $status");
        },
      );
      
      if (_hasSpeech) {
        var systemLocale = await _speechToText.systemLocale();
        _currentLocaleId = systemLocale?.localeId ?? '';
        _status = "Ready to record";
      } else {
        _status = "Speech not available on this device.";
      }
    } catch (e) {
      _status = "Failed to init: $e";
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

  // Start a single listen session (called repeatedly for continuous listening)
  void _startListenSession() async {
    if (!_hasSpeech || !_wantsToListen || !mounted) return;

    try {
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _currentSessionWords = result.recognizedWords;
            _status = "Listening... (speak naturally)";
          });
        },
        onSoundLevelChange: (level) {
          setState(() => _soundLevel = level);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        partialResults: true,
        cancelOnError: false,
        listenMode: ListenMode.dictation,
        localeId: _currentLocaleId,
      );
      setState(() => _isListening = true);
    } catch (e) {
      print("Listen error: $e");
      // Retry after a delay
      if (_wantsToListen && mounted) {
        Future.delayed(const Duration(seconds: 1), () {
          if (_wantsToListen && mounted) _startListenSession();
        });
      }
    }
  }

  // User presses the mic button to START continuous recording
  void _startListening() {
    if (!_hasSpeech) {
      Get.snackbar('Error', 'Microphone not initialized. Check permissions.');
      return;
    }
    setState(() {
      _wantsToListen = true;
      _currentSessionWords = "";
    });
    _startListenSession();
  }

  // User presses stop — save accumulated words
  void _stopListening() async {
    _wantsToListen = false;
    await _speechToText.stop();
    
    // Append the last session's words
    if (_currentSessionWords.isNotEmpty) {
      _allWords = _allWords.isEmpty 
          ? _currentSessionWords 
          : "$_allWords $_currentSessionWords";
      _currentSessionWords = "";
    }
    
    setState(() {
      _isListening = false;
      _status = _allWords.isEmpty ? "Ready to record" : "Recording saved. Tap Summarize or record more.";
    });
  }

  String get _displayText {
    if (_currentSessionWords.isNotEmpty && _allWords.isNotEmpty) {
      return "$_allWords $_currentSessionWords";
    }
    if (_currentSessionWords.isNotEmpty) return _currentSessionWords;
    return _allWords;
  }

  Future<void> _finishAndSummarize() async {
    // Make sure we capture any in-progress words
    if (_wantsToListen) _stopListening();
    
    final textToSummarize = _isManualMode ? _manualController.text : _displayText;

    if (textToSummarize.trim().isEmpty) {
      Get.snackbar('Error', 'No text or speech detected to summarize.');
      return;
    }

    setState(() => _isSummarizing = true);

    try {
      final summary = await AiService.summarizeConsultation(
        textToSummarize,
        _healthController.symptoms,
        _healthController.questionsForDoctor,
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('consultations')
            .add({
          'doctorName': 'Doctor Visit',
          'date': DateTime.now().toIso8601String().split('T')[0],
          'timestamp': FieldValue.serverTimestamp(),
          'transcript': textToSummarize,
          'summary': summary,
          'symptoms': _healthController.symptoms.toList(),
          'questions': _healthController.questionsForDoctor.toList(),
        });
        
        await _healthController.fetchConsultations();
        _healthController.symptoms.clear();
        _healthController.questionsForDoctor.clear();

        Get.back();
        Get.snackbar('Success', 'Visit summary saved to history!');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save summary: $e');
    } finally {
      setState(() => _isSummarizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentText = _isManualMode ? _manualController.text : _displayText;
    
    return Scaffold(
      appBar: AppBar(title: const Text('Record Visit')),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            // Mode toggle
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ActionChip(
                  label: Text(_isManualMode ? "Switch to Mic" : "Switch to Typing"),
                  avatar: Icon(_isManualMode ? Icons.mic : Icons.keyboard, size: 16),
                  onPressed: _toggleManualMode,
                ),
              ],
            ),
            const SizedBox(height: 10),
            
            // Status
            if (!_isManualMode) ...[
              if (_wantsToListen)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.red.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      const Text('RECORDING', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    ],
                  ),
                )
              else
                Text(_status, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14)),
            ],
            const SizedBox(height: 15),
            
            // Text display area
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _wantsToListen ? Colors.red.withOpacity(0.3) : Colors.blue.withOpacity(0.1),
                    width: _wantsToListen ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, spreadRadius: 2)
                  ],
                ),
                child: _isManualMode 
                  ? TextField(
                      controller: _manualController,
                      maxLines: null,
                      expands: true,
                      decoration: const InputDecoration(
                        hintText: "Type or paste your visit notes here...",
                        border: InputBorder.none,
                      ),
                      style: const TextStyle(fontSize: 18, height: 1.5),
                    )
                  : SingleChildScrollView(
                      child: Text(
                        _displayText.isEmpty ? 'Tap the microphone to start recording.\nSpeak naturally — the app will keep listening.' : _displayText,
                        style: TextStyle(
                          fontSize: 18, 
                          color: _displayText.isEmpty ? Colors.grey : Colors.black,
                          height: 1.5,
                        ),
                      ),
                    ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Action buttons
            if (_isSummarizing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('AI is summarizing...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              )
            else
              Column(
                children: [
                  // Mic button (only in mic mode)
                  if (!_isManualMode)
                    FloatingActionButton.large(
                      heroTag: 'mic',
                      onPressed: _wantsToListen ? _stopListening : _startListening,
                      backgroundColor: _wantsToListen ? Colors.red : Colors.blue,
                      child: Icon(_wantsToListen ? Icons.stop : Icons.mic, color: Colors.white, size: 36),
                    ),
                  const SizedBox(height: 15),
                  // Summarize button (always visible when there's text)
                  if (currentText.trim().isNotEmpty && !_wantsToListen)
                    ElevatedButton.icon(
                      onPressed: _finishAndSummarize,
                      icon: const Icon(Icons.auto_awesome_rounded),
                      label: const Text('Summarize Now', style: TextStyle(fontSize: 18)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                      ),
                    ),
                ],
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
