import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Returns the Android options for secure storage.
AndroidOptions _getAndroidOptions() => const AndroidOptions(encryptedSharedPreferences: true);

/// The instance of [FlutterSecureStorage] used for secure storage.
FlutterSecureStorage? _storage;

/// Returns the singleton instance of [FlutterSecureStorage].
///
/// If the [_storage] instance is null, it creates a new instance of [FlutterSecureStorage]
/// with the Android options obtained from [_getAndroidOptions()] and assigns it to [_storage].
/// Subsequent calls to [getStorage()] will return the same instance of [FlutterSecureStorage].
FlutterSecureStorage getStorage() {
  return _storage ??= FlutterSecureStorage(aOptions: _getAndroidOptions());
}
