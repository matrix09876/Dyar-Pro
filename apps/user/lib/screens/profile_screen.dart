import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import 'login_screen.dart';
import 'addresses_screen.dart';
import 'bookings_screen.dart';
import 'notifications_screen.dart';

/// حسابي: المحفظة، العناوين، الإشعارات، اللغة (3 لغات)، الوضع الليلي،
/// ادعُ واربح (رمز مشاركة)، استرداد بطاقة هدية، الخروج — كلها مربوطة.
class UserProfileScreen extends ConsumerWidget {
  const UserProfileScreen({super.key});

  static String _inviteCode(String uid) =>
      'DY${uid.substring(0, uid.length.clamp(0, 6)).toUpperCase()}';

  Future<void> _redeemGift(BuildContext context, WidgetRef ref, String uid) async {
    final s = ref.read(stringsProvider);
    final code = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s('redeemGift')),
        content: TextField(controller: code,
            textDirection: TextDirection.ltr,
            decoration: const InputDecoration(labelText: 'CODE')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false),
              child: Text(s('cancel'))),
          FilledButton(onPressed: () => Navigator.pop(ctx, true),
              child: Text(s('confirm'))),
        ],
      ),
    );
    if (ok == true && code.text.isNotEmpty) {
      try {
        await ref.read(userServiceProvider).redeemGiftCard(uid, code.text.trim());
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(s('orderPlaced'))));
        }
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(s('error'))));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final lang = ref.watch(langProvider);
    final dark = ref.watch(darkModeProvider);
    final user = FirebaseAuth.instance.currentUser;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(s('profile'),
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),

          if (user == null)
            DyarCard(
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const UserLoginScreen())),
              child: Row(children: [
                const Icon(LucideIcons.logIn, color: DyarTokens.brand),
                const SizedBox(width: 10),
                Text(s('signIn'),
                    style: const TextStyle(
                        color: DyarTokens.brand,
                        fontWeight: FontWeight.w700)),
              ]),
            )
          else ...[
            // المحفظة (الرصيد الحي من users/{uid})
            StreamBuilder<AppUser?>(
              stream: ref.read(userServiceProvider).watch(user.uid),
              builder: (context, snap) => DyarCard(
                child: Row(children: [
                  const Icon(LucideIcons.wallet, color: DyarTokens.brand),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s('wallet'))),
                  MoneyText(snap.data?.walletBalance ?? 0,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16)),
                ]),
              ),
            ),
            const SizedBox(height: 10),
            _Tile(
              icon: LucideIcons.mapPin,
              label: s('myAddresses'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const AddressesScreen())),
            ),
            const SizedBox(height: 10),
            _Tile(
              icon: LucideIcons.calendarDays,
              label: s('myBookings'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const MyBookingsScreen())),
            ),
            const SizedBox(height: 10),
            // مكالمة حية مع تاليا — وكيلة خدمة العملاء الصوتية
            _Tile(
              icon: LucideIcons.headphones,
              label: s('talkToTalya'),
              onTap: () => launchUrl(Uri.parse(kTalyaTalkUrl),
                  mode: LaunchMode.externalApplication),
            ),
            const SizedBox(height: 10),
            _Tile(
              icon: LucideIcons.bell,
              label: s('notifications'),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const NotificationsScreen())),
            ),
            const SizedBox(height: 10),
            // ادعُ واربح — رمز المشاركة الفريد
            DyarCard(
              child: Row(children: [
                const Icon(LucideIcons.gift, color: DyarTokens.brand),
                const SizedBox(width: 10),
                Expanded(child: Text(s('inviteEarn'))),
                SelectableText(_inviteCode(user.uid),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        color: DyarTokens.brand,
                        letterSpacing: 2)),
              ]),
            ),
            const SizedBox(height: 10),
            _Tile(
              icon: LucideIcons.creditCard,
              label: s('redeemGift'),
              onTap: () => _redeemGift(context, ref, user.uid),
            ),
          ],
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

          if (user != null)
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

class _Tile extends StatelessWidget {
  const _Tile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DyarCard(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, color: DyarTokens.brand),
        const SizedBox(width: 10),
        Expanded(child: Text(label)),
        const Icon(Icons.chevron_left, size: 18),
      ]),
    );
  }
}
