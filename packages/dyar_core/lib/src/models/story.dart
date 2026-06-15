import 'package:cloud_firestore/cloud_firestore.dart';

/// عنصر ستوري واحد — صورة أو فيديو (نمط إنستجرام).
class StoryItem {
  const StoryItem({
    required this.type, required this.url, this.durationSec = 5});

  final String type; // 'image' | 'video'
  final String url;
  final int durationSec; // مدة عرض الصورة (الفيديو بطوله)

  bool get isVideo => type == 'video';

  factory StoryItem.fromMap(Map<String, dynamic> m) => StoryItem(
        type: (m['type'] ?? 'image').toString(),
        url: (m['url'] ?? '').toString(),
        durationSec: (m['durationSec'] ?? 5) as int,
      );
}

/// ستوري — مجموعة عناصر (صور/فيديو) لمتجر أو إعلان، بنمط إنستجرام.
/// الوثيقة `stories/{id}`: { title, ringImage, storeId?, active, sortOrder,
///   items:[{type,url,durationSec}], expiresAt? } — وتتحمّل صيغة مبسّطة
///   (image/video مفرد) للتوافق مع لافتات الستوري القديمة.
class DyarStory {
  const DyarStory({
    required this.id, required this.title, this.ringImage,
    this.storeId, this.items = const []});

  final String id;
  final String title;
  final String? ringImage; // صورة الحلقة الدائرية
  final String? storeId;
  final List<StoryItem> items;

  /// أول صورة للحلقة إن لم تُحدَّد ringImage.
  String? get cover => ringImage ??
      (items.isNotEmpty ? items.firstWhere(
          (i) => !i.isVideo, orElse: () => items.first).url : null);

  factory DyarStory.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final rawItems = d['items'];
    final items = <StoryItem>[];
    if (rawItems is List) {
      for (final e in rawItems) {
        if (e is Map) items.add(StoryItem.fromMap(Map<String, dynamic>.from(e)));
      }
    }
    // توافق: صيغة مفردة image/video/imageUrl
    if (items.isEmpty) {
      final v = d['video']?.toString();
      final img = (d['image'] ?? d['imageUrl'])?.toString();
      if (v != null && v.isNotEmpty) items.add(StoryItem(type: 'video', url: v));
      if (img != null && img.isNotEmpty) items.add(StoryItem(type: 'image', url: img));
    }
    return DyarStory(
      id: doc.id,
      title: (d['title'] ?? '').toString(),
      ringImage: d['ringImage']?.toString(),
      storeId: d['storeId']?.toString(),
      items: items,
    );
  }
}
