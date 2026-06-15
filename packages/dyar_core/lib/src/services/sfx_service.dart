import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// أصوات ومؤثرات ديار — نقرة/اهتزاز عند الأحداث (طلب الطعام، تلقّي الطلب).
/// يستعمل أصوات النظام واهتزازه (بلا أصول/حِزم خارجية، آمن على الويب).
/// المستخدم يتحكم بالتشغيل/الإطفاء من «حسابي» (مفتاح dyar.sfx، الافتراضي مُفعّل).
class SfxService {
  static const _key = 'dyar.sfx';

  Future<bool> isEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(_key) ?? true;

  Future<void> setEnabled(bool v) async =>
      (await SharedPreferences.getInstance()).setBool(_key, v);

  /// نجاح/تأكيد — عند إرسال الطلب أو تلقّي طلب جديد (للتاجر/السائق).
  Future<void> success() async {
    if (!await isEnabled()) return;
    await HapticFeedback.mediumImpact();
    await SystemSound.play(SystemSoundType.alert);
  }

  /// لمسة خفيفة — عند الإضافة للسلة أو التنقّل.
  Future<void> tap() async {
    if (!await isEnabled()) return;
    await HapticFeedback.selectionClick();
  }
}
