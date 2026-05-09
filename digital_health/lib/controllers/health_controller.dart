import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/patient_model.dart';
import '../models/questionnaire_model.dart';
import '../services/ai_service.dart';

class HealthController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ── Patient ─────────────────────────────────────────────────────────────────

  Rxn<Patient> patient = Rxn<Patient>();
  RxList<Map<String, dynamic>> consultations = <Map<String, dynamic>>[].obs;
  RxBool isLoading = false.obs;

  // ── Visit preparations ───────────────────────────────────────────────────────

  RxList<Map<String, dynamic>> visitPreps = <Map<String, dynamic>>[].obs;
  RxString visitTitle = ''.obs;
  RxString duration = ''.obs;
  RxString symptomTrend = ''.obs;
  RxList<String> visitGoals = <String>[].obs;
  RxString visitPrepSummary = ''.obs;
  RxBool isGeneratingSummary = false.obs;

  // Progressive-disclosure questionnaire state
  RxSet<String> selectedCategories = <String>{}.obs;
  RxSet<String> expandedCategories = <String>{}.obs;
  RxSet<String> selectedSubItems = <String>{}.obs;
  RxMap<String, String> itemNotes = <String, String>{}.obs;

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

  // ── Visit prep – category/sub-item state ─────────────────────────────────────

  void toggleCategory(String id) {
    if (selectedCategories.contains(id)) {
      selectedCategories.remove(id);
      expandedCategories.remove(id);
      itemNotes.remove(id);
      // Clear any sub-item state for this category.
      for (final cat in kVisitTaxonomy) {
        if (cat.id == id) {
          for (final sub in cat.subQuestions) {
            selectedSubItems.remove(sub.id);
            itemNotes.remove(sub.id);
          }
          break;
        }
      }
    } else {
      selectedCategories.add(id);
      expandedCategories.add(id); // auto-expand on first tick
    }
  }

  void toggleExpanded(String id) {
    if (expandedCategories.contains(id)) {
      expandedCategories.remove(id);
    } else {
      expandedCategories.add(id);
    }
  }

  void toggleSubItem(String id) {
    if (selectedSubItems.contains(id)) {
      selectedSubItems.remove(id);
    } else {
      selectedSubItems.add(id);
    }
  }

  void setNote(String id, String text) {
    if (text.isEmpty) {
      itemNotes.remove(id);
    } else {
      itemNotes[id] = text;
    }
  }

  void toggleVisitGoal(String goal) {
    if (visitGoals.contains(goal)) {
      visitGoals.remove(goal);
    } else {
      visitGoals.add(goal);
    }
  }

  void clearVisitNotes() {
    visitTitle.value = '';
    duration.value = '';
    symptomTrend.value = '';
    visitGoals.clear();
    visitPrepSummary.value = '';
    selectedCategories.clear();
    expandedCategories.clear();
    selectedSubItems.clear();
    itemNotes.clear();
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

  // Populates controller state from a saved record (supports both new and
  // legacy flat format) so the edit screen can pre-fill the form.
  void loadVisitPrepForEdit(int index) {
    final prep = visitPreps[index];
    visitTitle.value = prep['title'] ?? '';
    duration.value = prep['duration'] ?? '';
    symptomTrend.value = prep['symptomTrend'] ?? '';
    visitGoals.assignAll(List<String>.from(prep['visitGoals'] ?? []));
    visitPrepSummary.value = prep['summary'] ?? '';

    if (prep.containsKey('selectedCategories')) {
      // New progressive-disclosure format.
      selectedCategories
        ..clear()
        ..addAll(Set<String>.from(prep['selectedCategories'] ?? []));
      selectedSubItems
        ..clear()
        ..addAll(Set<String>.from(prep['selectedSubItems'] ?? []));
      itemNotes.assignAll(Map<String, String>.from(
          (prep['itemNotes'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), v.toString()))));
      expandedCategories
        ..clear()
        ..addAll(Set<String>.from(selectedCategories));
    } else {
      // Legacy flat format: map old reason labels to taxonomy IDs.
      final legacyReasons = List<String>.from(prep['visitReasons'] ?? []);
      final ids = legacyReasons
          .map((r) => kLegacyReasonToId[r])
          .whereType<String>()
          .toSet();
      selectedCategories
        ..clear()
        ..addAll(ids);
      expandedCategories
        ..clear()
        ..addAll(ids);
      selectedSubItems.clear();
      itemNotes.clear();
    }
  }

  // Builds a FHIR R4 QuestionnaireResponse as a plain Map so no fhir package
  // types are needed. The JSON structure is identical to what the typed API
  // would produce and is fully spec-compliant.
  Map<String, dynamic> _buildFhirResponseJson(String uid) {
    Map<String, dynamic> answer(String text) => {'valueString': text};

    Map<String, dynamic> item(String linkId, String text,
        {String? note, List<Map<String, dynamic>>? nested}) {
      return {
        'linkId': linkId,
        'text': text,
        if (note != null && note.isNotEmpty) 'answer': [answer(note)],
        if (nested != null && nested.isNotEmpty) 'item': nested,
      };
    }

    final items = <Map<String, dynamic>>[];

    for (final cat in kVisitTaxonomy) {
      if (!selectedCategories.contains(cat.id)) continue;

      final catNote = itemNotes[cat.id] ?? '';
      final nested = <Map<String, dynamic>>[];

      for (final sub in cat.subQuestions) {
        final subNote = itemNotes[sub.id] ?? '';
        if (!selectedSubItems.contains(sub.id) && subNote.isEmpty) continue;
        nested.add(item(sub.id, sub.label, note: subNote.isNotEmpty ? subNote : null));
      }

      items.add(item(cat.id, cat.label,
          note: catNote.isNotEmpty ? catNote : null,
          nested: nested.isEmpty ? null : nested));
    }

    if (duration.value.isNotEmpty) {
      items.add({
        'linkId': 'duration',
        'text': 'How long have you had this?',
        'answer': [answer(duration.value)],
      });
    }

    if (symptomTrend.value.isNotEmpty) {
      items.add({
        'linkId': 'symptomTrend',
        'text': 'Is it getting better or worse?',
        'answer': [answer(symptomTrend.value)],
      });
    }

    if (visitGoals.isNotEmpty) {
      items.add({
        'linkId': 'goals',
        'text': 'What do you want from this visit?',
        'answer': visitGoals.map(answer).toList(),
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

    isGeneratingSummary.value = true;
    try {
      // Build a human-readable context string for the AI prompt.
      final contextLines = <String>[];
      for (final cat in kVisitTaxonomy) {
        if (!selectedCategories.contains(cat.id)) continue;
        final catNote = itemNotes[cat.id] ?? '';
        var line = cat.label;
        if (catNote.isNotEmpty) line += ' — $catNote';
        final subLines = cat.subQuestions
            .where((s) =>
                selectedSubItems.contains(s.id) ||
                (itemNotes[s.id]?.isNotEmpty ?? false))
            .map((s) {
              final sNote = itemNotes[s.id] ?? '';
              return sNote.isNotEmpty ? '${s.label}: $sNote' : s.label;
            })
            .join('; ');
        if (subLines.isNotEmpty) line += ' ($subLines)';
        contextLines.add(line);
      }

      final summary = await AiService.summarizeVisitPrep(
        visitContext: contextLines.join('\n'),
        duration: duration.value,
        symptomTrend: symptomTrend.value,
        visitGoals: visitGoals.toList(),
      );

      visitPrepSummary.value = summary;

      final fhirResponse = _buildFhirResponseJson(user.uid);

      final entry = <String, dynamic>{
        'title': visitTitle.value,
        'date': editIndex != null
            ? visitPreps[editIndex]['date']
            : DateTime.now().toIso8601String().split('T')[0],
        // Raw editable state (used when re-opening for edit).
        'selectedCategories': selectedCategories.toList(),
        'selectedSubItems': selectedSubItems.toList(),
        'itemNotes': Map<String, String>.from(itemNotes),
        'duration': duration.value,
        'symptomTrend': symptomTrend.value,
        'visitGoals': visitGoals.toList(),
        // FHIR R4 QuestionnaireResponse.
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
