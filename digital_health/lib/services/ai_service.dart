import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/patient_model.dart';

class AiService {
  static String get _openRouterKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';
  static const String _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  static String get _groqKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _whisperUrl =
      'https://api.groq.com/openai/v1/audio/transcriptions';

  // ── 1. Whisper transcription ──────────────────────────────────────────────
  // Sends the recorded M4A file to Groq Whisper-large-v3 and returns text.
  static Future<String> transcribeAudio(String filePath,
      {String languageCode = 'en'}) async {
    final file = File(filePath);
    if (!file.existsSync()) throw Exception('Audio file not found: $filePath');

    final request = http.MultipartRequest('POST', Uri.parse(_whisperUrl))
      ..headers['Authorization'] = 'Bearer $_groqKey'
      ..fields['model'] = 'whisper-large-v3'
      ..fields['language'] = languageCode
      ..fields['response_format'] = 'text'
      ..files.add(await http.MultipartFile.fromPath('file', filePath));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) return body.trim();
    throw Exception('Whisper error ${streamed.statusCode}: $body');
  }

  // ── 2. Consultation summarisation ────────────────────────────────────────
  // Transcript + patient profile → dual-level summary (brief + detailed).
  // Returns a map with keys 'brief_actionable' and 'detailed_personalized'.
  static Future<Map<String, String>> summarizeConsultation(
    String transcript, {
    Patient? patient,
    String reason = '',
    List<String> questions = const [],
    String targetLanguage = 'English',
  }) async {
    final patientContext = _buildPatientContext(patient);

    final cleanQuestions =
        questions.map((q) => q.trim()).where((q) => q.isNotEmpty).toList();
    final preVisit = [
      if (reason.isNotEmpty) 'Reason for the visit: $reason',
      if (cleanQuestions.isNotEmpty)
        'Patient\'s questions:\n${cleanQuestions.asMap().entries.map((e) => '${e.key + 1}. ${e.value}').join('\n')}',
    ].join('\n');

    final prompt = '''
You are a medical communication assistant. A patient just finished a doctor's appointment.

Return ONLY a valid JSON object — no markdown, no code fences, no explanation — with exactly these two keys:

{
  "brief_actionable": "...",
  "detailed_personalized": "..."
}

brief_actionable: A scannable bullet list using • bullets containing ONLY:
1. Medication changes (new, changed, or stopped medications with doses)
2. Next steps (follow-up appointments, tests, referrals, actions to take at home)
Readable in under 10 seconds. No explanations or summaries. If there are no changes or next steps, write "• No changes or follow-up needed."

detailed_personalized: A warm, plain-language full summary in $targetLanguage using "you" and "your". Explain medical terms in brackets. Structure with these four sections:
1. What the doctor found
2. Changes to medications or treatment
3. Next steps and follow-up
4. Answers to the patient's questions

$patientContext
${preVisit.isNotEmpty ? 'Pre-visit notes:\n$preVisit\n' : ''}
Consultation transcript:
$transcript
''';

    final raw = await _callNemotron(prompt);
    try {
      final cleaned = raw
          .trim()
          .replaceAll(RegExp(r'^```json?\s*', multiLine: true), '')
          .replaceAll(RegExp(r'```\s*$', multiLine: true), '')
          .trim();
      final decoded = jsonDecode(cleaned) as Map<String, dynamic>;
      return {
        'brief_actionable': (decoded['brief_actionable'] as String? ?? '').trim(),
        'detailed_personalized': (decoded['detailed_personalized'] as String? ?? '').trim(),
      };
    } catch (_) {
      return {'brief_actionable': '', 'detailed_personalized': raw.trim()};
    }
  }

  // ── 3. AI health Q&A ─────────────────────────────────────────────────────
  static Future<String> askAi(String question, Patient? patient) async {
    final patientContext = _buildPatientContext(patient);

    final prompt = '''
You are a compassionate AI Health Companion helping a patient understand their health.
Use the patient context below to give safe, clear, and reassuring answers.
If anything sounds like a medical emergency, tell them to call 112 (Sweden) or 911 immediately.
Use simple language. Explain any medical terms you use.

$patientContext

Patient question: $question
''';

    return _callNemotron(prompt);
  }

  // ── 4. Pre-visit summary ─────────────────────────────────────────────────
  // Takes the patient's reason and a list of questions; returns a short,
  // plain-language confirmation paragraph (1–2 sentences).
  static Future<String> summarizeVisitPrep({
    required String reason,
    List<String> questions = const [],
    String targetLanguage = 'English',
  }) async {
    final cleanQuestions =
        questions.map((q) => q.trim()).where((q) => q.isNotEmpty).toList();

    final qBlock = cleanQuestions.isEmpty
        ? '(none)'
        : cleanQuestions
            .asMap()
            .entries
            .map((e) => '${e.key + 1}. ${e.value}')
            .join('\n');

    final prompt = '''
A patient prepared notes before a doctor's visit.

Reason for the visit:
$reason

Questions the patient plans to ask:
$qBlock

Write 1–2 short, plain sentences in $targetLanguage so the patient can confirm it sounds right.
Use "you" and "your". No medical jargon. Be precise and reassuring.
''';

    return _callNemotron(prompt);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static String _buildPatientContext(Patient? p) {
    if (p == null) return '';
    final meds = p.medications
        .map((m) => [m['name'], m['dosage']].where((s) => s != null && s!.isNotEmpty).join(' '))
        .where((s) => s.isNotEmpty)
        .join(', ');
    return '''
Patient profile:
- Name: ${p.name}
- Age: ${p.age > 0 ? '${p.age} years' : 'unknown'}
- Blood type: ${p.bloodType}
- Height / Weight: ${p.height > 0 ? '${p.height} cm' : '?'} / ${p.weight > 0 ? '${p.weight} kg' : '?'}
- BMI: ${p.bmi > 0 ? '${p.bmi.toStringAsFixed(1)} (${p.bmiStatus})' : 'unknown'}
- Medical conditions: ${p.conditions.isNotEmpty ? p.conditions.join(', ') : 'none recorded'}
- Current medications: ${meds.isNotEmpty ? meds : 'none recorded'}
- Vitals: ${p.vitals.isNotEmpty ? p.vitals.entries.map((e) => '${e.key}: ${e.value}').join(', ') : 'none recorded'}
''';
  }

  static Future<String> _callNemotron(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_openRouterUrl),
        headers: {
          'Authorization': 'Bearer $_openRouterKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://patientinsights.chalmers.se',
          'X-Title': 'Patient Insights',
        },
        body: jsonEncode({
          'model': 'nvidia/nemotron-3-super-120b-a12b:free',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] as String;
      }
      return 'Could not generate response (Error ${response.statusCode}).';
    } catch (e) {
      return 'Connection error. Please check your internet and try again.';
    }
  }
}
