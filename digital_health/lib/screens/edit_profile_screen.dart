import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import '../models/medical_entry_model.dart';

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

  final List<Map<String, TextEditingController>> _medCtrls = [];

  // One input controller per standardized medical category.
  final Map<String, TextEditingController> _medicalInputCtrls = {
    for (final c in HealthController.medicalEntryCategories)
      c: TextEditingController(),
  };

  // Categories where the entry has a clinically meaningful date the patient
  // can provide (e.g. when the vaccine was given, when the illness occurred).
  static const Set<String> _datedCategories = {
    'pastIllnesses',
    'implants',
    'vaccinations',
  };

  // Holds the currently-selected `occurredOn` date for the input row of each
  // dated category. Reset to null after the user adds an entry.
  final Map<String, DateTime?> _medicalInputDates = {};

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

    for (final med in (p?.medications ?? [])) {
      _medCtrls.add({
        'name': TextEditingController(text: med['name'] ?? ''),
        'dosage': TextEditingController(text: med['dosage'] ?? ''),
        'frequency': TextEditingController(text: med['frequency'] ?? ''),
      });
    }
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    for (final m in _medCtrls) {
      m['name']!.dispose();
      m['dosage']!.dispose();
      m['frequency']!.dispose();
    }
    for (final c in _medicalInputCtrls.values) {
      c.dispose();
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
      'medications': meds,
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

            // ── Standardized medical information (EHDS / FHIR-aligned) ──────
            _medicalInfoHeader(),
            _medicalDisclaimer(),
            const SizedBox(height: 16),
            _medicalSection(
                'allergies', 'edit.medical.section.allergies'.tr),
            _legacyMedicationsSubsection(
                'edit.medical.section.current_meds'.tr),
            _medicalSection('currentDiagnoses',
                'edit.medical.section.current_diagnoses'.tr),
            _medicalSection(
                'pastIllnesses', 'edit.medical.section.past_illnesses'.tr),
            _medicalSection(
                'implants', 'edit.medical.section.implants'.tr),
            _medicalSection(
                'vaccinations', 'edit.medical.section.vaccinations'.tr),

            const SizedBox(height: 12),

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

  // ── Standardized medical entries ──────────────────────────────────────────

  Widget _medicalInfoHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        'edit.medical.section_header'.tr,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: Color(0xFF0066CC),
        ),
      ),
    );
  }

  Widget _medicalDisclaimer() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        border: Border.all(color: const Color(0xFFE6C200)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: Color(0xFF8A6D00), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'edit.medical.disclaimer'.tr,
              style: const TextStyle(
                  fontSize: 13.5, color: Color(0xFF5C4A00), height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _medicalSection(String category, String title) {
    final inputCtrl = _medicalInputCtrls[category]!;
    final isDated = _datedCategories.contains(category);
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(title),
          Obx(() {
            // Bind to patient.value so the chip list rebuilds after writes.
            _ctrl.patient.value;
            final entries = _ctrl.medicalEntriesFor(category);
            if (entries.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: entries
                    .map((e) => Chip(
                          label: Text(_chipLabel(e),
                              style: const TextStyle(fontSize: 14)),
                          deleteIcon:
                              const Icon(Icons.close_rounded, size: 16),
                          onDeleted: () => _ctrl.removeMedicalEntry(
                              category: category, id: e.id),
                          backgroundColor:
                              Colors.blue.withOpacity(0.07),
                          side: BorderSide(
                              color: Colors.blue.withOpacity(0.25)),
                        ))
                    .toList(),
              ),
            );
          }),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: inputCtrl,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'edit.medical.hint'.tr,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  onSubmitted: (_) => _submitMedicalEntry(category),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _submitMedicalEntry(category),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                child: Text('edit.medical.add'.tr),
              ),
            ],
          ),
          if (isDated) _medicalDateRow(category),
        ],
      ),
    );
  }

  // Inline date picker row shown under the text input for dated categories
  // (past illnesses, implants, vaccinations). Optional — leave blank to add
  // an entry without a date.
  Widget _medicalDateRow(String category) {
    final selected = _medicalInputDates[category];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: InkWell(
        onTap: () => _pickMedicalDate(category),
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_outlined,
                  size: 18, color: Color(0xFF0066CC)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  selected != null
                      ? _formatDate(selected)
                      : 'edit.medical.date_add'.tr,
                  style: TextStyle(
                    fontSize: 14,
                    color: selected != null
                        ? Colors.black87
                        : Colors.grey.shade700,
                    fontWeight: selected != null
                        ? FontWeight.w600
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (selected != null)
                GestureDetector(
                  onTap: () => setState(
                      () => _medicalInputDates[category] = null),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(Icons.close_rounded,
                        size: 18, color: Colors.grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickMedicalDate(String category) async {
    final initial = _medicalInputDates[category] ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _medicalInputDates[category] = picked);
    }
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _chipLabel(MedicalEntry e) {
    if (e.occurredOn == null) return e.displayText;
    return '${e.displayText} · ${_formatDate(e.occurredOn!)}';
  }

  // Reuses the legacy name/dosage/frequency medication cards inside the
  // Medical Information block, taking the slot that previously rendered
  // structured currentMedications chips. Persists via the existing
  // `medications` field on the Patient model when the user hits Save.
  Widget _legacyMedicationsSubsection(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(title),
          ..._medCtrls.asMap().entries
              .map((e) => _medicationCard(e.key, e.value)),
          OutlinedButton.icon(
            onPressed: _addMedication,
            icon: const Icon(Icons.add_rounded),
            label: Text('edit.med.add'.tr),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Color(0xFF0066CC)),
              foregroundColor: const Color(0xFF0066CC),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submitMedicalEntry(String category) async {
    final ctrl = _medicalInputCtrls[category]!;
    final text = ctrl.text.trim();
    if (text.isEmpty) return;
    final occurredOn = _medicalInputDates[category];
    ctrl.clear();
    setState(() => _medicalInputDates[category] = null);
    await _ctrl.addMedicalEntry(
      category: category,
      displayText: text,
      occurredOn: occurredOn,
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
