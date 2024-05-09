import 'package:flutter/services.dart';

import 'wireguard.dart';


class WireGuardMethodChannel implements WireGuard {
  static const _methodChannel = MethodChannel('wireguard_native.dicyvpn.com/method');
  static const _eventChannel = EventChannel('wireguard_native.dicyvpn.com/event');

  @override
  Future<void> requestPermission() {
    return _methodChannel.invokeMethod('requestPermission');
  }
}
