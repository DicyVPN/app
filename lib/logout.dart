import 'dart:developer';

import 'package:dicyvpn/ui/api/api.dart';
import 'package:dicyvpn/ui/components/button.dart';
import 'package:dicyvpn/ui/theme/colors.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class Logout extends StatefulWidget {
  const Logout({super.key});

  @override
  State<Logout> createState() => _LogoutState();
}

class _LogoutState extends State<Logout> {
  bool _loading = false;

  void _logoutAction() {
    if (!_loading) {
      logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CustomColors.gray800,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(tr('logoutTitle'), style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 16),
              Text(tr('logoutMessage')),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Button(
                    onPressed: () => Navigator.pop(context),
                    color: CustomButtonColor.transparent,
                    enabled: !_loading,
                    child: Text(tr('logoutLabelGoBack')),
                  ),
                  Button(
                    onPressed: _logoutAction,
                    color: CustomButtonColor.blue,
                    enabled: !_loading,
                    child: Text(tr('logoutLabelSignOut')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Logs out the user by making an API call to logout and removing the authentication information.
  /// Displays error messages if there is an error during the logout process.
  void logout() async {
    setState(() {
      _loading = true;
    });

    try {
      final api = await API.get();
      await api.logout();
      await API.removeAuthInfo();
    } on DioException catch (e) {
      if (e.response != null) {
        Response response = e.response!;
        log("Received error: ${response.data.toString()}", name: 'DicyVPN/Logout', error: e);

        if (!mounted) {
          return;
        }

        var message = response.data is String ? response.data : response.data['message'];
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: ${message ?? ''}'),
        ));
      } else {
        debugPrintStack();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(tr('unknownNetworkErrorTryAgain')),
          ));
        }
      }
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }
}
