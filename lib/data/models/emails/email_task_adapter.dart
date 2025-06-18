import 'package:ai_asistant/data/models/emails/email_task.dart';
import 'package:hive/hive.dart';

class EmailTaskAdapter extends TypeAdapter<EmailTask> {
  @override
  final int typeId = 104;

  @override
  EmailTask read(BinaryReader reader) {
    return EmailTask(
      content: reader.readString(),
      description: reader.readString(),
      priority: reader.readInt(),
    );
  }

  @override
  void write(BinaryWriter writer, EmailTask obj) {
    writer.writeString(obj.content);
    writer.writeString(obj.description);
    writer.writeInt(obj.priority);
  }
}
