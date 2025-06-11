// ignore_for_file: constant_identifier_names

import 'package:ai_asistant/core/services/native_bridge.dart';
import 'package:ai_asistant/data/models/service_models/meeting.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

enum DBs {
  MEETINGS(
    name: "meetings.db",
    creationQuery: """
    CREATE TABLE IF NOT EXISTS meetings (
            id TEXT PRIMARY KEY,
            title TEXT,
            startTime TEXT,
            endTime TEXT,
            actualTranscript TEXT,
            summary TEXT,
            keypoints TEXT
          )
""",
  ),
  REPORTS(
    name: "reports.db",
    creationQuery: """
    CREATE TABLE IF NOT EXISTS reports (
            day TEXT,
            hash TEXT,
            summary TEXT,
            PRIMARY KEY (hash)
          )
""",
  );

  final String name;
  final String creationQuery;

  const DBs({required this.name, required this.creationQuery});
}

class MeetingDatabaseHelper {
  static Future<Database> getDatabase({required DBs dbd}) async {
    String path = await NativeBridge.getDbPath();
    return await openDatabase(
      "$path/${dbd.name}",
      version: 1,
      onCreate: (db, version) {
        db.execute(dbd.creationQuery);
      },
    );
  }

  static Future<List<Map<String, String>>> getAllEmailReportsWithDay() async {
    try {
      final db = await getDatabase(dbd: DBs.REPORTS);
      db.rawQuery("""CREATE TABLE IF NOT EXISTS reports (
                    day TEXT,
                    hash TEXT,
                    summary TEXT,
                    PRIMARY KEY (hash)
                )""");
      final result = await db.query(
        'reports',
        columns: ['day', 'summary'],
        orderBy: 'day DESC',
      );

      final reports =
          result
              .map(
                (e) => {
                  'day': e['day'] as String,
                  'summary': e['summary'] as String,
                },
              )
              .toList();

      if (kDebugMode) {
        print('Retrieved $reports email reports');
      }
      return reports;
    } catch (e) {
      if (kDebugMode) {
        print('Error retrieving all email reports: $e');
      }
      throw Exception('Failed to retrieve email reports: $e');
    }
  }

  static Future<List<Meeting>> getAllMeetings() async {
    final db = await getDatabase(dbd: DBs.REPORTS);
    final result = await db.query('meetings', orderBy: 'startTime DESC');
    return result.map((e) => Meeting.fromMap(e)).toList();
  }

  static Future<DeletionStates> deleteMeeting(String id) async {
    try {
      final db = await getDatabase(dbd: DBs.REPORTS);
      final result = await db.delete(
        'meetings',
        where: 'id = ?',
        whereArgs: [id],
      );
      if (result > 0) {
        return DeletionStates.deleted;
      } else {
        return DeletionStates.error;
      }
    } catch (e) {
      if (kDebugMode) {
        print(e);
      }
      return DeletionStates.error;
    }
  }
}

enum DeletionStates {
  deleted(info: "Meeting has been deleted."),
  error(info: "There was an error.");

  final String info;

  const DeletionStates({required this.info});
}
