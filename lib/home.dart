/// The [Home] widget is a stateless widget that represents the main screen of the application.
/// It displays a navigation rail on large screens and a navigation drawer on small screens.
/// The main content of the screen is displayed in the [MainColumn] widget, which contains
/// a status card and a server selector.
///
/// The [NavigationItem] class represents an item in the navigation rail or drawer.
/// It contains an icon, a label, and an `onClick` callback function.
///
/// The [MainColumn] class is a stateless widget that represents the main content of the screen.
/// It contains a status card and a server selector. The status card displays the current VPN status
/// and allows the user to connect or disconnect from the VPN. The server selector allows the user
/// to select a VPN server to connect to.
///
/// The [MainColumn] class also contains helper methods for handling button clicks and server selection,
/// as well as methods for checking if the user has agreed to use secondary servers and displaying
/// an agreement dialog if necessary.

import 'dart:developer';

import 'package:dicyvpn/ui/api/dto.dart';
import 'package:dicyvpn/ui/components/custom_app_bar.dart';
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
import 'package:flutter_svg/flutter_svg.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    var navigationItems = [
      NavigationItem(
        icon: const Icon(Icons.home),
        label: Text(tr('navigationHome')),
        onClick: () {},
      ),
      NavigationItem(
        icon: const Icon(Icons.settings),
        label: Text(tr('navigationSettings')),
        onClick: () => navigationKey.currentState?.pushNamed('/settings'),
      ),
      NavigationItem(
        icon: const Icon(Icons.logout),
        label: Text(tr('navigationLogout')),
        onClick: () => navigationKey.currentState?.pushNamed('/logout'),
      ),
    ];

    bool isLargeScreen = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      appBar: !isLargeScreen ? CustomAppBar.getAppBar(canGoBack: false) : null,
      body: SafeArea(
        child: isLargeScreen
            ? Row(
                children: [
                  NavigationRail(
                    onDestinationSelected: (int index) {
                      navigationItems[index].onClick();
                    },
                    destinations: [
                      for (var item in navigationItems) ...[
                        NavigationRailDestination(
                          icon: item.icon,
                          label: item.label,
                        ),
                      ],
                    ],
                    selectedIndex: 0,
                  ),
                  Expanded(
                    flex: 4,
                    child: Container(
                      color: CustomColors.gray800,
                      height: double.infinity,
                      width: double.infinity,
                      child: ClipRect(
                        child: Transform.scale(
                          scale: 1.5,
                          child: SvgPicture.asset(
                            'assets/images/world_map.svg',
                            fit: BoxFit.cover,
                            colorFilter: const ColorFilter.mode(CustomColors.gray100, BlendMode.srcIn),
                            width: double.infinity,
                            excludeFromSemantics: true,
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(flex: 6, child: MainColumn()),
                ],
              )
            : MainColumn(),
      ),
      drawer: !isLargeScreen
          ? NavigationDrawer(
              onDestinationSelected: (index) {
                Navigator.of(context).pop(); // close the drawer
                navigationItems[index].onClick();
              },
              children: [
                for (var item in navigationItems) ...[
                  NavigationDrawerDestination(
                    icon: item.icon,
                    label: item.label,
                  ),
                ],
              ],
            )
          : null,
    );
  }
}

class NavigationItem {
  final Icon icon;
  final Text label;
  final VoidCallback onClick;

  NavigationItem({required this.icon, required this.label, required this.onClick});
}

class MainColumn extends StatelessWidget {
  static const _backgroundColor = CustomColors.gray800;
  static const _textColor = CustomColors.gray200;
  static ValueNotifier<Status> statusNotifier = VPN.get().status;
  static ValueNotifier<Server?> lastServerNotifier = VPN.get().lastServer;

  final ScrollController _controller = ScrollController();

  MainColumn({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
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
              child: ServerSelector(_textColor, (server) async {
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
      } catch (e) {
        log('Unhandled error', error: e);
        ScaffoldMessenger.of(navigationKey.currentContext!).showSnackBar(SnackBar(
          content: Text(e.toString()),
        ));
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
