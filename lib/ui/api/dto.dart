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

@JsonSerializable()
class ServerList {
  final Map<String, List<Server>> primary;
  final Map<String, List<Server>> secondary;

  ServerList(this.primary, this.secondary);

  factory ServerList.fromJson(Map<String, dynamic> json) => _$ServerListFromJson(json);
}

@JsonSerializable()
class ConnectionInfo {
  final String serverIp;
  final String publicKey;
  final String? privateKey;
  final String internalIp;
  final ConnectionPorts ports;

  ConnectionInfo(this.serverIp, this.publicKey, this.privateKey, this.internalIp, this.ports);

  factory ConnectionInfo.fromJson(Map<String, dynamic> json) => _$ConnectionInfoFromJson(json);
}

@JsonSerializable()
class ConnectionPorts {
  final ProtocolPorts wireguard;
  final ProtocolPorts openvpn;

  ConnectionPorts(this.wireguard, this.openvpn);

  factory ConnectionPorts.fromJson(Map<String, dynamic> json) => _$ConnectionPortsFromJson(json);
}

@JsonSerializable()
class ProtocolPorts {
  final List<int> udp;
  final List<int> tcp;

  ProtocolPorts(this.udp, this.tcp);

  factory ProtocolPorts.fromJson(Map<String, dynamic> json) => _$ProtocolPortsFromJson(json);
}
