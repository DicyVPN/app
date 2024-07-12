import 'package:dicyvpn/utils/navigation_key.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

/// Opens a dialog with the given [message].
/// 
/// The [title] parameter is optional and specifies the title of the dialog.
/// The [link] parameter is optional and specifies a URL to be launched when the link button is pressed.
/// The [linkText] parameter is optional and specifies the text to be displayed on the link button.
/// 
/// Returns a [Future] that resolves to the value returned by the dialog.
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