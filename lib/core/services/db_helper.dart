import 'package:ai_asistant/core/services/native_bridge.dart';
import 'package:ai_asistant/data/models/service_models/meeting.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class MeetingDatabaseHelper {
  static Future<Database> getDatabase() async {
    final dir = await NativeBridge.getDbPath();
    final dbPath = dir;

    return await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) {
        db.execute('''
          CREATE TABLE IF NOT EXISTS meetings (
            id TEXT PRIMARY KEY,
            title TEXT,
            startTime TEXT,
            endTime TEXT,
            actualTranscript TEXT,
            summary TEXT
          )
        ''');
      },
    );
  }

  static Future<List<Meeting>> getAllMeetings() async {
    final db = await getDatabase();
    final result = await db.query('meetings', orderBy: 'startTime DESC');
    return result.map((e) => Meeting.fromMap(e)).toList();
  }

  static Future<DeletionStates> deleteMeeting(String id) async {
    try {
      final db = await getDatabase();
      final result = await db.delete('meetings', where: 'id = ?', whereArgs: [id]);
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
