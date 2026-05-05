import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/patient_model.dart';
import '../services/ai_service.dart';

class HealthController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Rxn<Patient> patient = Rxn<Patient>();
  RxList<Map<String, dynamic>> consultations = <Map<String, dynamic>>[].obs;
  RxList<Map<String, dynamic>> visitPreps = <Map<String, dynamic>>[].obs;
  RxString visitTitle = ''.obs;
  RxList<String> visitReasons = <String>[].obs;
  RxString duration = ''.obs;
  RxString symptomTrend = ''.obs;
  RxList<String> visitGoals = <String>[].obs;
  RxString visitPrepSummary = ''.obs;
  RxBool isGeneratingSummary = false.obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPatientData();
    fetchConsultations();
    fetchVisitPreps();
  }

  Future<void> fetchPatientData() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final doc =
          await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        patient.value = Patient.fromFirestore(doc.data()!, user.uid);
      } else {
        final newPatient = Patient(
          id: user.uid,
          name: user.displayName ?? 'User',
          email: user.email ?? '',
          profileImage: user.photoURL,
        );
        await _firestore
            .collection('users')
            .doc(user.uid)
            .set(newPatient.toFirestore());
        patient.value = newPatient;
      }
    } catch (e) {
      print('Error fetching patient: $e');
    }
  }

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
      consultations.value = snapshot.docs.map((doc) => {
            'id': doc.id,
            ...doc.data(),
          }).toList();
    } catch (e) {
      print('Error fetching consultations: $e');
    }
  }

  Future<void> updatePatientData(Map<String, dynamic> data) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(data, SetOptions(merge: true));
      await fetchPatientData();
    } catch (e) {
      Get.snackbar('Error', 'Failed to update health profile');
    }
  }

  double get completionPercentage {
    if (patient.value == null) return 0;
    int total = 8;
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
    return (filled / total) * 100;
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
    List<String> missing = [];
    final p = patient.value;
    if (p == null) return [];
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

  void toggleVisitReason(String reason) {
    if (visitReasons.contains(reason)) {
      visitReasons.remove(reason);
    } else {
      visitReasons.add(reason);
    }
  }

  void toggleVisitGoal(String goal) {
    if (visitGoals.contains(goal)) {
      visitGoals.remove(goal);
    } else {
      visitGoals.add(goal);
    }
  }

  Future<void> submitQuestionnaire({int? editIndex}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    isGeneratingSummary.value = true;
    try {
      final summary = await AiService.summarizeVisitPrep(
        visitReasons: visitReasons,
        duration: duration.value,
        symptomTrend: symptomTrend.value,
        visitGoals: visitGoals,
      );

      visitPrepSummary.value = summary;

      final entry = {
        'title': visitTitle.value,
        'date': editIndex != null
            ? visitPreps[editIndex]['date']
            : DateTime.now().toIso8601String().split('T')[0],
        'visitReasons': visitReasons.toList(),
        'duration': duration.value,
        'symptomTrend': symptomTrend.value,
        'visitGoals': visitGoals.toList(),
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

      _firestore.collection('users').doc(user.uid).set(
        {'visitPreps': updated},
        SetOptions(merge: true),
      ).catchError((e) => print('visitPrep save failed: $e'));
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
    _firestore.collection('users').doc(user.uid).set(
      {'visitPreps': updated},
      SetOptions(merge: true),
    ).catchError((e) => print('deleteVisitPrep error: $e'));
  }

  void clearVisitNotes() {
    visitTitle.value = '';
    visitReasons.clear();
    duration.value = '';
    symptomTrend.value = '';
    visitGoals.clear();
    visitPrepSummary.value = '';
  }
}
