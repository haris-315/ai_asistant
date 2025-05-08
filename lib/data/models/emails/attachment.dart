// ignore_for_file: public_member_api_docs, sort_constructors_first, non_constant_identifier_names
import 'dart:convert';
import 'dart:typed_data';

class Attachment {
  final String id;
  final String name;
  final int size;
  final String content_type;
  final Uint8List content_bytes;

  Attachment({
    required this.id,
    required this.name,
    required this.size,
    required this.content_type,
    required this.content_bytes,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'size': size,
      'content_type': content_type,
      // 🛠️ Corrected: encode the bytes to base64 string
      'content_bytes': base64Encode(content_bytes),
    };
  }

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      id: map['id'] as String,
      name: map['name'] as String,
      size: map['size'] as int,
      content_type: map['content_type'] as String,
      // 🛠️ Corrected: decode base64 string to bytes
      content_bytes: base64Decode(map['content_bytes'] as String),
    );
  }

  String toJson() => json.encode(toMap());

  factory Attachment.fromJson(String source) =>
      Attachment.fromMap(json.decode(source) as Map<String, dynamic>);
}
