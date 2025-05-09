import 'package:ai_asistant/data/models/threadmodel.dart';
import 'package:ai_asistant/data/repos/headers.dart';
import 'package:dio/dio.dart';

class EmailRepo {
  final dio = Dio();
  Future<List<EmailThread>> getAllEmails({
    int toSkip = 0,
    int tillHowMany = 9,
  }) async {
    try {
      final headers = await getHeaders();
      var response = await dio.request(
        'https://ai-assistant-backend-dk0q.onrender.com/email/threads?skip=$toSkip&limit=$tillHowMany',
        options: Options(method: 'GET', headers: headers),
      );

      if (response.statusCode == 200) {
        // print(response);
        List<EmailThread> threads =
            (response.data as List)
                .map((e) => EmailThread.fromJson(e))
                .toList();
        return threads;
      } else {
        throw response.statusMessage ?? "There was an error fetching emails";
      }
    } catch (e) {
      print(e);
      throw e.toString();
    }
  }

  Future<List<EmailThread>> getEmailsBySearch({
    int toSkip = 0,
    int limit = 15,
    required String query,
  }) async {
    try {
      final headers = await getHeaders();
      var response = await dio.request(
        'https://ai-assistant-backend-dk0q.onrender.com/email/search?skip=$toSkip&limit=$limit&query=$query',
        options: Options(method: 'GET', headers: headers),
      );

      if (response.statusCode == 200) {
        List<EmailThread> threads =
            (response.data as List)
                .map((e) => EmailThread.fromJson(e))
                .toList();
        return threads;
      } else {
        throw response.statusMessage ??
            "There was an error while searching for emails";
      }
    } catch (e) {
      throw e.toString();
    }
  }
}
