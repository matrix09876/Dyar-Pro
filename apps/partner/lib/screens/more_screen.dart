import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import 'shell.dart';

/// "المزيد": تقييم المتجر + اللغة + الوضع الليلي + الخروج.
/// (مواعيد العمل، مناطق التوصيل، الطابعة... تُضاف تباعًا بنفس النمط.)
class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(langProvider);
    final dark = ref.watch(darkModeProvider);
    final store = ref.watch(myStoreProvider).value;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (store != null)
          DyarCard(
            child: Row(
              children: [
                const Icon(LucideIcons.star, color: DyarTokens.warning),
                const SizedBox(width: 10),
                Expanded(child: Text(s('rating'))),
                Text('${store.rating} (${store.ratingCount})',
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              ],
            ),
          ),
        const SizedBox(height: 10),
        DyarCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(LucideIcons.languages),
                const SizedBox(width: 10),
                Text(s('language'),
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 12),
              SegmentedButton<DyarLang>(
                segments: DyarLang.values
                    .map((l) =>
                        ButtonSegment(value: l, label: Text(l.label)))
                    .toList(),
                selected: {lang},
                onSelectionChanged: (v) =>
                    ref.read(langProvider.notifier).state = v.first,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        DyarCard(
          child: Row(
            children: [
              const Icon(LucideIcons.moon),
              const SizedBox(width: 10),
              Expanded(child: Text(s('darkMode'))),
              Switch(
                value: dark,
                activeThumbColor: DyarTokens.brand,
                onChanged: (v) =>
                    ref.read(darkModeProvider.notifier).state = v,
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        DyarCard(
          onTap: () => ref.read(authServiceProvider).signOut(),
          child: Row(
            children: [
              const Icon(LucideIcons.logOut, color: DyarTokens.danger),
              const SizedBox(width: 10),
              Text(s('logout'),
                  style: const TextStyle(
                      color: DyarTokens.danger,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ],
    );
  }
}
