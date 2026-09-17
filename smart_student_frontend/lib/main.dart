import 'package:flutter/material.dart';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'providers/settings_provider.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  await dotenv.load(fileName: '.env');


  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ar')],
      path: 'assets/translations', // path to translation files
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'),
      child: ChangeNotifierProvider(
        create: (_) => SettingsProvider(),
        child: const SmartStudentApp(),
      ),
    ),
  );
}

class SmartStudentApp extends StatelessWidget {
  const SmartStudentApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch the provider — rebuilds automatically on any settings change
    final settings = context.watch<SettingsProvider>();

    return MaterialApp(
      title: 'Smart Student Helper',
      debugShowCheckedModeBanner: false,
      // ── Theming ──────────────────────────────────────────────────────────
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: settings.themeMode,
      // ── Localisation ─────────────────────────────────────────────────────
      locale: context.locale,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      home: const AnimatedSplashScreen(),
    );
  }
}