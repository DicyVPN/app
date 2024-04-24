import 'package:dicyvpn/utils/navigation_key.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

Future<T?> openDialog<T>(String message, {String? title, String? link, String? linkText}) {
  return showDialog<T>(
    context: navigationKey.currentContext!,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return AlertDialog(
        title: title == null ? null : Text(title),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text(message),
            ],
          ),
        ),
        actions: <Widget>[
          if (link != null)
            TextButton(
              child: Text(tr('dialogClose')),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          TextButton(
            child: Text(linkText ?? tr('dialogClose')),
            onPressed: () {
              if (link != null) {
                launchUrlString(link);
              } else {
                Navigator.pop(context);
              }
            },
          ),
        ],
      );
    },
  );
}