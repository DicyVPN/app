import 'dart:developer';

import 'package:dicyvpn/ui/api/dto.dart';
import 'package:dicyvpn/ui/components/server_selector.dart';
import 'package:dicyvpn/ui/components/status_card.dart';
import 'package:dicyvpn/ui/theme/colors.dart';
import 'package:dicyvpn/utils/dialogs.dart';
import 'package:dicyvpn/utils/encrypted_storage.dart';
import 'package:dicyvpn/utils/navigation_key.dart';
import 'package:dicyvpn/vpn/status.dart';
import 'package:dicyvpn/vpn/vpn.dart';
import 'package:dicyvpn/vpn/wireguard/wireguard.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  Home({super.key});

  static const _backgroundColor = CustomColors.gray800;
  static const _textColor = CustomColors.gray200;
  static ValueNotifier<Status> statusNotifier = VPN.get().status;
  static ValueNotifier<Server?> lastServerNotifier = VPN.get().lastServer;

  final ScrollController _controller = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _controller,
          child: Column(
            children: <Widget>[
              Material(
                color: _backgroundColor,
                elevation: 4,
                textStyle: const TextStyle(color: _textColor),
                child: SizedBox(
                  width: double.maxFinite,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: StatusCard(
                      _backgroundColor,
                      _textColor,
                      statusNotifier: statusNotifier,
                      lastServerNotifier: lastServerNotifier,
                      buttonAction: _onStatusCardButtonClick,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Material(
                color: _backgroundColor,
                elevation: 4,
                textStyle: const TextStyle(color: _textColor),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: ServerSelector((server) async {
                    if (server.type == ServerType.secondary && !await _hasAgreedToUseSecondaryServers()) {
                      _showSecondaryServersAgreement();
                      return;
                    }
                    _controller.animateTo(0, curve: Curves.easeOut, duration: const Duration(milliseconds: 200));
                    _onServerClick(server);
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onStatusCardButtonClick() {
    if (statusNotifier.value == Status.connected) {
      VPN.get().stop(false, lastServerNotifier.value);
    } else {
      _onServerClick(lastServerNotifier.value!);
    }
  }

  void _onServerClick(Server server) {
    WireGuard.get().requestPermission().then((_) async {
      try {
        await VPN.get().connect(server, lastServerNotifier.value);
      } on NoSubscriptionException {
        openDialog(tr('noActiveSubscription'), link: tr('urlPrices'), linkText: tr('takeALookAtOurPlans'));
      } finally {
        lastServerNotifier.value = server;
      }
    }).catchError((e) {
      log('Got a permission rejected error', error: e);
      ScaffoldMessenger.of(navigationKey.currentContext!).showSnackBar(SnackBar(
        content: Text(tr('cannotConnectPermissionDenied')),
      ));
    });
  }

  Future<bool> _hasAgreedToUseSecondaryServers() async {
    var value = await getStorage().read(key: 'agreedToUseSecondaryServers');
    return value == true.toString();
  }

  void _showSecondaryServersAgreement() {
    showDialog(
      context: navigationKey.currentContext!,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(tr('secondaryServersAlertMessage')),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(tr('secondaryServersAlertGoBack')),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text(tr('secondaryServersAlertAgree')),
              onPressed: () async {
                await getStorage().write(key: 'agreedToUseSecondaryServers', value: true.toString());
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
            ),
          ],
        );
      },
    );
  }
}
