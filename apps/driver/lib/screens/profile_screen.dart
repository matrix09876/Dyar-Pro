import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import 'home_screen.dart';
import 'support_screen.dart';

/// حساب السائق: اللغة (3 لغات)، الوضع الليلي، الخروج.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(langProvider);
    final dark = ref.watch(darkModeProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // بطاقة السائق: المركبة + التقييم
          Consumer(builder: (context, ref, _) {
            final d = ref.watch(myDriverProvider).value;
            if (d == null) return const SizedBox.shrink();
            final emoji = switch (d.vehicleType) {
              'motorcycle' => '🏍️',
              'bicycle' => '🚲',
              _ => '🚗',
            };
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: DyarCard(
                child: Row(children: [
                  Text(emoji, style: const TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.plate ?? d.vehicleType,
                            style: const TextStyle(
                                fontWeight: FontWeight.w800)),
                        Text('⭐ ${d.rating}',
                            style: const TextStyle(
                                fontSize: 12,
                                color: DyarTokens.inkMuted)),
                      ],
                    ),
                  ),
                  StatusChip(label: d.status, statusKey: d.status),
                ]),
              ),
            );
          }),
          DyarCard(
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => const SupportScreen())),
            child: Row(children: [
              const Text('🤖', style: TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(child: Text(s('support'))),
              const Icon(Icons.chevron_left, color: DyarTokens.inkMuted),
            ]),
          ),
          const SizedBox(height: 10),
          Text(s('profile'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),

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
                      .map((l) => ButtonSegment(
                          value: l, label: Text(l.label)))
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
      ),
    );
  }
}
