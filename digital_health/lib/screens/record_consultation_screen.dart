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
  String _wordsSpoken = "";
  bool _isListening = false;
  bool _isSummarizing = false;

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  void _initSpeech() async {
    try {
      var status = await Permission.microphone.request();
      if (status.isDenied) {
        setState(() => _status = "Microphone permission denied.");
        return;
      }

      _hasSpeech = await _speechToText.initialize(
        onError: (error) => setState(() => _status = "Error: ${error.errorMsg}"),
        onStatus: (status) => setState(() => _status = "Status: $status"),
      );
      if (!_hasSpeech) {
        _status = "Speech not available on this device.";
      } else {
        _status = "Ready to record";
      }
    } catch (e) {
      _status = "Failed to init: $e";
    }
    setState(() {});
  }

  void _startListening() async {
    if (!_hasSpeech) {
      Get.snackbar('Error', 'Microphone not initialized. Check permissions.');
      return;
    }
    await _speechToText.listen(
      onResult: (result) {
        setState(() {
          _wordsSpoken = result.recognizedWords;
          _status = "Listening...";
        });
      },
    );
    setState(() {
      _isListening = true;
    });
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() {
      _isListening = false;
    });
  }

  Future<void> _finishAndSummarize() async {
    if (_wordsSpoken.isEmpty) {
      Get.snackbar('Error', 'No speech detected to summarize.');
      return;
    }

    setState(() {
      _isSummarizing = true;
    });

    try {
      final summary = await AiService.summarizeConsultation(
        _wordsSpoken,
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
          'transcript': _wordsSpoken,
          'summary': summary,
          'symptoms': _healthController.symptoms.toList(),
          'questions': _healthController.questionsForDoctor.toList(),
        });
        
        await _healthController.fetchConsultations();
        
        // Clear symptoms/questions after visit
        _healthController.symptoms.clear();
        _healthController.questionsForDoctor.clear();

        Get.back();
        Get.snackbar('Success', 'Visit summary saved to history!');
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to save summary: $e');
    } finally {
      setState(() {
        _isSummarizing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Record Visit')),
      body: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Text(
              'Recording the conversation helps the AI summarize your visit later.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(_status, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.blue.withOpacity(0.1)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _wordsSpoken.isEmpty ? 'Tap the microphone and start speaking...' : _wordsSpoken,
                    style: TextStyle(fontSize: 20, color: _wordsSpoken.isEmpty ? Colors.grey : Colors.black),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            if (_isSummarizing)
              const Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('AI is summarizing your visit...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  FloatingActionButton.large(
                    onPressed: _isListening ? _stopListening : _startListening,
                    backgroundColor: _isListening ? Colors.red : Colors.blue,
                    child: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white),
                  ),
                  if (_wordsSpoken.isNotEmpty && !_isListening)
                    ElevatedButton(
                      onPressed: _finishAndSummarize,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
                      ),
                      child: const Text('Finish & Summarize'),
                    ),
                ],
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
