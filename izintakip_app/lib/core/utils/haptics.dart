import 'package:flutter/services.dart';

class Haptics {
  static Future<void> light() async {
    await HapticFeedback.lightImpact();
  }

  static Future<void> medium() async {
    await HapticFeedback.mediumImpact();
  }

  static Future<void> heavy() async {
    await HapticFeedback.heavyImpact();
  }

  // hazır kütüphanesi de var ama küçük bir kısmı bize yeter o yüzden utils içinde kendimiz yazdık
  // kaynak: https://pub.dev/packages/haptic_feedback
  static Future<void> refresh() async {
    await HapticFeedback.selectionClick();
  }
}
