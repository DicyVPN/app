import 'dart:developer';

import 'package:dicyvpn/ui/api/dto.dart';
import 'package:dicyvpn/ui/components/button.dart';
import 'package:dicyvpn/ui/components/server_selector.dart';
import 'package:dicyvpn/ui/theme/colors.dart';
import 'package:dicyvpn/vpn/vpn.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  static const _backgroundColor = CustomColors.gray800;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: SizedBox(
          height: double.infinity,
          width: double.infinity,
          child: Material(
            color: _backgroundColor,
            elevation: 4,
            textStyle: TextStyle(color: CustomColors.gray200),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    StatusCard(),
                    ServerSelector(_backgroundColor),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StatusCard extends StatelessWidget {
  const StatusCard({super.key});

  @override
  Widget build(BuildContext context) {
    var statusNotifier = VPN.get().status;
    var lastServerNotifier = VPN.get().lastServer;

    return ListenableBuilder(
      listenable: Listenable.merge([statusNotifier, lastServerNotifier]),
      builder: (context, child) {
        log('StatusCard has rebuilt');
        var lastServer = lastServerNotifier.value;
        if (lastServer == null) {
          return Column(
            children: [
              const Text('Server is null'),
              Button(
                  onPressed: () {
                    lastServerNotifier.value = Server(
                      id: 'id',
                      name: 'name',
                      type: ServerType.primary,
                      country: 'country',
                      city: 'city',
                      load: 0,
                    );
                  },
                  theme: CustomButtonTheme.dark,
                  color: CustomButtonColor.green,
                  size: CustomButtonSize.normal,
                  child: const Text('Click me to set server')),
            ],
          );
        }
        return Column(
          children: [
            Text(
                'Server: ${lastServer.id}, ${lastServer.name}, ${lastServer.type}, ${lastServer.country}, ${lastServer.city}'),
            Button(
                onPressed: () {
                  lastServerNotifier.value = Server(
                    id: 'id2',
                    name: 'name2',
                    type: ServerType.primary,
                    country: 'country2',
                    city: 'city2',
                    load: 0,
                  );
                },
                theme: CustomButtonTheme.dark,
                color: CustomButtonColor.green,
                size: CustomButtonSize.normal,
                child: const Text('Click me to set new server')),
          ],
        );
      },
    );
  }
}
