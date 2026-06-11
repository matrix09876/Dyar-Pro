import 'package:flutter/material.dart';

import 'tokens.dart';

/// قوالب هوية المينيو — "المينيو كهوية بصرية لكل متجر"
/// (docs/COMPETITOR-TEARDOWN.md §4): كل متجر يضبط
/// `stores/{id}.brand = { template, accent? }` فتتلوّن صفحته كاملة —
/// تدرج الترويسة وشريط السلة، شارة السعر، شكل بطاقة الصنف
/// (زوايا/ظل/خلفية)، ونمط فاصل الأقسام — بلا أي كود مخصص لكل متجر.
///
/// القوالب الخمسة:
/// - `elegant`  — داكن ذهبي للمطاعم الفاخرة
/// - `fresh`    — أخضر نقي للبقالة/الصحي
/// - `street`   — برتقالي-أحمر جريء للوجبات السريعة
/// - `pharma`   — أزرق طبي هادئ للصيدليات
/// - `boutique` — بنفسجي راقٍ للورود/الهدايا
///
/// غياب `brand` (أو قيمة غير معروفة) = هوية ديار الافتراضية كما هي.

/// نمط فاصل الأقسام تحت عنوان كل قسم في المينيو.
enum MenuDividerStyle {
  /// خط رفيع بلون الهوية — رصين (elegant / pharma / الافتراضي).
  line,

  /// ثلاث نقاط متدرجة الشفافية — ناعم (fresh / boutique).
  dots,

  /// بلوك سميك جريء — صاخب (street).
  block,
}

@immutable
class MenuBrand {
  const MenuBrand({
    required this.template,
    required this.accent,
    required this.accentDark,
    required this.accentSoft,
    required this.headerGradient,
    required this.priceColor,
    required this.cardRadius,
    required this.cardShadow,
    required this.pageBackground,
    required this.dividerStyle,
    this.priceBadgeBg,
    this.cardColor = Colors.white,
  });

  /// معرّف القالب ('dyar' للافتراضي).
  final String template;

  /// لون الهوية الأساسي (chips المختارة، الفواصل، عدّاد الكمية).
  final Color accent;

  /// درجة داكنة من الهوية (نصوص/أيقونات فوق خلفيات فاتحة).
  final Color accentDark;

  /// صبغة فاتحة من الهوية (خلفية العدّاد، placeholder الصور).
  final Color accentSoft;

  /// تدرج الترويسة — يصبغ زر الإضافة وشريط السلة اللاصق.
  final LinearGradient headerGradient;

  /// خلفية شارة السعر — null = نص سعر عادي بلا شارة (الافتراضي الحالي).
  final Color? priceBadgeBg;

  /// لون نص السعر.
  final Color priceColor;

  /// نصف قطر زوايا بطاقة الصنف.
  final double cardRadius;

  /// ظل بطاقة الصنف.
  final List<BoxShadow> cardShadow;

  /// خلفية بطاقة الصنف.
  final Color cardColor;

  /// خلفية صفحة المتجر.
  final Color pageBackground;

  /// نمط فاصل الأقسام.
  final MenuDividerStyle dividerStyle;

  BorderRadius get cardBorderRadius => BorderRadius.circular(cardRadius);

  // ───────────────────────── القوالب ─────────────────────────

  /// الافتراضي الحالي — برتقالي ديار (يُستخدم عند غياب brand).
  static const dyar = MenuBrand(
    template: 'dyar',
    accent: DyarTokens.brand,
    accentDark: DyarTokens.brandDark,
    accentSoft: DyarTokens.brandLight,
    headerGradient:
        LinearGradient(colors: [Color(0xFFFF8A3D), DyarTokens.brandDark]),
    priceColor: DyarTokens.brandDark,
    cardRadius: 20,
    cardShadow: [
      BoxShadow(
          color: Color(0x0D000000), blurRadius: 14, offset: Offset(0, 6)),
    ],
    pageBackground: Color(0xFFF6F7FB),
    dividerStyle: MenuDividerStyle.line,
  );

  /// مطاعم فاخرة — داكن ذهبي، زوايا مشدودة، شارة سعر داكنة بنص ذهبي.
  static const elegant = MenuBrand(
    template: 'elegant',
    accent: Color(0xFFC9A24B),
    accentDark: Color(0xFF8C6D1F),
    accentSoft: Color(0xFFF0E6CC),
    headerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2B2620), Color(0xFF0F0E0C)],
    ),
    priceBadgeBg: Color(0xFF23201B),
    priceColor: Color(0xFFE6C878),
    cardRadius: 12,
    cardShadow: [
      BoxShadow(
          color: Color(0x1A60501E), blurRadius: 20, offset: Offset(0, 8)),
    ],
    pageBackground: Color(0xFFFAF7F0),
    dividerStyle: MenuDividerStyle.line,
  );

  /// بقالة/صحي — أخضر نقي، بطاقات خفيفة، فاصل نقاط.
  static const fresh = MenuBrand(
    template: 'fresh',
    accent: Color(0xFF16A34A),
    accentDark: Color(0xFF0F7A38),
    accentSoft: Color(0xFFE3F6E9),
    headerGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF4ADE80), Color(0xFF15803D)],
    ),
    priceBadgeBg: Color(0xFFE7F8EC),
    priceColor: Color(0xFF15803D),
    cardRadius: 18,
    cardShadow: [
      BoxShadow(
          color: Color(0x1416A34A), blurRadius: 12, offset: Offset(0, 5)),
    ],
    pageBackground: Color(0xFFF2FBF4),
    dividerStyle: MenuDividerStyle.dots,
  );

  /// وجبات سريعة — برتقالي-أحمر جريء، زوايا ضخمة، ظل قوي، فاصل بلوك.
  static const street = MenuBrand(
    template: 'street',
    accent: Color(0xFFFF3D00),
    accentDark: Color(0xFFC81E00),
    accentSoft: Color(0xFFFFE3D6),
    headerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF9100), Color(0xFFE52600)],
    ),
    priceBadgeBg: Color(0xFF1A1A1F),
    priceColor: Color(0xFFFFC53D),
    cardRadius: 24,
    cardShadow: [
      BoxShadow(
          color: Color(0x33E52600), blurRadius: 18, offset: Offset(0, 8)),
    ],
    pageBackground: Color(0xFFFFF4EC),
    dividerStyle: MenuDividerStyle.block,
  );

  /// صيدلية — أزرق طبي هادئ، بطاقات رصينة بظل خافت جدًا.
  static const pharma = MenuBrand(
    template: 'pharma',
    accent: Color(0xFF2563EB),
    accentDark: Color(0xFF1E40AF),
    accentSoft: Color(0xFFE3EDFD),
    headerGradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF60A5FA), Color(0xFF1D4ED8)],
    ),
    priceBadgeBg: Color(0xFFE8F0FE),
    priceColor: Color(0xFF1E40AF),
    cardRadius: 14,
    cardShadow: [
      BoxShadow(
          color: Color(0x0A1E3A8A), blurRadius: 10, offset: Offset(0, 4)),
    ],
    pageBackground: Color(0xFFF4F7FC),
    dividerStyle: MenuDividerStyle.line,
  );

  /// ورود/هدايا — بنفسجي راقٍ، ظل بنفسجي ناعم، فاصل نقاط.
  static const boutique = MenuBrand(
    template: 'boutique',
    accent: Color(0xFF8B5CF6),
    accentDark: Color(0xFF6D28D9),
    accentSoft: Color(0xFFEFE6FD),
    headerGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFA78BFA), Color(0xFF6D28D9)],
    ),
    priceBadgeBg: Color(0xFFF3EBFF),
    priceColor: Color(0xFF6D28D9),
    cardRadius: 22,
    cardShadow: [
      BoxShadow(
          color: Color(0x1F6D28D9), blurRadius: 16, offset: Offset(0, 8)),
    ],
    pageBackground: Color(0xFFFAF7FE),
    dividerStyle: MenuDividerStyle.dots,
  );

  // ─────────────────────── التحويل من العقد ───────────────────────

  /// يحوّل `stores/{id}.brand` (Map) إلى هوية جاهزة.
  /// brand غائب/غير معروف → [dyar] (الافتراضي الحالي بلا تغيير).
  /// `accent` (hex مثل `#7C3AED`) يعيد صبغ القالب بلون المتجر.
  static MenuBrand of(Map<String, dynamic>? brand) {
    final base = switch (brand?['template']) {
      'elegant' => elegant,
      'fresh' => fresh,
      'street' => street,
      'pharma' => pharma,
      'boutique' => boutique,
      _ => dyar,
    };
    final accentHex = brand?['accent'];
    if (accentHex is! String) return base;
    final custom = _parseHex(accentHex);
    return custom == null ? base : base._withAccent(custom);
  }

  /// إعادة صبغ القالب بلون مخصص مع الإبقاء على الشكل (زوايا/ظل/فاصل).
  MenuBrand _withAccent(Color a) {
    final dark = _darken(a, 0.28);
    return MenuBrand(
      template: template,
      accent: a,
      accentDark: dark,
      accentSoft: a.withValues(alpha: 0.14),
      headerGradient: LinearGradient(
        begin: headerGradient.begin,
        end: headerGradient.end,
        colors: [a, _darken(a, 0.35)],
      ),
      priceBadgeBg: priceBadgeBg == null ? null : a.withValues(alpha: 0.12),
      priceColor: dark,
      cardRadius: cardRadius,
      cardShadow: [
        BoxShadow(
            color: a.withValues(alpha: 0.16),
            blurRadius: 14,
            offset: const Offset(0, 6)),
      ],
      cardColor: cardColor,
      pageBackground: pageBackground,
      dividerStyle: dividerStyle,
    );
  }

  /// فاصل القسم وفق القالب — يوضع بجانب/تحت عنوان القسم.
  Widget sectionDivider() {
    switch (dividerStyle) {
      case MenuDividerStyle.line:
        return Container(
          height: 2.5,
          width: 46,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      case MenuDividerStyle.dots:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < 3; i++)
              Container(
                height: 6,
                width: 6,
                margin: const EdgeInsetsDirectional.only(end: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 1 - i * 0.3),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        );
      case MenuDividerStyle.block:
        return Container(
          height: 7,
          width: 34,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(4),
          ),
        );
    }
  }

  static Color? _parseHex(String hex) {
    var h = hex.replaceFirst('#', '').trim();
    if (h.length == 6) h = 'FF$h';
    if (h.length != 8) return null;
    final v = int.tryParse(h, radix: 16);
    return v == null ? null : Color(v);
  }

  static Color _darken(Color c, double t) => Color.lerp(c, Colors.black, t)!;
}
