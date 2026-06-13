/// وسوم الحِمية والتصديق المشتركة — مصدر واحد للزبون والتاجر واللوحة.
/// حلال/كوشير وسوم تصديق (تحتاج توثيق الإدارة لتظهر ✓)، والبقية وسوم
/// حِمية يصرّح بها التاجر. التسميات الثلاثية في i18n (مفتاح diet_{key}).
library;

class DietaryTag {
  const DietaryTag(this.key, this.emoji, {this.certification = false});

  /// مفتاح ثابت يُخزَّن في store.dietary / menuItem.dietary
  final String key;
  final String emoji;

  /// تصديق ديني (حلال/كوشير) — يُعرض ✓ فقط إذا store.dietaryVerified
  final bool certification;
}

/// الوسوم المعتمدة بالترتيب — تُستعمل في الفلتر والشارات.
const List<DietaryTag> kDietaryTags = [
  DietaryTag('halal', '☪️', certification: true),
  DietaryTag('kosher', '✡️', certification: true),
  DietaryTag('vegetarian', '🥗'),
  DietaryTag('vegan', '🌱'),
  DietaryTag('glutenFree', '🌾'),
  DietaryTag('spicy', '🌶️'),
];

DietaryTag? dietaryTagByKey(String key) {
  for (final t in kDietaryTags) {
    if (t.key == key) return t;
  }
  return null;
}
