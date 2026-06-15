import 'package:cloud_firestore/cloud_firestore.dart';

/// مفاتيح ميزات ديار — تتحكم بها اللوحة (config/features) لإظهار/إخفاء
/// أي ميزة عالميًا أو حسب المنطقة (المدينة). الجمهور (user/partner/driver/
/// service) ضمنيٌّ في مفتاح الميزة نفسه. الافتراضي الآمن: الميزة ظاهرة.
///
/// بنية الوثيقة `config/features`:
/// ```
/// { "<key>": true|false,                 // مفتاح عالمي
///   "byRegion": { "<cityId>": { "<key>": true|false } } }  // تجاوز للمدينة
/// ```
class FeatureFlags {
  const FeatureFlags(this.global, this.byRegion);

  final Map<String, bool> global;
  final Map<String, Map<String, bool>> byRegion;

  /// هل الميزة مفعّلة؟ تجاوز المنطقة يسبق العالمي، والافتراضي true.
  bool on(String key, {String? region}) {
    if (region != null) {
      final r = byRegion[region]?[key];
      if (r != null) return r;
    }
    return global[key] ?? true;
  }

  static const empty = FeatureFlags({}, {});

  factory FeatureFlags.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final global = <String, bool>{
      for (final e in d.entries)
        if (e.value is bool) e.key: e.value as bool,
    };
    final byRegion = <String, Map<String, bool>>{};
    final raw = d['byRegion'];
    if (raw is Map) {
      for (final city in raw.entries) {
        if (city.value is Map) {
          byRegion[city.key.toString()] = {
            for (final f in (city.value as Map).entries)
              if (f.value is bool) f.key.toString(): f.value as bool,
          };
        }
      }
    }
    return FeatureFlags(global, byRegion);
  }
}

/// كل مفاتيح الميزات المعروفة مجمّعة حسب الجمهور — مصدر واحد للوحة.
const Map<String, List<String>> kFeatureKeysByAudience = {
  'user': [
    'food', 'grocery', 'pharmacy', 'flowers', 'services', 'taxi', 'parcel',
    'marketplace', 'jobs', 'bookings', 'wholesale', 'loyalty', 'subscription',
    'referral', 'giftcards', 'voiceAgent', 'dietaryFilter', 'aiAssistant',
  ],
  'partner': ['printer', 'promotions', 'menuScheduling', 'selfCampaigns'],
  'driver': ['instantPayout', 'driverPrizes', 'rides', 'heatmap'],
  'service': ['appointments', 'consultation'],
};
