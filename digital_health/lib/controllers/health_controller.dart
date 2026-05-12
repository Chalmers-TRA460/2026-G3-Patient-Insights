import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/patient_model.dart';
import '../services/ai_service.dart';
import 'settings_controller.dart';

class HealthController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Patient ─────────────────────────────────────────────────────────────────

  Rxn<Patient> patient = Rxn<Patient>();
  RxList<Map<String, dynamic>> consultations = <Map<String, dynamic>>[].obs;
  RxBool isLoading = false.obs;
  RxBool isSummarizingVisit = false.obs;

  // ── Visit preparations ───────────────────────────────────────────────────────

  RxList<Map<String, dynamic>> visitPreps = <Map<String, dynamic>>[].obs;
  RxString visitTitle = ''.obs;
  RxList<String> visitQuestions = <String>[].obs;
  RxString visitPrepSummary = ''.obs;
  RxBool isGeneratingSummary = false.obs;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void onInit() {
    super.onInit();
    fetchPatientData();
    fetchConsultations();
    fetchVisitPreps();
  }

  // ── Patient data ─────────────────────────────────────────────────────────────

  Future<void> fetchPatientData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        patient.value = Patient.fromFirestore(doc.data()!, user.uid);
      } else {
        final newPatient = Patient(
          id: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? '',
          profileImage: user.photoURL,
        );
        await _firestore.collection('users').doc(user.uid).set(newPatient.toFirestore());
        patient.value = newPatient;
      }
    } catch (e) {
      print('Error fetching patient: $e');
    }
  }

  Future<void> fetchConsultations() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('consultations')
          .orderBy('timestamp', descending: true)
          .get();
      consultations.value = snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      print('Error fetching consultations: $e');
    }
  }

  Future<void> saveConsultationTranscript(String transcript) async {
    final user = _auth.currentUser;
    if (user == null) return;
    await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('consultations')
        .add({
      'doctorName': 'record.doctor'.tr,
      'date': DateTime.now().toIso8601String().split('T')[0],
      'timestamp': FieldValue.serverTimestamp(),
      'transcript': transcript,
      'summary': '',
    });
    await fetchConsultations();
  }

  Future<void> generateSummaryForVisit(int index) async {
    final transcript = consultations[index]['transcript'] as String? ?? '';
    if (transcript.isEmpty) return;
    isSummarizingVisit.value = true;
    try {
      final targetLanguage =
          Get.find<SettingsController>().resolvedLanguageName;
      final result = await AiService.summarizeConsultation(
        transcript,
        patient: patient.value,
        targetLanguage: targetLanguage,
      );
      await updateConsultation(index, {
        'briefSummary': result['brief_actionable'] ?? '',
        'detailedSummary': result['detailed_personalized'] ?? '',
      });
    } catch (e) {
      Get.snackbar('snackbar.error'.tr, 'Failed to generate summary: $e');
    } finally {
      isSummarizingVisit.value = false;
    }
  }

  Future<void> updateConsultation(int index, Map<String, dynamic> fields) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final docId = consultations[index]['id'] as String?;
    if (docId == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('consultations')
          .doc(docId)
          .update(fields);
      final updated = List<Map<String, dynamic>>.from(consultations);
      updated[index] = {...updated[index], ...fields};
      consultations.value = updated;
    } catch (e) {
      Get.snackbar('Error', 'Failed to update consultation');
    }
  }

  Future<void> updatePatientData(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).set(data, SetOptions(merge: true));
      await fetchPatientData();
    } catch (e) {
      Get.snackbar('Error', 'Failed to update health profile');
    }
  }

  // ── Profile completeness ─────────────────────────────────────────────────────

  double get completionPercentage {
    if (patient.value == null) return 0;
    int filled = 0;
    final p = patient.value!;
    if (p.dob != null) filled++;
    if (p.bloodType != 'Unknown') filled++;
    if (p.height > 0) filled++;
    if (p.weight > 0) filled++;
    if (p.conditions.isNotEmpty) filled++;
    if (p.medications.isNotEmpty) filled++;
    if (p.vitals.isNotEmpty) filled++;
    if (p.emergencyContact != null) filled++;
    return (filled / 8) * 100;
  }

  bool get canAccessHealthProfile => completionPercentage > 0;

  void promptProfileUpdate() {
    Get.snackbar(
      'Update your profile first',
      'Please complete your medical record before opening My Health Profile.',
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: const Color(0xFF1E293B),
      colorText: Colors.white,
    );
  }

  List<String> get missingFields {
    final p = patient.value;
    if (p == null) return [];
    final missing = <String>[];
    if (p.dob == null) missing.add('Date of Birth');
    if (p.bloodType == 'Unknown') missing.add('Blood Type');
    if (p.height <= 0) missing.add('Height');
    if (p.weight <= 0) missing.add('Weight');
    if (p.conditions.isEmpty) missing.add('Medical Conditions');
    if (p.medications.isEmpty) missing.add('Current Medications');
    if (p.vitals.isEmpty) missing.add('Recent Vitals');
    if (p.emergencyContact == null) missing.add('Emergency Contact');
    return missing;
  }

  // ── Visit prep – form state helpers ──────────────────────────────────────

  void clearVisitNotes() {
    visitTitle.value = '';
    visitQuestions.clear();
    visitPrepSummary.value = '';
  }

  // ── Visit prep – load / save ──────────────────────────────────────────────────

  Future<void> fetchVisitPreps() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      final raw = doc.data()?['visitPreps'];
      if (raw != null) {
        visitPreps.value = List<Map<String, dynamic>>.from(raw);
        if (visitPreps.isNotEmpty) {
          visitPrepSummary.value = visitPreps.first['summary'] ?? '';
        }
      }
    } catch (e) {
      print('fetchVisitPreps error: $e');
    }
  }

  // Populates controller state from a saved record so the edit screen can
  // pre-fill the form. Older record formats only contributed a title, so for
  // those we keep the title and let the user re-enter their questions.
  void loadVisitPrepForEdit(int index) {
    final prep = visitPreps[index];
    visitTitle.value = prep['title'] ?? '';
    visitPrepSummary.value = prep['summary'] ?? '';
    visitQuestions.assignAll(List<String>.from(prep['questions'] ?? const []));
  }

  // Builds a FHIR R4 QuestionnaireResponse as a plain Map. Captures the
  // reason for the visit and the list of patient questions.
  Map<String, dynamic> _buildFhirResponseJson(String uid) {
    final items = <Map<String, dynamic>>[];

    if (visitTitle.value.trim().isNotEmpty) {
      items.add({
        'linkId': 'reason',
        'text': 'Why are you going to the doctor?',
        'answer': [
          {'valueString': visitTitle.value.trim()}
        ],
      });
    }

    final qs = visitQuestions
        .map((q) => q.trim())
        .where((q) => q.isNotEmpty)
        .toList();
    if (qs.isNotEmpty) {
      items.add({
        'linkId': 'questions',
        'text': 'What questions do you want to ask?',
        'answer': qs.map((q) => {'valueString': q}).toList(),
      });
    }

    return {
      'resourceType': 'QuestionnaireResponse',
      'status': 'completed',
      'subject': {'reference': 'Patient/$uid'},
      if (items.isNotEmpty) 'item': items,
    };
  }

  Future<void> submitQuestionnaire({int? editIndex}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final cleanQuestions = visitQuestions
        .map((q) => q.trim())
        .where((q) => q.isNotEmpty)
        .toList();
    visitQuestions.assignAll(cleanQuestions);

    isGeneratingSummary.value = true;
    try {
      final targetLanguage =
          Get.find<SettingsController>().resolvedLanguageName;

      final summary = await AiService.summarizeVisitPrep(
        reason: visitTitle.value.trim(),
        questions: cleanQuestions,
        targetLanguage: targetLanguage,
      );

      visitPrepSummary.value = summary;

      final fhirResponse = _buildFhirResponseJson(user.uid);

      final entry = <String, dynamic>{
        'title': visitTitle.value.trim(),
        'date': editIndex != null
            ? visitPreps[editIndex]['date']
            : DateTime.now().toIso8601String().split('T')[0],
        'questions': cleanQuestions,
        'fhirResponse': fhirResponse,
        'summary': summary,
      };

      final updated = List<Map<String, dynamic>>.from(
          visitPreps.map((e) => Map<String, dynamic>.from(e)));
      if (editIndex != null) {
        updated[editIndex] = entry;
      } else {
        updated.insert(0, entry);
      }
      visitPreps.value = updated;

      _firestore
          .collection('users')
          .doc(user.uid)
          .set({'visitPreps': updated}, SetOptions(merge: true))
          .catchError((e) => print('visitPrep save failed: $e'));
    } catch (e) {
      print('submitQuestionnaire error: $e');
      Get.snackbar('Error', e.toString());
    } finally {
      isGeneratingSummary.value = false;
    }
  }

  void deleteVisitPrep(int index) {
    final updated = List<Map<String, dynamic>>.from(
        visitPreps.map((e) => Map<String, dynamic>.from(e)));
    updated.removeAt(index);
    visitPreps.value = updated;
    visitPrepSummary.value =
        updated.isNotEmpty ? (updated.first['summary'] ?? '') : '';

    final user = _auth.currentUser;
    if (user == null) return;
    _firestore
        .collection('users')
        .doc(user.uid)
        .set({'visitPreps': updated}, SetOptions(merge: true))
        .catchError((e) => print('deleteVisitPrep error: $e'));
  }
}
