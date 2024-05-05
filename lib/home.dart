import 'package:dicyvpn/ui/components/server_selector.dart';
import 'package:dicyvpn/ui/components/status_card.dart';
import 'package:dicyvpn/ui/theme/colors.dart';
import 'package:flutter/material.dart';

class Home extends StatelessWidget {
  const Home({super.key});

  static const _backgroundColor = CustomColors.gray800;
  static const _textColor = CustomColors.gray200;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Material(
                color: _backgroundColor,
                elevation: 4,
                textStyle: TextStyle(color: _textColor),
                child: SizedBox(
                  width: double.maxFinite,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: StatusCard(_backgroundColor, _textColor),
                  ),
                ),
              ),
              SizedBox(height: 8),
              Material(
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
}
