import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';

class CaregiverScreen extends StatefulWidget {
  const CaregiverScreen({super.key});

  @override
  State<CaregiverScreen> createState() => _CaregiverScreenState();
}

class _CaregiverScreenState extends State<CaregiverScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isAdding = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) =>
      RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$').hasMatch(email);

  Future<void> _add(HealthController c) async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _isAdding = true);
    await c.addCaregiver(_emailController.text.trim());
    _emailController.clear();
    setState(() => _isAdding = false);
  }

  @override
  Widget build(BuildContext context) {
    final HealthController c = Get.find<HealthController>();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('caregiver.title'.tr,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Obx(() {
        final caregivers =
            c.patient.value?.authorizedCaregivers ?? const [];

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Info banner ─────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded,
                      color: Color(0xFF1D4ED8), size: 26),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'caregiver.info'.tr,
                      style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF1E3A8A),
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ── Current caregivers ──────────────────────────────────────────
            Text('caregiver.current'.tr,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 14),

            if (caregivers.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 32, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.people_outline_rounded,
                        size: 52,
                        color: Colors.grey.withOpacity(0.4)),
                    const SizedBox(height: 14),
                    Text('caregiver.empty'.tr,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 17, color: Color(0xFF64748B))),
                  ],
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Column(
                  children: caregivers.asMap().entries.map((entry) {
                    final i = entry.key;
                    final email = entry.value;
                    return Column(
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                const Color(0xFFEFF6FF),
                            child: Text(
                              email[0].toUpperCase(),
                              style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1D4ED8)),
                            ),
                          ),
                          title: Text(
                            email,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1E293B)),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: Colors.red, size: 28),
                            tooltip: 'caregiver.revoke'.tr,
                            onPressed: () =>
                                _confirmRevoke(context, c, email),
                          ),
                        ),
                        if (i < caregivers.length - 1)
                          const Divider(
                              height: 1, indent: 20, endIndent: 20),
                      ],
                    );
                  }).toList(),
                ),
              ),

            const SizedBox(height: 36),

            // ── Add caregiver ───────────────────────────────────────────────
            Text('caregiver.add_title'.tr,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 6),
            Text('caregiver.add_subtitle'.tr,
                style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF64748B),
                    height: 1.4)),
            const SizedBox(height: 16),

            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    style: const TextStyle(fontSize: 17),
                    decoration: InputDecoration(
                      labelText: 'caregiver.email_label'.tr,
                      labelStyle: const TextStyle(fontSize: 16),
                      prefixIcon: const Icon(Icons.email_outlined, size: 24),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14)),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 18),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'caregiver.error_empty'.tr;
                      }
                      if (!_isValidEmail(v.trim())) {
                        return 'caregiver.error_invalid'.tr;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: _isAdding
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white))
                          : const Icon(Icons.person_add_rounded),
                      label: Text(
                        _isAdding
                            ? 'caregiver.adding'.tr
                            : 'caregiver.add_btn'.tr,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      onPressed:
                          _isAdding ? null : () => _add(c),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0066CC),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFF0066CC).withOpacity(0.6),
                        padding:
                            const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        );
      }),
    );
  }

  void _confirmRevoke(
      BuildContext context, HealthController c, String email) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('caregiver.revoke_title'.tr,
            style: const TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold)),
        content: Text(
          'caregiver.revoke_body'.trParams({'email': email}),
          style: const TextStyle(fontSize: 16, height: 1.5),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton(
            onPressed: Get.back,
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14)),
            child: Text('history.cancel'.tr,
                style: const TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () {
              Get.back();
              c.removeCaregiver(email);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14)),
            child: Text('caregiver.revoke'.tr,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
