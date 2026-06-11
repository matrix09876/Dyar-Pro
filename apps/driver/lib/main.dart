import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import 'screens/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // إعدادات Firebase تُولَّد لاحقًا بـ flutterfire configure (firebase_options.dart)
  // اشتراك بث الإشعارات: تطبيق السائق = جمهور drivers
  await initDyarFirebase(broadcastTopic: 'role-drivers');
  runApp(const ProviderScope(child: DriverApp()));
}

class DriverApp extends ConsumerWidget {
  const DriverApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final dark = ref.watch(darkModeProvider);
    return MaterialApp(
      title: 'Dyar Driver',
      debugShowCheckedModeBanner: false,
      theme: DyarTheme.light(),
      darkTheme: DyarTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      locale: lang.locale,
      supportedLocales: const [Locale('ar'), Locale('he'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => Directionality(
        textDirection: lang.direction,
        child: AppLockGate(child: child ?? const SizedBox()),
      ),
      home: const AuthGate(),
    );
  }
}
