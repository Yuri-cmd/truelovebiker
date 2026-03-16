import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static const _storage = FlutterSecureStorage();

  static const _keyToken = 'token';
  static const _keyUser = 'user_data';
  static const _keyUserId = 'user_id';
  static const _keyBikerId = 'biker_id';

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  static Future<void> saveUser(String userData) async {
    await _storage.write(key: _keyUser, value: userData);
  }

  static Future<String?> getUser() async {
    return await _storage.read(key: _keyUser);
  }

  static Future<void> saveUserId(int id) async {
    await _storage.write(key: _keyUserId, value: id.toString());
  }

  static Future<int?> getUserId() async {
    final id = await _storage.read(key: _keyUserId);
    return id != null ? int.tryParse(id) : null;
  }

  static Future<void> saveBikerId(int id) async {
    await _storage.write(key: _keyBikerId, value: id.toString());
  }

  static Future<int?> getBikerId() async {
    final id = await _storage.read(key: _keyBikerId);
    return id != null ? int.tryParse(id) : null;
  }

  static Future<void> clearSession() async {
    await _storage.deleteAll();
  }
}
