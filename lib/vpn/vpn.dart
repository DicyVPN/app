import 'dart:developer';

import 'package:dicyvpn/ui/api/api.dart';
import 'package:dicyvpn/ui/api/dto.dart';
import 'package:dicyvpn/utils/encrypted_storage.dart';
import 'package:dicyvpn/vpn/status.dart';
import 'package:dicyvpn/vpn/wireguard/wireguard_flutter.dart';
import 'package:dicyvpn/vpn/wireguard/wireguard_flutter_platform_interface.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

class VPN {
  static VPN? _instance;

  static Future<void> initialize() async {
    if (_instance == null) {
      final wireGuard = WireGuardFlutter.instance;
      Server? lastServer = await _getLastServer();
      _instance = VPN._internal(wireGuard, lastServer);
    }
  }

  static VPN get() {
    if (_instance == null) {
      throw StateError('Must call VPN.initialize() before calling VPN.get()');
    }
    return _instance!;
  }

  VPN._internal(this._wireGuard, Server? lastServer) {
    _wireGuard.vpnStageSnapshot.listen(_handleVpnStageChange);
    _wireGuard.stage().then(_handleVpnStageChange);
    this.lastServer = ValueNotifier(lastServer);
    this.lastServer.addListener(_onLastServerChanged);
  }

  final ValueNotifier<Status> status = ValueNotifier(Status.disconnected);
  late final ValueNotifier<Server?> lastServer;
  final WireGuardFlutterInterface _wireGuard;
  final String _tag = 'DicyVPN/VPN';
  final List<void Function()> _waitForStoppedCallbacks = List.empty(growable: true);

  Future<void> connect(Server server, Server? currentServer) async {
    await stop(true, currentServer, newServer: server);
    status.value = Status.connecting;
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

    await _stopWireGuard();
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
      await _wireGuard.startVpn(
        serverAddress: endpoint,
        wgQuickConfig: config,
        providerBundleIdentifier: packageInfo.packageName,
      );
    } catch (e) {
      // user might have not given permission for starting a VPN yet
      log('Error while starting VPN', name: _tag, error: e);
      status.value = Status.disconnected;
    }
  }

  Future<void> _stopWireGuard() {
    return _wireGuard.stopVpn().then((value) => status.value = Status.disconnected);
  }

  _getWireGuardConfig(ConnectionInfo info, String endpoint, String privateKey, String packageName) async {
    var dns = ['1.1.1.1', '1.1.0.0'];

    return '''
           [Interface]
           PrivateKey = $privateKey
           Address = ${info.internalIp}/32
           DNS = ${dns.join(', ')}
           ExcludedApplications = $packageName
           
           [Peer]
           PublicKey = ${info.publicKey}
           Endpoint = $endpoint
           PersistentKeepalive = 15
           AllowedIPs = 0.0.0.0/0, ::/0'''
        .replaceAll('\n           ', '\n');
  }

  void _handleVpnStageChange(VpnStage stage) {
    log('VPN Stage updated: $stage', name: _tag);

    switch (stage) {
      case VpnStage.connected:
        status.value = Status.connected;
      case VpnStage.connecting:
        status.value = Status.connecting;
      case VpnStage.disconnecting:
        status.value = Status.disconnecting;
      case VpnStage.disconnected:
        status.value = Status.disconnected;
      case VpnStage.waitingConnection:
        status.value = Status.connecting;
      case VpnStage.authenticating:
        status.value = Status.connecting;
      case VpnStage.reconnect:
        status.value = Status.connecting;
      case VpnStage.noConnection: // TODO might be useful alongside other cases
        status.value = Status.disconnected;
      case VpnStage.preparing:
        status.value = Status.connecting;
      case VpnStage.denied:
        status.value = Status.disconnected;
      case VpnStage.exiting:
        status.value = Status.disconnected;
    }

    if (status.value == Status.disconnected) {
      _waitForStoppedCallbacks.removeWhere((callback) {
        callback();
        return true;
      });
    }
  }

  void _waitForStopped(Future<void> Function() callback) {
    _wireGuard.stage().then((stage) {
      if (stage == VpnStage.noConnection || stage == VpnStage.disconnected) {
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
  log('Loaded last server: $id, $name, $type, $country, $city');
  return Server(id: id, name: name!, type: type, country: country!, city: city!, load: 0.0);
}
