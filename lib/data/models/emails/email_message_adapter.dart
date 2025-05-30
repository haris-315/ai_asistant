import 'package:hive/hive.dart';
import 'package:ai_asistant/data/models/emails/thread_detail.dart';

class HiveEmailAdapter extends TypeAdapter<EmailMessage> {
  @override
  final int typeId = 0; // Unique ID for the adapter

  @override
  EmailMessage read(BinaryReader reader) {
    return EmailMessage(
      id: reader.readString(),
      subject: reader.readString(),
      senderName: reader.readString(),
      sender: reader.readString(),
      recipients: reader.readList().cast<String>(),
      cc: reader.readList().cast<String>(),
      receivedAt: DateTime.parse(reader.readString()),
      isRead: reader.readBool(),
      hasAttachments: reader.readBool(),
      bodyPreview: reader.readString(),
      bodyPlain: reader.readString(),
      bodyHtml: reader.readString(),
      quick_replies: reader.readList().cast<String>(),
      summary: reader.readString(),
      topic: reader.readString(),
      ai_draft: reader.readString(),
    );
  }

  @override
  void write(BinaryWriter writer, EmailMessage obj) {
    writer.writeString(obj.id ?? '');
    writer.writeString(obj.subject ?? '');
    writer.writeString(obj.senderName ?? '');
    writer.writeString(obj.sender ?? '');
    writer.writeList(obj.recipients ?? []);
    writer.writeList(obj.cc ?? []);
    writer.writeString(obj.receivedAt?.toIso8601String() ?? '');
    writer.writeBool(obj.isRead ?? false);
    writer.writeBool(obj.hasAttachments ?? false);
    writer.writeString(obj.bodyPreview ?? '');
    writer.writeString(obj.bodyPlain ?? '');
    writer.writeString(obj.bodyHtml ?? '');
    writer.writeList(obj.quick_replies ?? []);
    writer.writeString(obj.summary ?? '');
    writer.writeString(obj.topic ?? '');
    writer.writeString(obj.ai_draft ?? '');
  }
}