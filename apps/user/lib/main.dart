import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dyar_core/dyar_core.dart';
import 'package:dyar_ui/dyar_ui.dart';

import 'screens/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initDyarFirebase();
  runApp(const ProviderScope(child: DyarUserApp()));
}

class DyarUserApp extends ConsumerWidget {
  const DyarUserApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(langProvider);
    final dark = ref.watch(darkModeProvider);
    return MaterialApp(
      title: 'Dyar',
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
        child: child ?? const SizedBox(),
      ),
      home: const UserShell(),
    );
  }
}
