import 'dart:convert';
import 'dart:developer';
import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dicyvpn/utils/encrypted_storage.dart';
import 'package:dicyvpn/utils/navigation_key.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:package_info_plus/package_info_plus.dart';

part 'api.g.dart';

const _baseUrl = 'https://api.dicyvpn.com';
const _tag = 'DicyVPN/API';

class PublicAPI {
  static PublicAPI? _instance;

  static Future<PublicAPI> get() async {
    return _instance ??= PublicAPI._internal(await _getDioClient());
  }

  PublicAPI._internal(this.dio);

  final Dio dio;

  Future<Response> login(String email, String password) {
    return dio.post('/login', data: {
      'email': email,
      'password': password,
      'isDevice': true,
    });
  }

  Future<Response> refreshToken(String refreshToken, String refreshTokenId, String accountId) {
    return dio.post('/refresh-token', data: {
      'refreshToken': refreshToken,
      'refreshTokenId': refreshTokenId,
      'accountId': accountId,
    });
  }

  static Future<Dio> _getDioClient() async {
    return Dio(BaseOptions(
      baseUrl: '$_baseUrl/v1/public',
      headers: <String, String>{
        'User-Agent': await _getUserAgent(),
      },
    ));
  }
}

class API {
  static API? _instance;

  static Future<API> get() async {
    var storage = getStorage();
    _token = await storage.read(key: 'auth.token');
    return _instance ??= API._internal(await _getDioClient(storage));
  }

  API._internal(this.dio);

  static String? _token;
  final Dio dio;

  Future<ServerList> getServersList() async {
    var response = await dio.get('/servers/list');
    return ServerList.fromJson(response.data);
  }

  Future<Response> logout() {
    return dio.get('/logout');
  }

  static Future<void> setAuthInfo(Headers headers) async {
    _token = headers.value('X-Auth-Token');
    var refreshToken = headers.value('X-Auth-Refresh-Token');
    var privateKey = headers.value('X-Auth-Private-Key');
    var payload = base64.normalize(_token!.split('.')[1]); // pad the base64 string with '='

    var object = json.decode(utf8.decode(base64.decode(payload)));
    var refreshTokenId = object['refreshTokenId'];
    var accountId = object['_id'];

    var storage = getStorage();
    await Future.wait([
      storage.write(key: 'auth.token', value: _token),
      storage.write(key: 'auth.refreshToken', value: refreshToken),
      storage.write(key: 'auth.refreshTokenId', value: refreshTokenId),
      storage.write(key: 'auth.accountId', value: accountId),
      storage.write(key: 'auth.privateKey', value: privateKey),
    ]);

    log('Token has been set, accountId: $accountId', name: _tag);
  }

  static Future<void> removeAuthInfo({String? reason}) async {
    var storage = getStorage();
    await Future.wait([
      storage.delete(key: 'auth.token'),
      storage.delete(key: 'auth.refreshToken'),
      storage.delete(key: 'auth.refreshTokenId'),
      storage.delete(key: 'auth.accountId'),
      storage.delete(key: 'auth.privateKey'),
    ]);

    navigationKey.currentState?.pushNamedAndRemoveUntil('/login', (route) => false, arguments: reason);
  }

  static Future<void> _setNewToken(Headers headers) {
    _token = headers.value('X-Auth-Token');
    return getStorage().write(key: 'auth.token', value: _token);
  }

  static String? _getToken() {
    return _token;
  }

  static Future<Dio> _getDioClient(FlutterSecureStorage storage) async {
    var dio = Dio(BaseOptions(
      baseUrl: '$_baseUrl/v1',
      headers: <String, String>{
        'User-Agent': await _getUserAgent(),
      },
    ));

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          var token = _getToken();
          options.headers['Authorization'] = 'Bearer $token';
          return handler.next(options);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          // unauthorized, refresh the token
          if (error.response?.statusCode == 401) {
            log('Token has expired, refreshing', name: _tag);
            var refreshToken = await storage.read(key: 'auth.refreshToken') ?? '';
            var refreshTokenId = await storage.read(key: 'auth.refreshTokenId') ?? '';
            var accountId = await storage.read(key: 'auth.accountId') ?? '';

            try {
              var refreshResponse = await PublicAPI.get().then((api) {
                return api.refreshToken(refreshToken, refreshTokenId, accountId);
              });

              _setNewToken(refreshResponse.headers);
            } on DioException {
              log('Failed to refresh token, logging out', name: _tag);
              await removeAuthInfo(reason: tr('sessionExpiredLoginAgain'));
              return handler.next(error);
            }

            log('Token has been refreshed, retrying request', name: _tag);
            try {
              return handler.resolve(await dio.fetch(error.requestOptions));
            } on DioException catch (e) {
              return handler.next(e);
            }
          }
          return handler.next(error);
        },
      ),
    );

    return dio;
  }
}

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

  Server({
    required this.id,
    required this.name,
    required this.type,
    required this.country,
    required this.city,
    required this.load,
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

Future<String> _getUserAgent() async {
  DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();

  var platformInfo = 'Unknown';

  if (Platform.isAndroid) {
    AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
    bool isTV = androidInfo.systemFeatures.contains('android.software.leanback');
    String abi = androidInfo.supportedAbis.isEmpty ? 'Unknown ABI' : androidInfo.supportedAbis.first;
    platformInfo = '(Android${isTV ? ' TV' : ''} ${androidInfo.version.release};'
        ' SDK${androidInfo.version.sdkInt}; $abi; ${androidInfo.board};'
        ' ${androidInfo.manufacturer}; ${androidInfo.model})';
  } else if (Platform.isIOS) {
    IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
    platformInfo = '(iOS ${iosInfo.systemVersion}';
  } else if (Platform.isLinux) {
    LinuxDeviceInfo linuxInfo = await deviceInfo.linuxInfo;
    platformInfo = '(Linux ${linuxInfo.name} ${linuxInfo.version})';
  } else if (Platform.isMacOS) {
    MacOsDeviceInfo macOsDeviceInfo = await deviceInfo.macOsInfo;
    platformInfo = '(macOS ${macOsDeviceInfo.osRelease})';
  } else if (Platform.isWindows) {
    WindowsDeviceInfo windowsDeviceInfo = await deviceInfo.windowsInfo;
    platformInfo = '(Windows ${windowsDeviceInfo.buildNumber})';
  }

  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  return 'DicyVPN/${packageInfo.version} ($platformInfo)';
}
