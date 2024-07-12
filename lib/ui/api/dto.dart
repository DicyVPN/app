import 'package:json_annotation/json_annotation.dart';

part 'dto.g.dart';

enum ServerType {
  primary,
  secondary;
}

@JsonSerializable()
class Server {
  @JsonKey(fromJson: _stringOrIntToString)
  final String id;
  final String name;
  final ServerType type;
  final String country;
  final String city;
  final double load;
  final bool free;

  Server({
    required this.id,
    required this.name,
    required this.type,
    required this.country,
    required this.city,
    required this.load,
    required this.free,
  });

  factory Server.fromJson(Map<String, dynamic> json) => _$ServerFromJson(json);

  static String _stringOrIntToString(dynamic value) {
    if (value is int) {
      return value.toString();
    } else if (value is String) {
      return value;
    } else {
      throw ArgumentError('Invalid type for id: $value');
    }
  }
}

/// Class representing a list of servers.
@JsonSerializable()
class ServerList {
  final Map<String, List<Server>> primary;
  final Map<String, List<Server>> secondary;

  /// Constructor for the ServerList class.
  ServerList(this.primary, this.secondary);

  /// Factory method to create a ServerList instance from JSON.
  factory ServerList.fromJson(Map<String, dynamic> json) => _$ServerListFromJson(json);
}

/// Class representing connection information.
@JsonSerializable()
class ConnectionInfo {
  final String serverIp;
  final String publicKey;
  final String? privateKey;
  final String internalIp;
  final ConnectionPorts ports;

  /// Constructor for the ConnectionInfo class.
  ConnectionInfo(this.serverIp, this.publicKey, this.privateKey, this.internalIp, this.ports);

  /// Factory method to create a ConnectionInfo instance from JSON.
  factory ConnectionInfo.fromJson(Map<String, dynamic> json) => _$ConnectionInfoFromJson(json);
}

/// Class representing connection ports.
@JsonSerializable()
class ConnectionPorts {
  final ProtocolPorts wireguard;
  final ProtocolPorts openvpn;

  /// Constructor for the ConnectionPorts class.
  ConnectionPorts(this.wireguard, this.openvpn);

  /// Factory method to create a ConnectionPorts instance from JSON.
  factory ConnectionPorts.fromJson(Map<String, dynamic> json) => _$ConnectionPortsFromJson(json);
}

/// Class representing protocol ports.
@JsonSerializable()
class ProtocolPorts {
  final List<int> udp;
  final List<int> tcp;

  /// Constructor for the ProtocolPorts class.
  ProtocolPorts(this.udp, this.tcp);

  /// Factory method to create a ProtocolPorts instance from JSON.
  factory ProtocolPorts.fromJson(Map<String, dynamic> json) => _$ProtocolPortsFromJson(json);
}
