// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

// ignore_for_file: non_constant_identifier_names

class ChatModel {
  final String id;
  final String role;
  final String content;

  ChatModel({required this.id, required this.role, required this.content});

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'id': id, 'role': role, 'content': content};
  }

  factory ChatModel.fromMap(Map<String, dynamic> map) {
    return ChatModel(
      id: map['id'] ?? "",
      role: map['role'] ?? "",
      content: map['content'] ?? "",

    );
  }

  String toJson() => json.encode(toMap());

  factory ChatModel.fromJson(String source) =>
      ChatModel.fromMap(json.decode(source) as Map<String, dynamic>);
}
