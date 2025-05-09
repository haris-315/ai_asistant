  import 'package:ai_asistant/core/services/session_store_service.dart';

Future<Map<String, dynamic>> getHeaders({Map<String, dynamic>? extra}) async {
    final String token = await SecureStorage.getToken() ?? "";

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      if (extra != null) ...extra,
    };
  }
