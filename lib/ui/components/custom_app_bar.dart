import 'package:dicyvpn/ui/theme/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class CustomAppBar {
  static AppBar getAppBar({required bool canGoBack}) {
    return AppBar(
      backgroundColor: CustomColors.gray600,
      centerTitle: true,
      title: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Container(
          constraints: const BoxConstraints(maxHeight: 40),
          child: Image.asset('assets/images/full_logo.png', semanticLabel: tr('dicyvpnLogo')),
        ),
      ),
      leading: Builder(
        builder: (context) {
          if (canGoBack) {
            return IconButton(
              icon: const Icon(Icons.arrow_back),
              tooltip: tr('menuLabel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            );
          }
          return IconButton(
            icon: const Icon(Icons.menu),
            tooltip: tr('menuLabel'),
            onPressed: () {
              Scaffold.of(context).openDrawer();
            },
          );
        },
      ),
    );
  }
}
