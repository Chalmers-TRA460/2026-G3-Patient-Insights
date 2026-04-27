import 'package:get/get.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/patient_model.dart';

class HealthController extends GetxController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Rxn<Patient> patient = Rxn<Patient>();
  RxList<Map<String, dynamic>> consultations =
      <Map<String, dynamic>>[].obs;
  RxList<String> symptoms = <String>[].obs;
  RxList<String> questionsForDoctor = <String>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchPatientData();
    fetchConsultations();
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
      await _firestore.collection('users').doc(user.uid).update(data);
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

  void addSymptom(String s) {
    if (s.isNotEmpty && !symptoms.contains(s)) symptoms.add(s);
  }

  void removeSymptom(String s) => symptoms.remove(s);

  void addQuestion(String q) {
    if (q.isNotEmpty && !questionsForDoctor.contains(q))
      questionsForDoctor.add(q);
  }

  void removeQuestion(String q) => questionsForDoctor.remove(q);
}
