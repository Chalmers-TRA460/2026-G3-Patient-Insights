import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final HealthController controller = Get.find<HealthController>();

  late TextEditingController _heightController;
  late TextEditingController _weightController;
  late TextEditingController _bloodTypeController;
  late TextEditingController _bpController;
  late TextEditingController _glucoseController;

  @override
  void initState() {
    super.initState();
    final p = controller.patient.value;
    _heightController =
        TextEditingController(text: p?.height.toString() ?? '');
    _weightController =
        TextEditingController(text: p?.weight.toString() ?? '');
    _bloodTypeController =
        TextEditingController(text: p?.bloodType ?? '');
    _bpController =
        TextEditingController(text: p?.vitals['bp'] ?? '');
    _glucoseController =
        TextEditingController(text: p?.vitals['glucose'] ?? '');
  }

  Future<void> _save() async {
    Map<String, dynamic> data = {
      'height': double.tryParse(_heightController.text) ?? 0,
      'weight': double.tryParse(_weightController.text) ?? 0,
      'bloodType': _bloodTypeController.text,
      'vitals': {
        ...controller.patient.value?.vitals ?? {},
        'bp': _bpController.text,
        'glucose': _glucoseController.text,
      }
    };

    await controller.updatePatientData(data);
    Get.back();
    Get.snackbar('snackbar.success'.tr, 'edit.success'.tr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('edit.title'.tr)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildField('edit.height'.tr, _heightController,
                TextInputType.number),
            _buildField('edit.weight'.tr, _weightController,
                TextInputType.number),
            _buildField('edit.blood_type'.tr, _bloodTypeController,
                TextInputType.text),
            const Divider(height: 40),
            Text('edit.vitals'.tr,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            _buildField('edit.bp'.tr, _bpController,
                TextInputType.text),
            _buildField('edit.glucose'.tr, _glucoseController,
                TextInputType.number),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                child: Text('edit.save'.tr),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      TextInputType type) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: ctrl,
        keyboardType: type,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 18),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15)),
        ),
        style: const TextStyle(fontSize: 18),
      ),
    );
  }
}
