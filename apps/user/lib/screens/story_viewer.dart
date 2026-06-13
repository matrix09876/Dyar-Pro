import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// عارض ستوري بنمط إنستجرام: أشرطة تقدّم علوية، تقدّم تلقائي لكل عنصر،
/// نقر يمين/يسار للتالي/السابق، ضغط مطوّل للإيقاف المؤقت، سحب/✕ للإغلاق.
/// الصور مؤقّتة؛ عناصر الفيديو تُفتح بالمشغّل الخارجي (تشغيل مضمّن لاحقًا
/// بإضافة حزمة video_player عند توفّر الشبكة).
class StoryViewer extends StatefulWidget {
  const StoryViewer({super.key, required this.stories, this.startIndex = 0});
  final List<DyarStory> stories;
  final int startIndex;

  @override
  State<StoryViewer> createState() => _StoryViewerState();
}

class _StoryViewerState extends State<StoryViewer>
    with SingleTickerProviderStateMixin {
  late int _story = widget.startIndex;
  int _item = 0;
  late final AnimationController _ctrl;

  DyarStory get _current => widget.stories[_story];
  StoryItem? get _media =>
      _current.items.isEmpty ? null : _current.items[_item];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this)
      ..addStatusListener((s) {
        if (s == AnimationStatus.completed) _next();
      });
    _start();
  }

  void _start() {
    _ctrl.stop();
    _ctrl.reset();
    final secs = _media?.durationSec ?? 5;
    _ctrl.duration = Duration(seconds: secs.clamp(2, 15));
    _ctrl.forward();
    setState(() {});
  }

  void _next() {
    if (_item < _current.items.length - 1) {
      _item++;
    } else if (_story < widget.stories.length - 1) {
      _story++;
      _item = 0;
    } else {
      Navigator.of(context).pop();
      return;
    }
    _start();
  }

  void _prev() {
    if (_item > 0) {
      _item--;
    } else if (_story > 0) {
      _story--;
      _item = 0;
    }
    _start();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final m = _media;
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (d) {
          final w = MediaQuery.of(context).size.width;
          // RTL: يمين الشاشة = السابق، يسار = التالي
          d.globalPosition.dx > w / 2 ? _prev() : _next();
        },
        onLongPressStart: (_) => _ctrl.stop(),
        onLongPressEnd: (_) => _ctrl.forward(),
        onVerticalDragEnd: (d) {
          if ((d.primaryVelocity ?? 0) > 200) Navigator.of(context).pop();
        },
        child: Stack(children: [
          // الوسائط
          Positioned.fill(
            child: m == null
                ? const SizedBox()
                : m.isVideo
                    ? _VideoPlaceholder(url: m.url)
                    : CachedNetworkImage(
                        imageUrl: m.url, fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                            child: CircularProgressIndicator(
                                color: Colors.white24)),
                      ),
          ),
          // أشرطة التقدّم + الترويسة
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Column(children: [
                Row(
                  children: [
                    for (int i = 0; i < _current.items.length; i++)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: _SegmentBar(
                            controller: _ctrl,
                            state: i < _item
                                ? 1.0
                                : (i == _item ? null : 0.0),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(children: [
                  Container(
                    height: 34, width: 34,
                    decoration: const BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white24),
                    clipBehavior: Clip.antiAlias,
                    child: _current.cover != null
                        ? CachedNetworkImage(
                            imageUrl: _current.cover!, fit: BoxFit.cover)
                        : const Icon(Icons.storefront,
                            color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_current.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800)),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ]),
              ]),
            ),
          ),
          // عنصر فيديو: زر تشغيل خارجي
          if (m != null && m.isVideo)
            Center(
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: DyarTokens.brand),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('تشغيل الفيديو'),
                onPressed: () => launchUrl(Uri.parse(m.url),
                    mode: LaunchMode.externalApplication),
              ),
            ),
        ]),
      ),
    );
  }
}

/// شريط تقدّم لشريحة واحدة: state=1 مكتمل · 0 لم يبدأ · null = الحالي (متحرّك).
class _SegmentBar extends StatelessWidget {
  const _SegmentBar({required this.controller, this.state});
  final AnimationController controller;
  final double? state;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        height: 3,
        child: state != null
            ? LinearProgressIndicator(
                value: state,
                backgroundColor: Colors.white30,
                valueColor: const AlwaysStoppedAnimation(Colors.white))
            : AnimatedBuilder(
                animation: controller,
                builder: (_, __) => LinearProgressIndicator(
                    value: controller.value,
                    backgroundColor: Colors.white30,
                    valueColor:
                        const AlwaysStoppedAnimation(Colors.white)),
              ),
      ),
    );
  }
}

class _VideoPlaceholder extends StatelessWidget {
  const _VideoPlaceholder({required this.url});
  final String url;
  @override
  Widget build(BuildContext context) => Container(
        color: const Color(0xFF111317),
        alignment: Alignment.center,
        child: const Icon(Icons.movie_creation_outlined,
            color: Colors.white24, size: 80),
      );
}
