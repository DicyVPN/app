import 'dart:developer';

import 'package:dicyvpn/ui/api/dto.dart';
import 'package:dicyvpn/ui/components/server_selector.dart';
import 'package:dicyvpn/ui/components/status_card.dart';
import 'package:dicyvpn/ui/theme/colors.dart';
import 'package:dicyvpn/vpn/status.dart';
import 'package:dicyvpn/vpn/vpn.dart';
import 'package:dicyvpn/vpn/wireguard/wireguard.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  static const _backgroundColor = CustomColors.gray800;
  static const _textColor = CustomColors.gray200;
  static ValueNotifier<Status> statusNotifier = VPN.get().status;
  static ValueNotifier<Server?> lastServerNotifier = VPN.get().lastServer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
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
              const Material(
                color: _backgroundColor,
                elevation: 4,
                textStyle: TextStyle(color: _textColor),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: ServerSelector(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onStatusCardButtonClick() {
    WireGuard.get().requestPermission().then((_) {
      log('PERMISSION IS GRANTED');
    }).catchError((e) {
      log('Got a permission rejected error', error: e);
    });
    // if (statusNotifier.value == Status.connected) {
    //   VPN.get().stop(false, lastServerNotifier.value);
    // } else {
    //   VPN.get().connect(lastServerNotifier.value!, lastServerNotifier.value);
    // }
  }
}
