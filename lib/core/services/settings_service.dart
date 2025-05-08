import 'package:shared_preferences/shared_preferences.dart';

class SettingsService {
  static storeSetting(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
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
