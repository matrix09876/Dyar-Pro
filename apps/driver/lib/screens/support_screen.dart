import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// دعم السائق: محادثة حية مع بوت ديار (aiSupportReply يرد تلقائيًا
/// بالخادم) + ردود سريعة جاهزة — مثل التطبيق الحالي وأفضل.
class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  static const _quickReplies = [
    'وين الطلبات؟ 📦',
    'مشكلة في الأرباح 💰',
    'الزبون لا يرد 📞',
    'أحتاج موظف دعم 🧑‍💼',
  ];

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send([String? preset]) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final text = (preset ?? _input.text).trim();
    if (text.isEmpty) return;
    _input.clear();
    await ref.read(supportServiceProvider).send(uid, text);
    await Future.delayed(const Duration(milliseconds: 150));
    if (_scroll.hasClients) {
      _scroll.animateTo(_scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(stringsProvider);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text('${s('support')} 🤖'),
        actions: [
          // مكالمة حية مع تاليا — وكيلة خدمة العملاء الصوتية
          IconButton(
            tooltip: s('talkToTalya'),
            icon: const Icon(LucideIcons.headphones, color: DyarTokens.brand),
            onPressed: () => launchUrl(Uri.parse(kTalyaTalkUrl),
                mode: LaunchMode.externalApplication),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: ref.read(supportServiceProvider).watch(uid),
            builder: (context, snap) {
              final msgs = snap.data ?? const [];
              if (msgs.isEmpty) {
                return EmptyState(
                    message: 'أهلًا بك! كيف نساعدك اليوم؟',
                    icon: LucideIcons.bellRing);
              }
              return ListView.builder(
                controller: _scroll,
                padding: const EdgeInsets.all(16),
                itemCount: msgs.length,
                itemBuilder: (context, i) {
                  final m = msgs[i];
                  final mine = m['senderUid'] == uid;
                  return Align(
                    alignment: mine
                        ? AlignmentDirectional.centerEnd
                        : AlignmentDirectional.centerStart,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      constraints: const BoxConstraints(maxWidth: 280),
                      decoration: BoxDecoration(
                        gradient: mine
                            ? const LinearGradient(colors: [
                                Color(0xFFFF8A3D),
                                DyarTokens.brandDark,
                              ])
                            : null,
                        color: mine ? null : Colors.white,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(16),
                          topRight: const Radius.circular(16),
                          bottomLeft: Radius.circular(mine ? 16 : 4),
                          bottomRight: Radius.circular(mine ? 4 : 16),
                        ),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!mine)
                            const Text('Dyar Bot 🤖',
                                style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                    color: DyarTokens.success)),
                          Text(
                            m['text']?.toString() ?? '',
                            style: TextStyle(
                                color: mine ? Colors.white : null,
                                fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        // ردود سريعة
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.only(start: 12, end: 4),
            children: [
              for (final q in _quickReplies)
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 8),
                  child: ActionChip(
                    label: Text(q, style: const TextStyle(fontSize: 12)),
                    onPressed: () => _send(q),
                  ),
                ),
            ],
          ),
        ),
        // إدخال الرسالة
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(hintText: 'رسالة…'),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  height: 48, width: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [
                      Color(0xFFFF8A3D),
                      DyarTokens.brandDark,
                    ]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(LucideIcons.send,
                      color: Colors.white, size: 20),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }
}
