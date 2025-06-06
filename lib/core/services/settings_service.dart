import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static storeSetting(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<T> customSetting<T>(Function(SharedPreferences sprefs) fn) async {
    final prefs = await SharedPreferences.getInstance();
    return await fn(prefs);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString("access_token");
  }

  static getSetting(String key) async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString(key);
  }

  static removeSetting(String key) async {
    final prefs = await SharedPreferences.getInstance();

    return await prefs.remove(key);
  }
}
