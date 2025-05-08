import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  static final _storage = const FlutterSecureStorage();
  static const _key = "access_token";

  static Future<void> storeToken(String token) async {
    await _storage.write(key: _key, value: token);
  }

  static Future<String?> getToken() async {
    return await _storage.read(key: _key);
  }

  static Future<void> deleteToken() async {
    await _storage.delete(key: _key);
  }
}
