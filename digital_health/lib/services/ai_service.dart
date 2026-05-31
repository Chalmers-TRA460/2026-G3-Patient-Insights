import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/patient_model.dart';
import '../models/quiz_question_model.dart';

class AiService {
  static String get _openRouterKey => dotenv.env['OPENROUTER_API_KEY'] ?? '';
  static const String _openRouterUrl =
      'https://openrouter.ai/api/v1/chat/completions';

  static String get _groqKey => dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _whisperUrl =
      'https://api.groq.com/openai/v1/audio/transcriptions';

  // ── 1. Whisper transcription ──────────────────────────────────────────────
  // Accepts raw audio bytes — works on both mobile and web.
  static Future<String> transcribeAudio(Uint8List audioBytes,
      {String languageCode = 'en'}) async {
    if (audioBytes.isEmpty) throw Exception('Audio data is empty');

    final request = http.MultipartRequest('POST', Uri.parse(_whisperUrl))
      ..headers['Authorization'] = 'Bearer $_groqKey'
      ..fields['model'] = 'whisper-large-v3'
      ..fields['language'] = languageCode
      ..fields['response_format'] = 'text'
      ..files.add(http.MultipartFile.fromBytes(
        'file',
        audioBytes,
        filename: 'audio.m4a',
      ));

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode == 200) return body.trim();
    throw Exception('Whisper error ${streamed.statusCode}: $body');
  }

  // ── 2. Consultation summarisation ────────────────────────────────────────
  // Transcript + patient profile → dual-level summary (brief + detailed) plus
  // a concise visit title. Returns a map with keys 'brief_actionable',
  // 'detailed_personalized', and 'visit_title'.
  static Future<Map<String, String>> summarizeConsultation(
    String transcript, {
    Patient? patient,
    String reason = '',
    List<String> questions = const [],
    String? preparationTitle,
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

    final cleanPrepTitle = preparationTitle?.trim();
    final hasPrepTitle = cleanPrepTitle != null && cleanPrepTitle.isNotEmpty;

    final prompt = '''
You are a medical transcription assistant. Summarise ONLY what was explicitly said in the consultation transcript below.

STRICT ANTI-HALLUCINATION RULES (mandatory — violations are harmful):
- Do NOT add any information that is not explicitly present in the transcript.
- Do NOT infer, assume, or insert standard medical knowledge, typical treatments, or general health advice.
- Do NOT explain medical terms unless the doctor explained them in the transcript.
- If a topic was not discussed during the consultation, write "Not discussed." — do not fill the gap.
- Use the patient profile only to correctly interpret names/terms already in the transcript, never to add new facts.

Return ONLY a valid JSON object — no markdown, no code fences, no explanation — with exactly these three keys:

{
  "visit_title": "...",
  "brief_actionable": "...",
  "detailed_personalized": "..."
}

visit_title: A concise, patient-friendly, descriptive title for this visit in $targetLanguage.
- Maximum 4–5 words. No trailing punctuation. Use sentence case (capitalise only the first word and proper nouns).
- Describe the main reason for the visit or its primary outcome (e.g. "Annual checkup", "Back pain follow-up", "Migraine medication review").
- Do NOT include the patient's name, the date, or generic words like "Consultation" or "Visit" on their own.
- If a linked preparation name is provided below, take it into consideration when formulating the title — the title may build on or refine the preparation name, but should still reflect what actually happened in the transcript.

brief_actionable: A bullet list using • bullets. Include ONLY items explicitly stated in the transcript:
- Medications: ALL medications mentioned or prescribed during the visit, with the exact dose and frequency the doctor stated. Include new, changed, continued, and stopped medications.
- Lifestyle & self-care: any recommendations about exercise, diet, activity, rest, or things to do at home.
- Next steps: only follow-up appointments, tests, referrals, or actions the doctor explicitly mentioned.
- Warning signs: any symptoms the doctor said to watch for, or when to seek urgent care.
If nothing was stated for a category, omit that category entirely. If there is nothing to list, write "• Nothing specific mentioned."

detailed_personalized: A plain-language summary in $targetLanguage using "you" and "your".
Report ONLY what was said. Structure it as four sections with bold headings in $targetLanguage:
**1. What the doctor found**
**2. Changes to medications or treatment**
**3. Next steps and follow-up**
**4. Answers to your questions**

Formatting rules:
- Blank line after each heading and between sections.
- If nothing relevant was said for a section, write "Not discussed in this visit." under that heading.
- Do NOT join sections without blank lines.
- Translate headings into $targetLanguage but keep the 1.–4. numbering and ** markers.

$patientContext
${hasPrepTitle ? 'Linked preparation name (consider this when formulating the visit_title):\n$cleanPrepTitle\n' : ''}${preVisit.isNotEmpty ? 'Pre-visit notes (patient\'s own words — do not treat as medical facts):\n$preVisit\n' : ''}
Consultation transcript (the only source of truth):
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
        'visit_title': (decoded['visit_title'] as String? ?? '').trim(),
        'brief_actionable': (decoded['brief_actionable'] as String? ?? '').trim(),
        'detailed_personalized': (decoded['detailed_personalized'] as String? ?? '').trim(),
      };
    } catch (_) {
      return {
        'visit_title': '',
        'brief_actionable': '',
        'detailed_personalized': raw.trim(),
      };
    }
  }

  // ── 2b. Regenerate detailed summary from an edited brief ─────────────────
  // After the patient (with the doctor) corrects the brief actionable summary,
  // the detailed narrative needs to be rewritten so it agrees with the
  // verified brief. Both the corrected brief AND the original transcript are
  // used as inputs — the brief is treated as ground truth for facts; the
  // transcript provides context for the narrative.
  static Future<String> regenerateDetailedFromBrief({
    required String editedBrief,
    required String transcript,
    Patient? patient,
    String targetLanguage = 'English',
  }) async {
    final patientContext = _buildPatientContext(patient);

    final prompt = '''
You are a medical transcription assistant. Rewrite the detailed summary using ONLY the facts in the corrected brief and the transcript.

STRICT ANTI-HALLUCINATION RULES (mandatory):
- Do NOT add any information absent from both the corrected brief and the transcript.
- Do NOT add medical knowledge, typical treatments, or general advice.
- Do NOT explain medical terms unless the doctor explained them in the transcript.
- The corrected brief is the source of truth for facts. If the transcript conflicts, the brief wins.
- Use the transcript only for the doctor's own wording and reasoning around facts already in the brief.
- If a section topic is not covered by either source, write "Not discussed in this visit." under that heading.

Return ONLY the detailed summary text in $targetLanguage. No JSON, no code fences, no preamble.

Structure it as four sections with bold headings in $targetLanguage:
**1. What the doctor found**
**2. Changes to medications or treatment**
**3. Next steps and follow-up**
**4. Answers to your questions**

Formatting rules:
- Blank line after each heading and between sections.
- Translate headings into $targetLanguage, keep 1.–4. numbering and ** markers.

$patientContext

Corrected brief (source of truth for facts):
$editedBrief

Original consultation transcript (context for wording only):
$transcript
''';

    final raw = await _callNemotron(prompt);
    return raw.trim();
  }

  // ── 2c. Detect prepared questions the doctor did not address ─────────────
  // Given the consultation transcript and the patient's prepared questions
  // (from a linked preparation form), return the subset of questions that
  // were either never asked or were asked but received no clear answer.
  // The returned strings are exact copies of the originals — the caller
  // filters out anything the AI paraphrased.
  static Future<List<String>> findUnansweredQuestions({
    required String transcript,
    required List<String> preparedQuestions,
  }) async {
    final clean = preparedQuestions
        .map((q) => q.trim())
        .where((q) => q.isNotEmpty)
        .toList();
    if (clean.isEmpty || transcript.trim().isEmpty) return [];

    final numbered = clean
        .asMap()
        .entries
        .map((e) => '${e.key + 1}. ${e.value}')
        .join('\n');

    final prompt = '''
You are reviewing a doctor's consultation to identify which of the patient's prepared questions were NOT addressed.

Return ONLY a valid JSON array of strings — no markdown, no code fences, no explanation.
Each string must be one of the prepared questions copied EXACTLY (do not paraphrase, do not translate, do not renumber).

Include a question in the array ONLY if BOTH conditions hold:
1. The question was either never asked during the visit, OR was raised but the doctor gave no clear answer.
2. You are confident the topic was not addressed. When in doubt, leave it OUT — false positives are worse than false negatives.

If every prepared question was addressed, return an empty array [].

Patient's prepared questions:
$numbered

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
      final decoded = jsonDecode(cleaned) as List<dynamic>;
      final asked = clean.toSet();
      return decoded
          .whereType<String>()
          .map((s) => s.trim())
          .where(asked.contains)
          .toList();
    } catch (_) {
      return [];
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

  // ── 5. Knowledge-check quiz ───────────────────────────────────────────────
  // Transcript + patient profile → list of quiz questions (5 items).
  static Future<List<QuizQuestion>> generateVisitQuiz(
    String transcript, {
    Patient? patient,
    String targetLanguage = 'English',
  }) async {
    final patientContext = _buildPatientContext(patient);

    // Dynamically calculate the number of quiz questions based on transcript word count.
    // If the conversation is short (e.g. < 150 words), 2 questions are enough.
    // As length increases, scale the questions up to a maximum of 10.
    final words = transcript.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
    int numQuestions = 5; // default fallback
    if (words < 150) {
      numQuestions = 2;
    } else if (words < 300) {
      numQuestions = 3;
    } else if (words < 600) {
      numQuestions = 5;
    } else if (words < 1000) {
      numQuestions = 7;
    } else {
      numQuestions = 10;
    }

    final prompt = '''
You are a medical education assistant helping a patient check what they understood from their doctor's visit.

Return ONLY a valid JSON array — no markdown, no code fences, no explanation — containing exactly $numQuestions objects.

Each object must have exactly these five keys:
{
  "question": "...",
  "options": ["...", "...", "...", "..."],
  "correctIndex": 0,
  "explanation": "...",
  "notMentioned": false
}

STRICT GROUNDING RULE (mandatory):
For any question about medications, dosages, next steps, tests, or follow-up appointments, you MUST base the question ONLY on information explicitly spoken in the transcript. If a follow-up timeline, specific dose, or appointment date was not mentioned in the transcript, do NOT create a question about it and do NOT invent plausible-sounding details. Never substitute standard medical timelines or typical clinical practice for what was actually said.

LIFESTYLE FLEXIBILITY (limited exception):
You may generate 1 or 2 questions about general lifestyle recommendations (e.g., posture, hydration, rest, basic self-care) that are reasonable given the patient's inferred condition, even if those specific tips were not spoken in the transcript. When you do this, you MUST set "notMentioned": true for that question, and the explanation field MUST explicitly state: "This is general best-practice advice and was not specifically mentioned during your visit."

For every question that IS grounded in the transcript, set "notMentioned": false.

Additional rules:
- Each question must have exactly 4 options.
- correctIndex is the zero-based index of the correct option.
- IMPORTANT: vary the position of the correct option across questions — do not always put the correct answer first. Distribute correctIndex values across 0, 1, 2, and 3.
- explanation is 1–2 sentences in plain language.
- Do NOT ask about diagnoses or test results — only actionable items the patient must remember.
- Write all text in $targetLanguage.

$patientContext
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
      final decoded = jsonDecode(cleaned) as List<dynamic>;
      final parsed = decoded
          .whereType<Map<String, dynamic>>()
          .map(QuizQuestion.fromJson)
          .where((q) => q.question.isNotEmpty && q.options.length >= 2)
          .toList();
      return parsed.map(_shuffleOptions).toList();
    } catch (_) {
      return [];
    }
  }

  // Randomise the order of options so the correct answer isn't always at A.
  static QuizQuestion _shuffleOptions(QuizQuestion q) {
    if (q.options.length < 2) return q;
    final indices = List<int>.generate(q.options.length, (i) => i)
      ..shuffle(Random());
    final newOptions = indices.map((i) => q.options[i]).toList();
    final newCorrect = indices.indexOf(q.correctIndex);
    return q.copyWith(
      options: newOptions,
      correctIndex: newCorrect < 0 ? 0 : newCorrect,
    );
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
