import 'package:dicyvpn/vpn/status.dart';
import 'package:flutter/services.dart';

import 'wireguard.dart';

/// A class that implements the WireGuard interface using Flutter method channels.
class WireGuardMethodChannel implements WireGuard {
  static const _methodChannel =
      MethodChannel('wireguard_native.dicyvpn.com/method');
  static const _eventChannel =
      EventChannel('wireguard_native.dicyvpn.com/event');

  /// Requests permission to use WireGuard.
  @override
  Future<void> requestPermission() {
    return _methodChannel.invokeMethod('requestPermission');
  }

  /// Starts the WireGuard connection with the specified configuration and address.
  @override
  Future<void> start(String config, String address) {
    return _methodChannel
        .invokeMethod('start', {'config': config, 'address': address});
  }

  /// Stops the WireGuard connection.
  @override
  Future<void> stop() {
    return _methodChannel.invokeMethod('stop');
  }

  /// Retrieves the current status of the WireGuard connection.
  @override
  Future<Status> getStatus() {
    return _methodChannel
        .invokeMethod<String>('getStatus')
        .then((value) => Status.values.byName(value!));
  }

  /// Retrieves a stream of status updates for the WireGuard connection.
  @override
  Stream<Status> getStatusStream() {
    return _eventChannel
        .receiveBroadcastStream()
        .map((event) => Status.values.byName(event));
  }
}
