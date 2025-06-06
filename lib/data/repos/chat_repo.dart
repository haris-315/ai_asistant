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
  //
  //     return await getChatSessions();
  //   } else {
  //
  //     throw response.statusMessage ??
  //         "There was an error creating new session.";
  //   }
  // }

  Future<List<Map<String, dynamic>>> getChatSessions() async {
    return _errorWrapper<List<Map<String, dynamic>>>(() async {
      var headers = await getHeaders();
      var response = await dio.get(
        '${AppConstants.baseUrl}chat/sessions',
        options: Options(headers: headers),
      );
      if (response.statusCode == 200) {
        List<Map<String, dynamic>> chatSessions =
            List<Map<String, dynamic>>.from(response.data);

        return chatSessions;
      } else {
        throw response.statusMessage ?? "There was an error!";
      }
    });
  }

  Future<List<Map<String, dynamic>>> deleteSession(String id) async {
    return _errorWrapper<List<Map<String, dynamic>>>(() async {
      var response = await dio.request(
        '${AppConstants.baseUrl}chat/$id',
        options: Options(method: 'DELETE', headers: await getHeaders()),
      );

      if (response.statusCode == 200) {
        return await getChatSessions();
      } else {
        throw response.statusMessage ??
            "There was an error deleting session id: $id";
      }
    });
  }

  Future<void> renameSession() async {
    var headers = await getHeaders();
    var data = json.encode({"title": "Coding Assistant Pro"});
    var dio = Dio();
    var response = await dio.request(
      '${AppConstants.baseUrl}chat/518c8049-e005-4b8a-92fa-200e33f40c14/rename',
      options: Options(method: 'PATCH', headers: headers),
      data: data,
    );

    if (response.statusCode == 200) {
    } else {}
  }

  Future<Map> sendMessage({
    required bool isNewSession,
    required String message,
    String model = "gpt-4-turbo",
    required String sessionId,
  }) async {
    return _errorWrapper<Map>(() async {
      final headers = await getHeaders(
        // extra: {"Content-Type": "application/json"},
      );
      var data = {"model": model, "content": message};
      if (!isNewSession) {
        data['session_id'] = sessionId;
      } 

      var response = await dio.request(
        '${AppConstants.baseUrl}chat/message',
        options: Options(method: 'POST', headers: headers),
        data: data,
      );

      if (response.statusCode == 200) {
        return response.data;
      } else {
        throw response.statusMessage ?? "Got an error while  sending message.";
      }
    });
  }

  Future<SessionModel> getSingleSession(String sessionId) async {
    return _errorWrapper<SessionModel>(() async {
      final headers = await getHeaders();
      var response = await dio.request(
        '${AppConstants.baseUrl}chat/sessions/$sessionId',
        options: Options(method: 'GET', headers: headers),
      );

      if (response.statusCode == 200) {
        return SessionModel.fromMap(response.data);
      } else {
        throw "Failed to load chat session.";
      }
    });
  }

  Future<T> _errorWrapper<T>(Function fn) async {
    try {
      return await fn.call();
    } catch (_) {
      throw "An error occured please try again.";
    }
  }
}
