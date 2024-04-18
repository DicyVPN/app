import 'package:dicyvpn/login.dart';
import 'package:dicyvpn/ui/theme/theme.dart';
import 'package:dicyvpn/utils/encrypted_storage.dart';
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
      initialRoute: '/startup',
      routes: {
        '/startup': (context) => const Startup(),
        '/login': (context) => const Login(),
        '/logout': (context) => const Text('logout page'),
        '/home': (context) => const Text('home page'),
      },
    );
  }
}

class Startup extends StatelessWidget {
  const Startup({super.key});

  @override
  Widget build(BuildContext context) {
    var storage = getStorage();
    storage.containsKey(key: 'auth.refreshToken').then((value) {
      if (value) {
        Navigator.popAndPushNamed(context, '/home');
      } else {
        Navigator.popAndPushNamed(context, '/login');
      }
    });

    return const Center(); // empty widget
  }
}
