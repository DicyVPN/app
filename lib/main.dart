import 'package:dicyvpn/login.dart';
import 'package:dicyvpn/ui/theme/theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en', 'US'), Locale('de', 'DE')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en', 'US'),
      child: const DicyVPN(),
    ),
  );
}

class DicyVPN extends StatelessWidget {
  const DicyVPN({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DicyVPN',
      theme: ThemeData(
        colorScheme: customColorScheme,
        useMaterial3: true,
      ),
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      home: const Main(),
    );
  }
}

class Main extends StatelessWidget {
  const Main({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Login(),
    );
  }
}
