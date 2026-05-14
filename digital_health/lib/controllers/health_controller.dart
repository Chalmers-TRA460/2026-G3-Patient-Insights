import 'dart:async';
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
  RxBool isRegeneratingDetailed = false.obs;

  // ── Family / caregiver view ───────────────────────────────────────────────

  // Non-null only when viewing a family member's profile.
  Rxn<Patient> currentViewedPatient = Rxn<Patient>();
  RxList<Patient> accessiblePatients = <Patient>[].obs;
  RxBool isFetchingAccessible = false.obs;

  // Returns the family member being viewed, or the primary user's own record.
  Patient? get effectivePatient => currentViewedPatient.value ?? patient.value;
  bool get isViewingOther => currentViewedPatient.value != null;

  // ── Visit preparations ───────────────────────────────────────────────────────

  RxList<Map<String, dynamic>> visitPreps = <Map<String, dynamic>>[].obs;
  RxString visitTitle = ''.obs;
  RxList<String> visitQuestions = <String>[].obs;
  RxString visitPrepSummary = ''.obs;
  RxBool isGeneratingSummary = false.obs;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  StreamSubscription<User?>? _authSub;

  @override
  void onInit() {
    super.onInit();
    // Listen to auth state so data is always scoped to the current user.
    // This also fixes stale data appearing for a new account after sign-out:
    // the listener fires immediately with the current user on first init,
    // and again whenever the signed-in user changes.
    _authSub = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  @override
  void onClose() {
    _authSub?.cancel();
    super.onClose();
  }

  void _onAuthStateChanged(User? user) {
    // Clear every reactive field so no previous user's data leaks through.
    patient.value = null;
    consultations.clear();
    visitPreps.clear();
    currentViewedPatient.value = null;
    accessiblePatients.clear();

    if (user != null) {
      fetchPatientData();
      fetchConsultations();
      fetchVisitPreps();
    }
  }

  // ── Patient data ─────────────────────────────────────────────────────────────

  Future<void> fetchPatientData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        patient.value = Patient.fromFirestore(doc.data()!, user.uid);
        // Always write the canonical lowercase email from Firebase Auth on
        // every login. This ensures the field is present and correct for
        // all users — including those with legacy documents that pre-date
        // the email field — so caregiver search queries work immediately.
        final authEmail = (user.email ?? '').toLowerCase();
        if (authEmail.isNotEmpty) {
          _firestore
              .collection('users')
              .doc(user.uid)
              .set({'email': authEmail}, SetOptions(merge: true))
              .catchError((_) {});
        }
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

  // Save a patient-edited brief summary and regenerate the detailed version
  // from the corrected brief + original transcript. The previous brief is
  // pushed onto a rolling briefHistory (cap = 3) so the patient can revert
  // an accidental edit.
  //
  // The brief + history are persisted BEFORE the regeneration call so the
  // patient sees their edit reflected immediately while the spinner runs on
  // the detailed version — otherwise the UI would keep showing the old brief
  // for the duration of the AI call.
  Future<void> editBriefSummary(int index, String newBrief) async {
    if (index < 0 || index >= consultations.length) return;
    final visit = consultations[index];
    final previousBrief = (visit['briefSummary'] as String? ?? '').trim();
    final transcript = visit['transcript'] as String? ?? '';

    final history = List<Map<String, dynamic>>.from(
        (visit['briefHistory'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e)));
    if (previousBrief.isNotEmpty) {
      history.insert(0, {
        'text': previousBrief,
        'timestamp': DateTime.now().toIso8601String(),
      });
      while (history.length > 3) {
        history.removeLast();
      }
    }

    // Optimistic save: brief + history land in Firestore/local state right
    // away. The spinner takes over the detailed area until regen completes.
    isRegeneratingDetailed.value = true;
    await updateConsultation(index, {
      'briefSummary': newBrief,
      'briefHistory': history,
    });

    try {
      final targetLanguage =
          Get.find<SettingsController>().resolvedLanguageName;
      final newDetailed = await AiService.regenerateDetailedFromBrief(
        editedBrief: newBrief,
        transcript: transcript,
        patient: patient.value,
        targetLanguage: targetLanguage,
      );

      await updateConsultation(index, {
        'detailedSummary': newDetailed,
      });
    } catch (e) {
      Get.snackbar('snackbar.error'.tr, 'Failed to update summary: $e');
    } finally {
      isRegeneratingDetailed.value = false;
    }
  }

  // Restore a prior brief from history. The currently-visible brief is pushed
  // onto history first (so the restore can itself be undone), then the chosen
  // version becomes the new brief and the detailed summary is regenerated.
  Future<void> restoreBriefVersion(int consultationIndex, int historyIndex) async {
    if (consultationIndex < 0 || consultationIndex >= consultations.length) {
      return;
    }
    final visit = consultations[consultationIndex];
    final history = List<Map<String, dynamic>>.from(
        (visit['briefHistory'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e)));
    if (historyIndex < 0 || historyIndex >= history.length) return;
    final restored = (history[historyIndex]['text'] as String? ?? '').trim();
    if (restored.isEmpty) return;
    await editBriefSummary(consultationIndex, restored);
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

  // ── Family access ────────────────────────────────────────────────────────────

  Future<void> fetchAccessiblePatients() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final email = (user.email ?? '').trim().toLowerCase();
    if (email.isEmpty) return;
    isFetchingAccessible.value = true;
    try {
      final snapshot = await _firestore
          .collection('users')
          .where('authorizedCaregivers', arrayContains: email)
          .get();
      accessiblePatients.value = snapshot.docs
          .map((doc) => Patient.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('fetchAccessiblePatients error: $e');
    } finally {
      isFetchingAccessible.value = false;
    }
  }

  void switchToPatient(Patient p) {
    currentViewedPatient.value = p;
  }

  void returnToMyProfile() {
    currentViewedPatient.value = null;
  }

  // ── Caregiver management ─────────────────────────────────────────────────────

  Future<void> addCaregiver(String email) async {
    final user = _auth.currentUser;
    if (user == null) return;
    final normalized = email.trim().toLowerCase();

    // Local duplicate check — avoids a network round-trip for obvious cases.
    final current = patient.value?.authorizedCaregivers ?? [];
    if (current.contains(normalized)) {
      Get.snackbar('caregiver.already_added_title'.tr,
          'caregiver.already_added_body'.tr);
      return;
    }

    try {
      // Verify the email belongs to a registered user before granting access.
      final matches = await _firestore
          .collection('users')
          .where('email', isEqualTo: normalized)
          .limit(1)
          .get();

      if (matches.docs.isEmpty) {
        Get.snackbar('snackbar.error'.tr, 'caregiver.not_found'.tr,
            snackPosition: SnackPosition.BOTTOM);
        return;
      }

      await _firestore.collection('users').doc(user.uid).update({
        'authorizedCaregivers': FieldValue.arrayUnion([normalized]),
      });
      await fetchPatientData();
      Get.snackbar(
        'caregiver.success_title'.tr,
        'caregiver.success_body'.trParams({'email': normalized}),
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      Get.snackbar('snackbar.error'.tr, 'caregiver.error_add'.tr);
    }
  }

  Future<void> removeCaregiver(String email) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).update({
        'authorizedCaregivers': FieldValue.arrayRemove([email]),
      });
      await fetchPatientData();
    } catch (e) {
      Get.snackbar('snackbar.error'.tr, 'caregiver.error_remove'.tr);
    }
  }

  // ── Profile completeness ─────────────────────────────────────────────────────

  double get completionPercentage {
    if (effectivePatient == null) return 0;
    int filled = 0;
    final p = effectivePatient!;
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
    final p = effectivePatient;
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
