// ignore_for_file: public_member_api_docs, sort_constructors_first, non_constant_identifier_names
import 'dart:convert';

import 'package:ai_asistant/data/models/chats/chat_model.dart';

class SessionModel {
  final String id;
  final String model;
  final String system_prompt;
  final String title;
  final String category;

  final List<ChatModel> messages;
  SessionModel({
    required this.id,
    required this.model,
    required this.system_prompt,
    required this.title,
    required this.category,

    required this.messages,
  });

  factory SessionModel.empty({String? id, String? name}) => SessionModel(
    id: id ?? "",
    model: "",
    system_prompt: "",
    title: "",
    category: "",

    messages: [],
  );

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'model': model,
      'system_prompt': system_prompt,
      'title': title,
      'category': category,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
      'messages': messages.map((x) => x.toMap()).toList(),
    };
  }

  factory SessionModel.fromMap(Map<String, dynamic> map) {
    return SessionModel(
      id: map['id'] ?? "",
      model: map['model'] ?? "",
      system_prompt: map['system_prompt'] ?? "",
      title: map['title'] ?? "New Session",
      category: map['category'] ?? "",
      messages: List<ChatModel>.from(
        (map['messages'] as List<dynamic>).map<ChatModel>(
          (x) => ChatModel.fromMap(x as Map<String, dynamic>),
        ),
      ),
    );
  }

  String toJson() => json.encode(toMap());

  factory SessionModel.fromJson(String source) =>
      SessionModel.fromMap(json.decode(source) as Map<String, dynamic>);

  SessionModel copyWith({
    String? id,
    String? model,
    String? system_prompt,
    String? title,
    String? category,
    List<ChatModel>? messages,
  }) {
    return SessionModel(
      id: id ?? this.id,
      model: model ?? this.model,
      system_prompt: system_prompt ?? this.system_prompt,
      title: title ?? this.title,
      category: category ?? this.category,
      messages: messages ?? this.messages,
    );
  }
}
