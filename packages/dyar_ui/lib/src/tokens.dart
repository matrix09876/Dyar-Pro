import 'package:flutter/material.dart';

/// Dyar Ultra UI design tokens — برتقالي ديار + مقاسات الـ QA spec
/// (أهداف لمس ≥44px، CTA 52-56px، خط ≥11px).
abstract final class DyarTokens {
  // الألوان
  static const brand = Color(0xFFF4691E);
  static const brandDark = Color(0xFFE04E12);
  static const brandLight = Color(0xFFFFE6D5);
  static const ink = Color(0xFF1A1A1F);
  static const inkMuted = Color(0xFF6B7280);
  static const surfaceLight = Color(0xFFF9FAFB);
  static const surfaceDark = Color(0xFF15151A);
  static const cardDark = Color(0xFF1E1E25);
  static const success = Color(0xFF16A34A);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFDC2626);

  // المقاسات
  static const ctaHeight = 54.0;
  static const minTouch = 44.0;
  static const radius = 16.0;
  static const radiusLg = 24.0;
}
