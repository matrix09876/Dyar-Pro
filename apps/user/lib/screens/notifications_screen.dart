import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

/// الإشعارات: قائمة لحظية مربوطة بمجموعة notifications + تعليم كمقروء.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Scaffold(
          appBar: AppBar(title: Text(s('notifications'))),
          body: EmptyState(message: s('signIn'), icon: LucideIcons.bell));
    }
    return Scaffold(
      appBar: AppBar(title: Text(s('notifications'))),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ref.read(userServiceProvider).watchNotifications(uid),
        builder: (context, snap) {
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return EmptyState(message: s('noData'), icon: LucideIcons.bell);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final n = items[i];
              final read = n['read'] == true;
              return DyarCard(
                onTap: read
                    ? null
                    : () => ref
                        .read(userServiceProvider)
                        .markNotificationRead(n['id'] as String),
                child: Row(children: [
                  Icon(read ? LucideIcons.bell : LucideIcons.bellRing,
                      color: read ? DyarTokens.inkMuted : DyarTokens.brand),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n['title']?.toString() ?? '',
                            style: TextStyle(
                                fontWeight:
                                    read ? FontWeight.w500 : FontWeight.w800)),
                        Text(n['body']?.toString() ?? '',
                            style: const TextStyle(
                                fontSize: 13, color: DyarTokens.inkMuted)),
                      ],
                    ),
                  ),
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
