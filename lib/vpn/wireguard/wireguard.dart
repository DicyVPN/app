/// This file contains the interface for the WireGuard VPN implementation.
/// It provides methods for requesting permission, starting and stopping the VPN connection,
/// getting the status of the VPN connection, and streaming the status updates.

import 'dart:io';

import 'package:dicyvpn/vpn/status.dart';
import 'package:flutter/foundation.dart';

import 'wireguard_method_channel.dart';

/// The interface for the WireGuard VPN implementation.
abstract interface class WireGuard {
  static WireGuard? _instance;

  /// Returns the singleton instance of the WireGuard VPN implementation.
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

  /// Requests permission to use the VPN.
  Future<void> requestPermission();

  /// Starts the VPN connection with the specified configuration and address.
  Future<void> start(String config, String address);

  /// Stops the VPN connection.
  Future<void> stop();

  /// Gets the current status of the VPN connection.
  Future<Status> getStatus();

  /// Streams the status updates of the VPN connection.
  Stream<Status> getStatusStream();
}
