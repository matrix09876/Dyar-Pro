import 'package:cloud_functions/cloud_functions.dart';
import '../models/ai_cart.dart';

/// المساعد الذكي للتسوّق (ديار AI) — يستدعي دالة aiBuildCart الخادمية التي
/// تختار متجراً وأصنافاً حقيقية بأسعار مُتحقَّقة. لا طلب بلا تأكيد المستخدم.
class AiService {
  AiService({FirebaseFunctions? fns})
      : _fns = fns ?? FirebaseFunctions.instance;
  final FirebaseFunctions _fns;

  Future<AiCartSuggestion> buildCart({
    required String query,
    required String lang,
    String? city,
    String? type,
    int? budget, // أغورة
  }) async {
    final res = await _fns.httpsCallable('aiBuildCart').call({
      'query': query,
      'lang': lang,
      if (city != null) 'city': city,
      if (type != null) 'type': type,
      if (budget != null) 'budget': budget,
    });
    return AiCartSuggestion.fromMap(Map<String, dynamic>.from(res.data));
  }
}
