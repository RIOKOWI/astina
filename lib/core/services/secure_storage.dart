import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  SecureStorageService()
    : _storage = const FlutterSecureStorage(
        aOptions: AndroidOptions(encryptedSharedPreferences: true),
      );

  final FlutterSecureStorage _storage;

  static const _tokenKey = 'auth_token';
  static const _userKey = 'cached_user';
  static const _biometricEnabledKey = 'biometric_enabled';

  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> getToken() async {
    return _storage.read(key: _tokenKey);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  Future<void> saveUser(String userJson) async {
    await _storage.write(key: _userKey, value: userJson);
  }

  Future<String?> getUser() async {
    return _storage.read(key: _userKey);
  }

  Future<void> clearUser() async {
    await _storage.delete(key: _userKey);
  }

  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  Future<void> setValue(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  Future<String?> getValue(String key) async {
    return _storage.read(key: key);
  }

  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }

  Future<void> setBiometricEnabled(bool value) async {
    await _storage.write(key: _biometricEnabledKey, value: value.toString());
  }

  Future<bool> isBiometricEnabled() async {
    final v = await _storage.read(key: _biometricEnabledKey);
    return v == 'true';
  }
}
