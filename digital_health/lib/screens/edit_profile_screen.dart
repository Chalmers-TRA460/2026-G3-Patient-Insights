import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final HealthController _ctrl = Get.find<HealthController>();
  final _formKey = GlobalKey<FormState>();

  DateTime? _dob;
  String _bloodType = 'A+';

  late TextEditingController _heightCtrl;
  late TextEditingController _weightCtrl;

  List<String> _conditions = [];
  final TextEditingController _conditionCtrl = TextEditingController();

  final List<Map<String, TextEditingController>> _medCtrls = [];

  late TextEditingController _emNameCtrl;
  late TextEditingController _emPhoneCtrl;

  static const _bloodTypes = [
    'A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Unknown'
  ];

  @override
  void initState() {
    super.initState();
    final p = _ctrl.patient.value;

    _heightCtrl = TextEditingController(
        text: (p?.height ?? 0) > 0 ? p!.height.toStringAsFixed(0) : '')
      ..addListener(() => setState(() {}));
    _weightCtrl = TextEditingController(
        text: (p?.weight ?? 0) > 0 ? p!.weight.toStringAsFixed(0) : '')
      ..addListener(() => setState(() {}));

    if (p?.bloodType != null && _bloodTypes.contains(p!.bloodType)) {
      _bloodType = p.bloodType;
    }

    _dob = p?.dob;

    _conditions = List<String>.from(p?.conditions ?? []);

    for (final med in (p?.medications ?? [])) {
      _medCtrls.add({
        'name': TextEditingController(text: med['name'] ?? ''),
        'dosage': TextEditingController(text: med['dosage'] ?? ''),
        'frequency': TextEditingController(text: med['frequency'] ?? ''),
      });
    }

    _emNameCtrl = TextEditingController(
        text: p?.emergencyContact?['name'] ?? '');
    _emPhoneCtrl = TextEditingController(
        text: p?.emergencyContact?['phone'] ?? '');
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _conditionCtrl.dispose();
    _emNameCtrl.dispose();
    _emPhoneCtrl.dispose();
    for (final m in _medCtrls) {
      m['name']!.dispose();
      m['dosage']!.dispose();
      m['frequency']!.dispose();
    }
    super.dispose();
  }

  double get _bmi {
    final h = double.tryParse(_heightCtrl.text) ?? 0;
    final w = double.tryParse(_weightCtrl.text) ?? 0;
    if (h <= 0 || w <= 0) return 0;
    return w / ((h / 100) * (h / 100));
  }

  int get _age {
    if (_dob == null) return 0;
    final now = DateTime.now();
    int a = now.year - _dob!.year;
    if (now.month < _dob!.month ||
        (now.month == _dob!.month && now.day < _dob!.day)) a--;
    return a;
  }

  String get _bmiLabel {
    if (_bmi < 18.5) return 'Underweight';
    if (_bmi < 25) return 'Normal';
    if (_bmi < 30) return 'Overweight';
    return 'Obese';
  }

  Color get _bmiColor {
    if (_bmi < 18.5) return Colors.blue;
    if (_bmi < 25) return Colors.green;
    if (_bmi < 30) return Colors.orange;
    return Colors.red;
  }

  void _addCondition() {
    final text = _conditionCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _conditions.add(text);
      _conditionCtrl.clear();
    });
  }

  void _addMedication() {
    setState(() {
      _medCtrls.add({
        'name': TextEditingController(),
        'dosage': TextEditingController(),
        'frequency': TextEditingController(),
      });
    });
  }

  void _removeMedication(int index) {
    final m = _medCtrls.removeAt(index);
    m['name']!.dispose();
    m['dosage']!.dispose();
    m['frequency']!.dispose();
    setState(() {});
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(1970),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _save() async {
    final meds = _medCtrls
        .map((m) => {
              'name': m['name']!.text,
              'dosage': m['dosage']!.text,
              'frequency': m['frequency']!.text,
            })
        .where((m) => (m['name'] ?? '').isNotEmpty)
        .toList();

    await _ctrl.updatePatientData({
      'dob': _dob?.toIso8601String().split('T')[0] ?? '',
      'bloodType': _bloodType,
      'height': double.tryParse(_heightCtrl.text) ?? 0,
      'weight': double.tryParse(_weightCtrl.text) ?? 0,
      'conditions': _conditions,
      'medications': meds,
      'emergencyContact': {
        'name': _emNameCtrl.text,
        'phone': _emPhoneCtrl.text,
      },
    });

    Get.back();
    Get.snackbar('snackbar.success'.tr, 'edit.success'.tr);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: TextButton(
          onPressed: () => Get.back(),
          child: Text('edit.cancel'.tr,
              style: const TextStyle(
                  color: Color(0xFF0066CC), fontSize: 16)),
        ),
        leadingWidth: 90,
        title: Text('edit.title'.tr),
        actions: [
          TextButton(
            onPressed: _save,
            child: Text('edit.save'.tr,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0066CC))),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Basic information ───────────────────────────────────────────
            _sectionHeader('edit.section.basic'.tr),

            // Date of birth picker
            InkWell(
              onTap: _pickDob,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade400),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        color: Color(0xFF0066CC), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('edit.dob'.tr,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey.shade600)),
                          const SizedBox(height: 2),
                          Text(
                            _dob != null
                                ? '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}'
                                : 'edit.dob.tap'.tr,
                            style: TextStyle(
                                fontSize: 16,
                                color: _dob != null
                                    ? Colors.black
                                    : Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded,
                        color: Colors.grey),
                  ],
                ),
              ),
            ),

            if (_dob != null && _age > 0) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(
                  'edit.age'.trParams({'age': _age.toString()}),
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Blood type dropdown
            DropdownButtonFormField<String>(
              value: _bloodType,
              decoration: InputDecoration(
                labelText: 'edit.blood_type'.tr,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              items: _bloodTypes
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _bloodType = v!),
            ),

            const SizedBox(height: 28),

            // ── Height & Weight ─────────────────────────────────────────────
            _sectionHeader('edit.section.measurements'.tr),

            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'edit.height'.tr,
                      suffixText: 'cm',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _weightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'edit.weight'.tr,
                      suffixText: 'kg',
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),

            if (_bmi > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _bmiColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: _bmiColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('edit.bmi'.tr,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    Text(
                      '${_bmi.toStringAsFixed(1)} — $_bmiLabel',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: _bmiColor),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 28),

            // ── Medical conditions ──────────────────────────────────────────
            _sectionHeader('edit.section.conditions'.tr),

            if (_conditions.isNotEmpty) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _conditions.asMap().entries.map((e) => Chip(
                      label: Text(e.value,
                          style: const TextStyle(fontSize: 14)),
                      deleteIcon:
                          const Icon(Icons.close_rounded, size: 16),
                      onDeleted: () => setState(
                          () => _conditions.removeAt(e.key)),
                      backgroundColor:
                          Colors.blue.withOpacity(0.07),
                      side: BorderSide(
                          color: Colors.blue.withOpacity(0.25)),
                    )).toList(),
              ),
              const SizedBox(height: 10),
            ],

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _conditionCtrl,
                    decoration: InputDecoration(
                      hintText: 'edit.conditions.hint'.tr,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                    ),
                    onSubmitted: (_) => _addCondition(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addCondition,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0066CC),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  child: Text('edit.conditions.add'.tr),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Medications ─────────────────────────────────────────────────
            _sectionHeader('edit.section.medications'.tr),

            ..._medCtrls.asMap().entries
                .map((e) => _medicationCard(e.key, e.value)),

            OutlinedButton.icon(
              onPressed: _addMedication,
              icon: const Icon(Icons.add_rounded),
              label: Text('edit.med.add'.tr),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: Color(0xFF0066CC)),
                foregroundColor: const Color(0xFF0066CC),
              ),
            ),

            const SizedBox(height: 28),

            // ── Emergency contact ───────────────────────────────────────────
            _sectionHeader('edit.section.emergency'.tr),

            TextFormField(
              controller: _emNameCtrl,
              decoration: InputDecoration(
                labelText: 'edit.emergency.name'.tr,
                prefixIcon: const Icon(Icons.person_outline_rounded),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'edit.emergency.phone'.tr,
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),

            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('edit.save'.tr,
                    style: const TextStyle(fontSize: 18)),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(title,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0066CC))),
    );
  }

  Widget _medicationCard(
      int index, Map<String, TextEditingController> ctrls) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.medication_rounded,
                    color: Colors.purple, size: 20),
                const SizedBox(width: 8),
                Text('${index + 1}.',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                GestureDetector(
                  onTap: () => _removeMedication(index),
                  child: const Icon(Icons.delete_outline_rounded,
                      color: Colors.red, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: ctrls['name'],
              decoration: InputDecoration(
                labelText: 'edit.med.name'.tr,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrls['dosage'],
                    decoration: InputDecoration(
                      labelText: 'edit.med.dosage'.tr,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: ctrls['frequency'],
                    decoration: InputDecoration(
                      labelText: 'edit.med.frequency'.tr,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                      contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
