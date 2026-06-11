import '../i18n/strings.dart';

/// مهن مقدمي الخدمات — عقد ثابت مشترك بين اللوحة والتطبيقات.
/// المتجر من نوع `service` يحمل `serviceCategory` بأحد هذه المفاتيح.
/// (انظر docs/DATA-MODEL.md — stores.serviceCategory)
class ServiceCategory {
  const ServiceCategory({
    required this.key,
    required this.emoji,
    required this.labelAr,
    required this.labelHe,
    required this.labelEn,
  });

  final String key;
  final String emoji;
  final String labelAr, labelHe, labelEn;

  /// التسمية حسب لغة التطبيق الحالية
  String label(DyarLang lang) => switch (lang) {
        DyarLang.ar => labelAr,
        DyarLang.he => labelHe,
        DyarLang.en => labelEn,
      };
}

/// القائمة الرسمية (12+ مهنة) — الترتيب هو ترتيب العرض في الشبكة.
const List<ServiceCategory> kServiceCategories = [
  ServiceCategory(
      key: 'plumber', emoji: '🔧',
      labelAr: 'سباك', labelHe: 'אינסטלטור', labelEn: 'Plumber'),
  ServiceCategory(
      key: 'electrician', emoji: '⚡',
      labelAr: 'كهربائي', labelHe: 'חשמלאי', labelEn: 'Electrician'),
  ServiceCategory(
      key: 'painter', emoji: '🎨',
      labelAr: 'دهان', labelHe: 'צבעי', labelEn: 'Painter'),
  ServiceCategory(
      key: 'mechanic', emoji: '🚗',
      labelAr: 'ميكانيكي', labelHe: 'מוסכניק', labelEn: 'Mechanic'),
  ServiceCategory(
      key: 'carpenter', emoji: '🪚',
      labelAr: 'نجار', labelHe: 'נגר', labelEn: 'Carpenter'),
  ServiceCategory(
      key: 'accountant', emoji: '🧮',
      labelAr: 'محاسب', labelHe: 'רואה חשבון', labelEn: 'Accountant'),
  ServiceCategory(
      key: 'lawyer', emoji: '⚖️',
      labelAr: 'محامي', labelHe: 'עורך דין', labelEn: 'Lawyer'),
  ServiceCategory(
      key: 'doctor', emoji: '🩺',
      labelAr: 'طبيب', labelHe: 'רופא', labelEn: 'Doctor'),
  ServiceCategory(
      key: 'dentist', emoji: '🦷',
      labelAr: 'طبيب أسنان', labelHe: 'רופא שיניים', labelEn: 'Dentist'),
  ServiceCategory(
      key: 'barber', emoji: '💈',
      labelAr: 'حلاق', labelHe: 'ספר', labelEn: 'Barber'),
  ServiceCategory(
      key: 'salon', emoji: '💅',
      labelAr: 'صالون تجميل', labelHe: 'סלון יופי', labelEn: 'Beauty salon'),
  ServiceCategory(
      key: 'cleaning', emoji: '🧹',
      labelAr: 'تنظيف', labelHe: 'ניקיון', labelEn: 'Cleaning'),
  ServiceCategory(
      key: 'electronics', emoji: '📱',
      labelAr: 'تصليح إلكترونيات', labelHe: 'תיקון אלקטרוניקה',
      labelEn: 'Electronics repair'),
  ServiceCategory(
      key: 'ac', emoji: '❄️',
      labelAr: 'تكييف وتبريد', labelHe: 'מיזוג אוויר', labelEn: 'AC & cooling'),
];

/// بحث بالمفتاح (null إن لم يوجد)
ServiceCategory? serviceCategoryByKey(String? key) {
  if (key == null) return null;
  for (final c in kServiceCategories) {
    if (c.key == key) return c;
  }
  return null;
}
