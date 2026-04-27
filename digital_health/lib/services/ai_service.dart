import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/patient_model.dart';

class AiService {
  static const String _apiKey =
      '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';
  static const String _url =
      'https://openrouter.ai/api/v1/chat/completions';

  static Future<String> askAi(String question, Patient? patient) async {
    String context = '';
    if (patient != null) {
      context = '''
Patient Context:
- Name: ${patient.name}
- Age: ${patient.age}
- Blood Type: ${patient.bloodType}
- Conditions: ${patient.conditions.join(', ')}
- Medications: ${patient.medications.map((m) => "${m['name']} ${m['dosage']}").join(', ')}
- Vitals: ${patient.vitals.entries.map((e) => "${e.key}: ${e.value}").join(', ')}
      ''';
    }

    final prompt = '''
You are a compassionate AI Health Companion for an elderly patient.
Use the patient context below to give safe, clear, and reassuring answers.
If anything sounds like a medical emergency, tell them to call 911 immediately.
Use simple English. Avoid medical jargon.

$context

Patient Question: $question
''';

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://healthapp.com',
          'X-Title': 'Elderly Health Companion',
        },
        body: jsonEncode({
          'model': 'nvidia/nemotron-3-super-120b-a12b:free',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      print('AI Response Code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "I'm having trouble connecting (Error ${response.statusCode}). Please check your API key and try again.";
      }
    } catch (e) {
      return "Connection error. Please check your internet and try again.";
    }
  }

  static Future<String> summarizeConsultation(
    String transcript,
    List<String> symptoms,
    List<String> questions,
  ) async {
    final prompt = '''
Please summarize this doctor-patient consultation in clear, simple, and reassuring language for an elderly patient.

Focus on:
1. What the doctor found
2. Any changes to medications or treatments
3. Next steps and follow-up appointments
4. Answers to the patient's concerns

Symptoms the patient reported: ${symptoms.join(', ')}
Questions the patient had: ${questions.join(', ')}

Full Consultation Transcript:
$transcript
''';

    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
          'HTTP-Referer': 'https://healthapp.com',
          'X-Title': 'Elderly Health Companion',
        },
        body: jsonEncode({
          'model': 'nvidia/nemotron-3-super-120b-a12b:free',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      print('AI Summary Response Code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      }
      return 'Could not generate summary.';
    } catch (e) {
      return 'Error generating summary.';
    }
  }
}
