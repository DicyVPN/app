import 'dart:io' show Platform;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:package_info_plus/package_info_plus.dart';

const _baseUrl = 'https://api.dicyvpn.com';

class PublicAPI {
  static PublicAPI? _instance;

  static Future<PublicAPI> get() async {
    return _instance ??= PublicAPI._internal(await _getDioClient());
  }

  PublicAPI._internal(this.dio);

  final Dio dio;

  Future<Response> login(String email, String password) {
    return dio.post('/login', data: {
      'email': email, // TODO: this body is not working for some reason
      'password': password,
      'isDevice': true,
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
