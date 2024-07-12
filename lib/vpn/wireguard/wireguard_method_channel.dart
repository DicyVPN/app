import 'package:dicyvpn/vpn/status.dart';
import 'package:flutter/services.dart';
import 'wireguard.dart';

class WireGuardMethodChannel implements WireGuard {
  static const _methodChannel =
      MethodChannel('wireguard_native.dicyvpn.com/method');
  static const _eventChannel =
      EventChannel('wireguard_native.dicyvpn.com/event');

  @override
  Future<void> requestPermission() {
    return _methodChannel.invokeMethod('requestPermission');
  }

  @override
  Future<void> start(String config, String address) {
    return _methodChannel
        .invokeMethod('start', {'config': config, 'address': address});
  }

  @override
  Future<void> stop() {
    return _methodChannel.invokeMethod('stop');
  }

  @override
  Future<Status> getStatus() {
    return _methodChannel
        .invokeMethod<String>('getStatus')
        .then((value) => Status.values.byName(value!));
  }

  @override
  Stream<Status> getStatusStream() {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => Status.values.byName(event));
  }
}
