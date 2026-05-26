import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';
import 'prepare_visit_screen.dart';

class AppointmentSetupScreen extends StatefulWidget {
  const AppointmentSetupScreen({super.key});

  @override
  State<AppointmentSetupScreen> createState() =>
      _AppointmentSetupScreenState();
}

class _AppointmentSetupScreenState extends State<AppointmentSetupScreen> {
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;

  static const List<String> _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const List<String> _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  String _formatDate(DateTime d) =>
      '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]} ${d.year}';

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0066CC),
            onPrimary: Colors.white,
            surface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF0066CC),
            onPrimary: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _onContinue() {
    if (_selectedDate == null) {
      Get.snackbar(
        'snackbar.info'.tr,
        'appt.error.no_date'.tr,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
      return;
    }
    final c = Get.find<HealthController>();
    c.appointmentDate.value = _formatDate(_selectedDate!);
    c.appointmentTime.value =
        _selectedTime != null ? _formatTime(_selectedTime!) : '';
    c.clearVisitNotes();
    Get.to(() => const PrepareVisitScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text('New Appointment',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Step indicator ───────────────────────────────────────────────
            _StepBadge(step: 1, total: 3, label: 'appt.step1'.tr),
            const SizedBox(height: 24),

            // ── Header ───────────────────────────────────────────────────────
            const Text('When is your appointment?',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B))),
            const SizedBox(height: 8),
            const Text(
              'Set the date and time so you can track and prepare for your visit.',
              style: TextStyle(
                  fontSize: 15, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 36),

            // ── Date picker card ─────────────────────────────────────────────
            const Text('Appointment Date',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.4)),
            const SizedBox(height: 8),
            _PickerCard(
              icon: Icons.calendar_today_rounded,
              iconColor: const Color(0xFF0066CC),
              iconBg: const Color(0xFFEFF6FF),
              label: _selectedDate != null
                  ? _formatDate(_selectedDate!)
                  : 'Select a date',
              hasValue: _selectedDate != null,
              onTap: _pickDate,
            ),
            const SizedBox(height: 20),

            // ── Time picker card ─────────────────────────────────────────────
            const Text('Appointment Time',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF64748B),
                    letterSpacing: 0.4)),
            const SizedBox(height: 8),
            _PickerCard(
              icon: Icons.access_time_rounded,
              iconColor: const Color(0xFF7C3AED),
              iconBg: const Color(0xFFF5F3FF),
              label: _selectedTime != null
                  ? _formatTime(_selectedTime!)
                  : 'Select a time (optional)',
              hasValue: _selectedTime != null,
              onTap: _pickTime,
            ),

            // ── Tip ──────────────────────────────────────────────────────────
            if (_selectedDate != null) ...[
              const SizedBox(height: 28),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_rounded,
                        color: Color(0xFF16A34A), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Appointment set for ${_formatDate(_selectedDate!)}${_selectedTime != null ? ' at ${_formatTime(_selectedTime!)}' : ''}.',
                        style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF15803D),
                            height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 48),

            // ── Continue button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.arrow_forward_rounded, size: 20),
                label: const Text('Continue to Preparation',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0066CC),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepBadge extends StatelessWidget {
  final int step;
  final int total;
  final String label;
  const _StepBadge(
      {required this.step, required this.total, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF0066CC),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Step $step of $total',
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.3),
          ),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _PickerCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final bool hasValue;
  final VoidCallback onTap;

  const _PickerCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.hasValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasValue
                ? const Color(0xFF0066CC).withOpacity(0.4)
                : const Color(0xFFE2E8F0),
            width: hasValue ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: iconBg, borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      hasValue ? FontWeight.w600 : FontWeight.normal,
                  color: hasValue
                      ? const Color(0xFF1E293B)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ),
            Icon(
              hasValue ? Icons.edit_rounded : Icons.chevron_right_rounded,
              color: const Color(0xFF94A3B8),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
