import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';

class EditConsultationScreen extends StatefulWidget {
  final Map<String, dynamic> visit;
  final int index;

  const EditConsultationScreen({
    super.key,
    required this.visit,
    required this.index,
  });

  @override
  State<EditConsultationScreen> createState() => _EditConsultationScreenState();
}

class _EditConsultationScreenState extends State<EditConsultationScreen> {
  late final TextEditingController _doctorCtrl;
  late final TextEditingController _transcriptCtrl;
  late final TextEditingController _briefCtrl;
  late final TextEditingController _detailCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final v = widget.visit;
    _doctorCtrl = TextEditingController(text: v['doctorName'] as String? ?? '');
    _transcriptCtrl =
        TextEditingController(text: v['transcript'] as String? ?? '');
    _briefCtrl =
        TextEditingController(text: v['briefSummary'] as String? ?? '');
    _detailCtrl = TextEditingController(
      text: v['detailedSummary'] as String? ?? v['summary'] as String? ?? '',
    );
  }

  @override
  void dispose() {
    _doctorCtrl.dispose();
    _transcriptCtrl.dispose();
    _briefCtrl.dispose();
    _detailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final c = Get.find<HealthController>();
    final detail = _detailCtrl.text.trim();
    await c.updateConsultation(widget.index, {
      'doctorName': _doctorCtrl.text.trim(),
      'transcript': _transcriptCtrl.text.trim(),
      'briefSummary': _briefCtrl.text.trim(),
      'detailedSummary': detail,
      if (detail.isNotEmpty) 'summary': detail,
    });
    if (mounted) setState(() => _saving = false);
    Get.back();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('edit_consult.title'.tr),
        actions: [
          if (_saving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                'edit_consult.save'.tr,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _label('edit_consult.doctor'.tr),
            const SizedBox(height: 8),
            _field(_doctorCtrl,
                maxLines: 1, hint: 'edit_consult.doctor_hint'.tr),
            const SizedBox(height: 24),

            _label('edit_consult.transcript'.tr),
            const SizedBox(height: 8),
            _field(_transcriptCtrl,
                maxLines: 10, hint: 'edit_consult.transcript_hint'.tr),
            const SizedBox(height: 24),

            _label('detail.brief_label'.tr),
            const SizedBox(height: 8),
            _field(_briefCtrl,
                maxLines: 5, hint: 'edit_consult.brief_hint'.tr),
            const SizedBox(height: 24),

            _label('detail.full_label'.tr),
            const SizedBox(height: 8),
            _field(_detailCtrl,
                maxLines: 8, hint: 'edit_consult.detail_hint'.tr),
            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: Text('edit_consult.save'.tr,
                    style: const TextStyle(
                        fontSize: 17, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: Color(0xFF334155)),
      );

  Widget _field(TextEditingController ctrl,
      {required int maxLines, required String hint}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 16, height: 1.5),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF0066CC), width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
