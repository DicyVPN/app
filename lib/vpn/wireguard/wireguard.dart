import 'dart:io';

import 'package:flutter/foundation.dart';

import 'wireguard_method_channel.dart';

abstract interface class WireGuard {
  static WireGuard? _instance;

  static WireGuard get() {
    if (_instance == null) {
      if (kIsWeb) {
        throw UnsupportedError('The web platform is not supported');
      } else if (Platform.isLinux) {
        // _instance = WireGuardLinux(); // TODO-linux
      } else {
        _instance = WireGuardMethodChannel();
      }
    }
    return _instance!;
  }

  Future<void> requestPermission();
}
