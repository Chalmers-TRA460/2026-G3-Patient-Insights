import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get/get.dart';
import '../controllers/settings_controller.dart';

class AccessibleAudioCard extends StatefulWidget {
  final String speakText;
  final Widget child;
  final VoidCallback? onTap;

  const AccessibleAudioCard({
    super.key,
    required this.speakText,
    required this.child,
    this.onTap,
  });

  @override
  State<AccessibleAudioCard> createState() => _AccessibleAudioCardState();
}

class _AccessibleAudioCardState extends State<AccessibleAudioCard> {
  final FlutterTts _tts = FlutterTts();
  final SettingsController _settings = Get.find<SettingsController>();

  Future<void> _speak() async {
    await _tts.stop();
    final preferred = _settings.ttsLanguage;
    final available = await _tts.isLanguageAvailable(preferred);
    await _tts.setLanguage(available == true ? preferred : 'en-US');
    await _tts.setSpeechRate(0.2);
    await _tts.setPitch(1.0);
    await _tts.speak(widget.speakText);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final accessible = _settings.isAccessibilityMode.value;
      return GestureDetector(
        onTap: () {
          if (accessible) _speak();
          widget.onTap?.call();
        },
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            widget.child,
            if (accessible)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Color(0xFF0066CC),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.volume_up_rounded,
                      size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
      );
    });
  }
}
