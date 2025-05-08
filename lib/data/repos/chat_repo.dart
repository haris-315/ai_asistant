import 'dart:convert';
import 'package:ai_asistant/core/shared/constants.dart';
import 'package:ai_asistant/data/models/chats/session_model.dart';
import 'package:ai_asistant/data/repos/headers.dart';
import 'package:dio/dio.dart';

class ChatRepo {
  var dio = Dio();

  // Future<List<Map<String, dynamic>>> startNewSession({
  //   String? title = "New Session",
  //   String? model = "gpt-4-turbo",
  //   String? systemPrompt = "",
  //   String? category = "General",
  // }) async {
  //   var data = json.encode({
  //     "model": model,
  //     "title": title,
  //     "category": category,
  //     "system_prompt": systemPrompt,
  //   });
  //   var headers = await getHeaders();
  //   var response = await dio.request(
  //     '${AppConstants.baseUrl}chat/start',
  //     options: Options(method: 'POST', headers: headers),
  //     data: data,
  //   );

  //   if (response.statusCode == 200) {
  //     print(json.encode(response.data));
  //     return await getChatSessions();
  //   } else {
  //     print(response.statusMessage);
  //     throw response.statusMessage ??
  //         "There was an error creating new session.";
  //   }
  // }

  Future<List<Map<String, dynamic>>> getChatSessions() async {
    var headers = await getHeaders();
    var response = await dio.get(
      '${AppConstants.baseUrl}chat/sessions',
      options: Options(headers: headers),
    );
    if (response.statusCode == 200) {
      List<Map<String, dynamic>> chatSessions = List<Map<String, dynamic>>.from(
        response.data,
      );

      return chatSessions;
    } else {
      print(response.statusMessage);
      throw response.statusMessage ?? "There was an error!";
    }
  }

  Future<List<Map<String, dynamic>>> deleteSession(String id) async {
    var response = await dio.request(
      '${AppConstants.baseUrl}chat/$id',
      options: Options(method: 'DELETE', headers: await getHeaders()),
    );

    if (response.statusCode == 200) {
      print(json.encode(response.data));
      return await getChatSessions();
    } else {
      print(response.statusMessage);
      throw response.statusMessage ??
          "There was an error deleting session id: $id";
    }
  }

  Future<void> renameSession() async {
    var headers = {
      'Authorization':
          'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJpLmFyc2xhbmtoYWxpZEBvdXRsb29rLmNvbSJ9.6CHm10Iqv9h5FOqY2dsJdRhFP0abcyUstljKbPlUR4A',
      'Content-Type': 'application/json',
    };
    var data = json.encode({"title": "Coding Assistant Pro"});
    var dio = Dio();
    var response = await dio.request(
      '${AppConstants.baseUrl}chat/518c8049-e005-4b8a-92fa-200e33f40c14/rename',
      options: Options(method: 'PATCH', headers: headers),
      data: data,
    );

    if (response.statusCode == 200) {
      print(json.encode(response.data));
    } else {
      print(response.statusMessage);
    }
  }

  Future<Map> sendMessage({
    required bool isNewSession,
    required String message,
    String model = "gpt-4-turbo",
    required String sessionId,
  }) async {
    final headers = await getHeaders(
      // extra: {"Content-Type": "application/json"},
    );
    var data = {"model": model, "content": message};
    if (!isNewSession) {
      data['session_id'] = sessionId;
    }
    print(data);
    var response = await dio.request(
      '${AppConstants.baseUrl}chat/message',
      options: Options(method: 'POST', headers: headers),
      data: data,
    );
    print(response.data);
    print("$model and $sessionId and $message");
    if (response.statusCode == 200) {
      return response.data;
    } else {
      throw response.statusMessage ?? "Got an error while  sending message.";
    }
  }

  Future<SessionModel> getSingleSession(String sessionId) async {
    final headers = await getHeaders();
    var response = await dio.request(
      '${AppConstants.baseUrl}chat/sessions/$sessionId',
      options: Options(method: 'GET', headers: headers),
    );

    if (response.statusCode == 200) {
      print(json.encode(response.data));
      return SessionModel.fromMap(response.data);
    } else {
      print(response.statusMessage);
      throw "Failed to load chat session.";
    }
  }
}
