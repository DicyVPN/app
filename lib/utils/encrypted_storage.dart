import 'package:flutter_secure_storage/flutter_secure_storage.dart';

AndroidOptions _getAndroidOptions() => const AndroidOptions();

FlutterSecureStorage? _storage;

FlutterSecureStorage getStorage() {
  return _storage ??= FlutterSecureStorage(aOptions: _getAndroidOptions());
}
