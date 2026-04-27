import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';

class HealthProfileScreen extends StatelessWidget {
  const HealthProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final HealthController controller = Get.find<HealthController>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('My Health Profile'),
        actions: [
          TextButton(
            onPressed: () => Get.toNamed('/edit-profile'),
            child: const Text('Edit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Obx(() {
        final patient = controller.patient.value;
        if (patient == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with Profile Info
              Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                    child: Text(patient.name[0], style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor)),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(patient.name, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                        Text('Age: ${patient.age}  |  Blood: ${patient.bloodType}', style: const TextStyle(fontSize: 18, color: Colors.grey)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Vitals Summary Cards
              const Text('Recent Vital Signs', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildVitalCard('Blood Pressure', patient.vitals['bp'] ?? '120/80', 'mmHg', Icons.speed_rounded, Colors.blue),
                    _buildVitalCard('Heart Rate', patient.vitals['hr'] ?? '72', 'bpm', Icons.favorite_rounded, Colors.red),
                    _buildVitalCard('Glucose', patient.vitals['glucose'] ?? '98', 'mg/dL', Icons.water_drop_rounded, Colors.orange),
                    _buildVitalCard('Oxygen', patient.vitals['spo2'] ?? '98', '%', Icons.air_rounded, Colors.teal),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // BMI Section
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Body Mass Index (BMI)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('${patient.bmi.toStringAsFixed(1)} - ${patient.bmiStatus}', 
                            style: TextStyle(fontSize: 22, color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    const Icon(Icons.monitor_weight_rounded, size: 40, color: Colors.blueGrey),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              _buildSectionHeader('Medical Conditions'),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: patient.conditions.map((c) => Chip(
                  label: Text(c, style: const TextStyle(fontSize: 16)),
                  backgroundColor: Colors.blue.withOpacity(0.05),
                  side: BorderSide(color: Colors.blue.withOpacity(0.2)),
                )).toList(),
              ),

              const SizedBox(height: 30),

              _buildSectionHeader('Current Medications'),
              ...patient.medications.map((m) => ListTile(
                leading: const Icon(Icons.medication_rounded, color: Colors.purple),
                title: Text(m['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                subtitle: Text('${m['dosage']} - ${m['frequency']}', style: const TextStyle(fontSize: 16)),
              )),

              const SizedBox(height: 30),

              _buildSectionHeader('Emergency Contact'),
              if (patient.emergencyContact != null)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.red.withOpacity(0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.contact_phone_rounded, color: Colors.red, size: 30),
                      const SizedBox(width: 15),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(patient.emergencyContact!['name'] ?? '', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(patient.emergencyContact!['phone'] ?? '', style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 40),
              
              // Link to Visit History
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Get.toNamed('/history'),
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('View AI Visit Summaries'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildVitalCard(String label, String value, String unit, IconData icon, Color color) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const Spacer(),
          Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
    );
  }
}
