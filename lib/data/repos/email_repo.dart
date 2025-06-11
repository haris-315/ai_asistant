import 'dart:convert';

import 'package:ai_asistant/core/shared/constants.dart';
import 'package:ai_asistant/data/models/emails/thread_detail.dart';
import 'package:ai_asistant/data/models/threadmodel.dart';
import 'package:ai_asistant/data/repos/headers.dart';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

class EmailRepo {
  final Dio dio = Dio();

  static Future<Box<EmailMessage>> _openBox() async {
    if (!Hive.isBoxOpen('emails')) {
      await Hive.openBox<EmailMessage>('emails');
    }
    return Hive.box<EmailMessage>('emails');
  }

  String _generateHash(EmailMessage email) {
    final content =
        '${email.id}${email.subject}${email.sender}${email.bodyPlain}${email.receivedAt}';
    return md5.convert(utf8.encode(content)).toString();
  }

  Future<List<EmailThread>> getAllEmails({
    int toSkip = 0,
    int tillHowMany = 15,
  }) async {
    try {
      final headers = await getHeaders();
      var response = await dio.request(
        '${AppConstants.baseUrl}email/threads?skip=$toSkip&limit=$tillHowMany',
        options: Options(method: 'GET', headers: headers),
      );

      if (response.statusCode == 200) {
        List<EmailThread> threads =
            (response.data as List)
                .map((e) => EmailThread.fromJson(e))
                .toList();
        return threads;
      } else {
        throw response.statusMessage ?? "There was an error fetching emails";
      }
    } catch (e) {
      throw "An error occurred please try again.";
    }
  }

  static Future<List<EmailMessage>> getEmailsReceivedToday() async {
    try {
      final box = await _openBox();

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final todayEnd = todayStart.add(const Duration(days: 1));

      final todayEmails =
          box.values.where((email) {
            final received = email.receivedAt;
            return received != null &&
                received.isAfter(todayStart) &&
                received.isBefore(todayEnd);
          }).toList();
      print(todayEmails);
      return todayEmails;
    } catch (e) {
      throw "Failed to fetch today's emails: $e";
    }
  }

  Future<List<EmailMessage>> loadMailsInBackground() async {
    try {
      final headers = await getHeaders();
      var response = await dio.request(
        '${AppConstants.baseUrl}email/all-emails/',
        options: Options(method: 'GET', headers: headers),
      );

      if (response.statusCode == 200) {
        List<EmailMessage> emails =
            (response.data['emails'] as List)
                .map((e) => EmailMessage.fromJson(e))
                .toList();
        final box = await _openBox();

        for (var email in emails) {
          final hash = _generateHash(email);
          final existing = box.get(email.id);

          if (existing == null || _generateHash(existing) != hash) {
            await box.put(email.id, email);
          }
        }

        return emails;
      } else {
        throw response.statusMessage ??
            "There was an error while fetching emails";
      }
    } catch (e) {
      print(e);
      throw "An error occurred please try again.";
    }
  }

  Future<List<EmailMessage>> getEmailsBySearch({required String query}) async {
    try {
      final box = await _openBox();
      final queryLower = query.toLowerCase();

      final results =
          box.values
              .where(
                (email) =>
                    (email.subject?.toLowerCase() ?? '').contains(queryLower) ||
                    (email.senderName?.toLowerCase() ?? '').contains(
                      queryLower,
                    ) ||
                    (email.sender?.toLowerCase() ?? '').contains(queryLower) ||
                    (email.bodyPlain?.toLowerCase() ?? '').contains(
                      queryLower,
                    ) ||
                    (email.summary?.toLowerCase() ?? '').contains(queryLower),
              )
              .toList();

      return results;
    } catch (e) {
      throw "An error occurred while searching emails: $e";
    }
  }
}
