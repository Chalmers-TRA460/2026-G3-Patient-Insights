import 'package:flutter/material.dart';
import 'package:get/get.dart';

class SettingsController extends GetxController {
  final RxString localeCode = RxString(Get.locale?.languageCode ?? 'en');
  final RxBool isAccessibilityMode = false.obs;

  String get ttsLanguage => localeCode.value == 'sv' ? 'sv-SE' : 'en-US';

  void setLocale(String code) {
    final locale = code == 'sv' ? const Locale('sv', 'SE') : const Locale('en', 'US');
    Get.updateLocale(locale);
    localeCode.value = code;
  }

  void toggleLocale() =>
      setLocale(localeCode.value == 'sv' ? 'en' : 'sv');

  void toggleAccessibilityMode() =>
      isAccessibilityMode.value = !isAccessibilityMode.value;
}
