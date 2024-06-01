// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Server _$ServerFromJson(Map<String, dynamic> json) => Server(
      id: Server._stringOrIntToString(json['id']),
      name: json['name'] as String,
      type: $enumDecode(_$ServerTypeEnumMap, json['type']),
      country: json['country'] as String,
      city: json['city'] as String,
      load: (json['load'] as num).toDouble(),
      free: json['free'] as bool,
    );

Map<String, dynamic> _$ServerToJson(Server instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$ServerTypeEnumMap[instance.type]!,
      'country': instance.country,
      'city': instance.city,
      'load': instance.load,
      'free': instance.free,
    };

const _$ServerTypeEnumMap = {
  ServerType.primary: 'primary',
  ServerType.secondary: 'secondary',
};

ServerList _$ServerListFromJson(Map<String, dynamic> json) => ServerList(
      (json['primary'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) => Server.fromJson(e as Map<String, dynamic>))
                .toList()),
      ),
      (json['secondary'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
            k,
            (e as List<dynamic>)
                .map((e) => Server.fromJson(e as Map<String, dynamic>))
                .toList()),
      ),
    );

Map<String, dynamic> _$ServerListToJson(ServerList instance) =>
    <String, dynamic>{
      'primary': instance.primary,
      'secondary': instance.secondary,
    };

ConnectionInfo _$ConnectionInfoFromJson(Map<String, dynamic> json) =>
    ConnectionInfo(
      json['serverIp'] as String,
      json['publicKey'] as String,
      json['privateKey'] as String?,
      json['internalIp'] as String,
      ConnectionPorts.fromJson(json['ports'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ConnectionInfoToJson(ConnectionInfo instance) =>
    <String, dynamic>{
      'serverIp': instance.serverIp,
      'publicKey': instance.publicKey,
      'privateKey': instance.privateKey,
      'internalIp': instance.internalIp,
      'ports': instance.ports,
    };

ConnectionPorts _$ConnectionPortsFromJson(Map<String, dynamic> json) =>
    ConnectionPorts(
      ProtocolPorts.fromJson(json['wireguard'] as Map<String, dynamic>),
      ProtocolPorts.fromJson(json['openvpn'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ConnectionPortsToJson(ConnectionPorts instance) =>
    <String, dynamic>{
      'wireguard': instance.wireguard,
      'openvpn': instance.openvpn,
    };

ProtocolPorts _$ProtocolPortsFromJson(Map<String, dynamic> json) =>
    ProtocolPorts(
      (json['udp'] as List<dynamic>).map((e) => e as int).toList(),
      (json['tcp'] as List<dynamic>).map((e) => e as int).toList(),
    );

Map<String, dynamic> _$ProtocolPortsToJson(ProtocolPorts instance) =>
    <String, dynamic>{
      'udp': instance.udp,
      'tcp': instance.tcp,
    };
