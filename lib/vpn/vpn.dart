/// This file contains the implementation of the VPN class, which is responsible for managing the VPN connection.
/// It provides methods for initializing the VPN, connecting to a server, stopping the VPN, and handling status changes.
///
/// The VPN class uses the WireGuard class to interact with the WireGuard VPN protocol.
/// It also uses the API class to communicate with the server API and retrieve connection information.
///
/// The VPN class is a singleton, meaning that there can only be one instance of it.
/// To use the VPN class, you need to call the `initialize` method first, and then you can call the `get` method to retrieve the instance.
///
/// The VPN class also defines the `DNSType` enum, which represents different types of DNS servers.
/// Each DNS type has a list of DNS server addresses associated with it.
///
/// The VPN class throws a `NoSubscriptionException` if there is no subscription available when connecting to a server.
///
/// The `_getLastServer` function is a private function that retrieves the last connected server from the storage.
/// It returns a `Server` object representing the last connected server, or `null` if no server is found.
///
/// Example usage:
///
/// ```dart
/// await VPN.initialize();
/// VPN vpn = VPN.get();
/// vpn.connect(server, currentServer);
/// vpn.stop(isSwitching, currentServer, newServer: newServer);
/// ```

import 'dart:convert';
import 'dart:developer';
import 'dart:io';

import 'package:dicyvpn/ui/api/api.dart';
import 'package:dicyvpn/ui/api/dto.dart';
import 'package:dicyvpn/utils/encrypted_storage.dart';
import 'package:dicyvpn/vpn/status.dart';
import 'package:dicyvpn/vpn/wireguard/wireguard.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum DNSType {
  cloudflare(dns: ['1.1.1.1', '1.1.0.0']),
  google(dns: ['8.8.8.8', '8.8.4.4']),
  custom(dns: []);

  const DNSType({required this.dns});

  final List<String> dns;
}

class VPN {
  static VPN? _instance;

  static Future<void> initialize() async {
    if (_instance == null) {
      Server? lastServer = await _getLastServer();
      _instance = VPN._internal(lastServer);
    }
  }

  static VPN get() {
    if (_instance == null) {
      throw StateError('Must call VPN.initialize() before calling VPN.get()');
    }
    return _instance!;
  }

  VPN._internal(Server? lastServer) {
    _wireGuard.getStatusStream().listen(_handleStatusChange);
    this.lastServer = ValueNotifier(lastServer);
    this.lastServer.addListener(_onLastServerChanged);
  }

  final ValueNotifier<Status> status = ValueNotifier(Status.disconnected);
  late final ValueNotifier<Server?> lastServer;
  final WireGuard _wireGuard = WireGuard.get();
  final String _tag = 'DicyVPN/VPN';
  final List<void Function()> _waitForStoppedCallbacks = List.empty(growable: true);

  Future<void> connect(Server server, Server? currentServer) async {
    status.value = Status.connecting;
    await stop(true, currentServer, newServer: server);
    try {
      var api = await API.get();
      var info = await api.connect(server.id, server.type);

      log('Connecting to a WireGuard ${server.name} (${server.id})', name: _tag);

      _waitForStopped(() => _startWireGuard(info));
    } on DioException catch (e) {
      status.value = Status.disconnected;
      if (e.response != null) {
        Response response = e.response!;
        var reply = response.data['reply'];
        var code = reply['code'];
        var message = reply['message'];

        if (code == 'NO_SUBSCRIPTION') {
          throw NoSubscriptionException();
        }
        throw Exception(message);
      }
    }
  }

  Future<void> stop(bool isSwitching, Server? currentServer, {Server? newServer}) async {
    if (status.value == Status.disconnected) {
      return;
    }

    log('Stopping VPN', name: _tag);
    if (!isSwitching) {
      status.value = Status.disconnecting;
    }

    if (currentServer != null && currentServer.type == ServerType.primary && currentServer.id != newServer?.id) {
      log('Disconnecting from the primary server');
      if (Platform.isIOS) {
        // on iOS we cannot exclude DicyVPN, to successfully complete the API request we must first disconnect
        await _wireGuard.stop();
      }
      try {
        var api = await API.get();
        await api.disconnect(currentServer.id, currentServer.type);
        log('Sent disconnection request for ${currentServer.name} (${currentServer.id})', name: _tag);
      } catch (e) {
        log(
          'Failed to send disconnection request for ${currentServer.name} (${currentServer.id})',
          name: _tag,
          error: e,
        );
      }
    }

    await _wireGuard.stop();
  }

  Future<void> _startWireGuard(ConnectionInfo info) async {
    var port = info.ports.wireguard.udp[0];
    var endpoint = '${info.serverIp}:$port';
    var storage = getStorage();
    var privateKey = info.privateKey ?? await storage.read(key: 'auth.privateKey');
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    var config = await _getWireGuardConfig(info, endpoint, privateKey!, packageInfo.packageName);
    log('WireGuard config: $config', name: _tag);

    try {
      await _wireGuard.start(config, info.serverIp);
    } catch (e) {
      // user might have not given permission for starting a VPN yet
      log('Error while starting VPN', name: _tag, error: e);
      status.value = Status.disconnected;
    }
  }

  /// Generates a WireGuard configuration based on the provided [info], [endpoint], [privateKey], and [packageName].
  /// The configuration includes DNS settings, excluded applications (if applicable), and peer information.
  /// Returns the generated WireGuard configuration as a string.
  Future<String> _getWireGuardConfig(ConnectionInfo info, String endpoint, String privateKey, String packageName) async {
    List<String> dns = DNSType.cloudflare.dns;
    var enableCustomDNS = await getStorage().read(key: 'vpn.useCustomDns') == true.toString();
    if (enableCustomDNS) {
      try {
        var dnsType = await getStorage().read(key: 'vpn.customDnsType');
        var type = DNSType.values.byName(dnsType!);
        if (type == DNSType.custom) {
          var customDnsList = jsonDecode(await getStorage().read(key: 'vpn.dns') ?? '[]');
          if (customDnsList is List && customDnsList.isNotEmpty) {
            dns = [];
            for (var address in customDnsList) {
              dns.add(address);
            }
          }
        } else {
          dns = type.dns;
        }
      } catch (_) {}
    }

    // iOS does not connect if ExcludedApplications is present
    var excludedApplications = Platform.isIOS ? '' : 'ExcludedApplications = $packageName';

    return '''
           [Interface]
           PrivateKey = $privateKey
           Address = ${info.internalIp}/32
           DNS = ${dns.join(', ')}
           $excludedApplications
           
           [Peer]
           PublicKey = ${info.publicKey}
           Endpoint = $endpoint
           PersistentKeepalive = 15
           AllowedIPs = 0.0.0.0/0, ::/0'''
        .replaceAll('\n           ', '\n');
  }

  void _handleStatusChange(Status status) {
    log('VPN status updated: $status', name: _tag);
    this.status.value = status;

    if (status == Status.disconnected) {
      _waitForStoppedCallbacks.removeWhere((callback) {
        callback();
        return true;
      });
    }
  }

  void _waitForStopped(Future<void> Function() callback) {
    _wireGuard.getStatus().then((status) {
      if (status == Status.disconnected) {
        callback();
        return;
      }

      _waitForStoppedCallbacks.add(callback);
    });
  }

  void _onLastServerChanged() {
    Server? newValue = lastServer.value;
    if (newValue != null) {
      var storage = getStorage();
      storage.write(key: 'lastServer.id', value: newValue.id);
      storage.write(key: 'lastServer.name', value: newValue.name);
      storage.write(key: 'lastServer.type', value: newValue.type.name);
      storage.write(key: 'lastServer.country', value: newValue.country);
      storage.write(key: 'lastServer.city', value: newValue.city);
    }
  }
}

class NoSubscriptionException implements Exception {}

Future<Server?> _getLastServer() async {
  var storage = getStorage();
  var id = await storage.read(key: 'lastServer.id');
  if (id == null) {
    return null;
  }

  var name = await storage.read(key: 'lastServer.name');
  var type = ServerType.values.byName((await storage.read(key: 'lastServer.type'))!);
  var country = await storage.read(key: 'lastServer.country');
  var city = await storage.read(key: 'lastServer.city');
  return Server(id: id, name: name!, type: type, country: country!, city: city!, load: 0.0, free: false);
}
