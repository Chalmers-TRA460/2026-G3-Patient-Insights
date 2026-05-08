import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  final RxString localeCode = RxString(Get.locale?.languageCode ?? 'en');
  final RxBool isAccessibilityMode = false.obs;

  String get ttsLanguage {
    final code = localeCode.value == 'default'
        ? (Get.deviceLocale?.languageCode ?? 'en')
        : localeCode.value;
    return code == 'sv' ? 'sv-SE' : 'en-US';
  }

  void setLocale(String code) {
    final Locale locale;
    if (code == 'default') {
      locale = Get.deviceLocale ?? const Locale('en', 'US');
    } else {
      locale = code == 'sv' ? const Locale('sv', 'SE') : const Locale('en', 'US');
    }
    Get.updateLocale(locale);
    localeCode.value = code;
  }

  void toggleAccessibilityMode() =>
      isAccessibilityMode.value = !isAccessibilityMode.value;

  void showLanguageSheet() {
    Get.bottomSheet(
      Obx(() => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'settings.language.sheet_title'.tr,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _sheetTile('default', '🌐', 'settings.language.default'.tr),
            _sheetTile('en', '🇬🇧', 'settings.language.english'.tr),
            _sheetTile('sv', '🇸🇪', 'settings.language.swedish'.tr),
          ],
        ),
      )),
    );
  }

  Widget _sheetTile(String code, String flag, String label) {
    final selected = localeCode.value == code;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Text(flag, style: const TextStyle(fontSize: 28)),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      trailing: selected
          ? const Icon(Icons.check_circle_rounded, color: Color(0xFF0066CC))
          : const Icon(Icons.radio_button_unchecked, color: Colors.grey),
      onTap: () {
        setLocale(code);
        Get.back();
      },
    );
  }
}
