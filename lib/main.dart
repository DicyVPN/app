import 'dart:developer';
import 'dart:io';

import 'package:dicyvpn/home.dart';
import 'package:dicyvpn/login.dart';
import 'package:dicyvpn/logout.dart';
import 'package:dicyvpn/ui/theme/colors.dart';
import 'package:dicyvpn/ui/theme/theme.dart';
import 'package:dicyvpn/utils/deserialize_preferences.dart';
import 'package:dicyvpn/utils/encrypted_storage.dart';
import 'package:dicyvpn/utils/navigation_key.dart';
import 'package:dicyvpn/vpn/vpn.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
// ignore: depend_on_referenced_packages -- will be removed after 2-3 versions
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await VPN.initialize();

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
      navigatorKey: navigationKey,
      initialRoute: '/startup',
      routes: {
        '/startup': (context) => const Startup(),
        '/login': (context) => const Login(),
        '/logout': (context) => const Logout(),
        '/home': (context) => const Home(),
      },
    );
  }
}

class Startup extends StatelessWidget {
  const Startup({super.key});

  @override
  Widget build(BuildContext context) {
    _loadAuthInfoAndNavigate();

    return Container( // empty widget
      color: CustomColors.gray800,
    );
  }

  void _loadAuthInfoAndNavigate() async {
    var storage = getStorage();
    storage.containsKey(key: 'auth.refreshToken').then((hasRefreshToken) async {
      if (hasRefreshToken) {
        navigationKey.currentState?.popAndPushNamed('/home');
      } else {
        // get auth data from a previous version of the app
        if (Platform.isAndroid) {
          try {
            final directory = await getApplicationSupportDirectory();
            final datastore = File('${directory.path}/datastore/settings.preferences_pb');
            if (directory.existsSync() && datastore.existsSync()) {
              var preferences = deserializePreferencesFile(datastore);
              if (preferences.containsKey('auth.refreshToken')) {
                log('Old preferences file contains auth info, moving to the encrypted storage',
                    name: 'DicyVPN/Startup');
                await Future.wait([
                  storage.write(key: 'auth.token', value: preferences['auth.token']),
                  storage.write(key: 'auth.refreshToken', value: preferences['auth.refreshToken']),
                  storage.write(key: 'auth.refreshTokenId', value: preferences['auth.refreshTokenId']),
                  storage.write(key: 'auth.accountId', value: preferences['auth.accountId']),
                  storage.write(key: 'auth.privateKey', value: preferences['auth.privateKey']),
                ]);
                // remove old auth data
                datastore.delete();
                navigationKey.currentState?.popAndPushNamed('/home');
                return;
              }
            } else {
              log('Old preferences file not found', name: 'DicyVPN/Startup');
            }
          } catch (e) {
            log('Error occurred while trying to import old auth info', name: 'DicyVPN/Startup', error: e);
          }
        }
        navigationKey.currentState?.popAndPushNamed('/login');
      }
    });
  }
}
