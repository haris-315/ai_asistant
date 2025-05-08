  import 'package:ai_asistant/core/services/session_store_service.dart';

Future<Map<String, dynamic>> getHeaders({Map<String, dynamic>? extra}) async {
    final String token = await SecureStorage.getToken() ?? "";
    // "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJpLmFyc2xhbmtoYWxpZEBvdXRsb29rLmNvbSJ9.6CHm10Iqv9h5FOqY2dsJdRhFP0abcyUstljKbPlUR4A";
    print(token);
    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
      if (extra != null) ...extra,
    };
  }
