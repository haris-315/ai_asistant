import 'package:ai_asistant/core/services/settings_service.dart';

Future<Map<String, dynamic>> getHeaders({Map<String, dynamic>? extra}) async {
  final String token = await SettingsService.getToken() ?? "";

  return {
    'Authorization': 'Bearer $token',
    'Content-Type': 'application/json',
    if (extra != null) ...extra,
  };
}
