// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'api.dart';

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
    );

Map<String, dynamic> _$ServerToJson(Server instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': _$ServerTypeEnumMap[instance.type]!,
      'country': instance.country,
      'city': instance.city,
      'load': instance.load,
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
