import 'package:dicyvpn/ui/components/server_selector.dart';
import 'package:dicyvpn/ui/theme/colors.dart';
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
                child: ServerSelector(_backgroundColor),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
