import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/health_controller.dart';

// Persistent banner shown whenever the user is viewing a family member's
// profile. Must never scroll off-screen — always placed outside any
// scrollable widget, directly inside a Column as the first child.
class ViewingBanner extends StatelessWidget {
  const ViewingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final HealthController c = Get.find<HealthController>();
    return Obx(() {
      if (!c.isViewingOther) return const SizedBox.shrink();
      final name = c.currentViewedPatient.value?.name ?? '';
      return Container(
        width: double.infinity,
        color: const Color(0xFFEA580C),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.white, size: 24),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'family.viewing_banner'.trParams({'name': name}),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    height: 1.3),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: c.returnToMyProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFFEA580C),
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('family.return_btn'.tr,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    });
  }
}
