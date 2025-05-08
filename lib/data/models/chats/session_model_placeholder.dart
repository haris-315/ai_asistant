// ignore_for_file: public_member_api_docs, sort_constructors_first, non_constant_identifier_names
import 'dart:convert';


class SessionModelHolder {
  final String id;
  final String model;
  final String system_prompt;
  final String title;
  final String category;


  SessionModelHolder({
    required this.id,
    required this.model,
    required this.system_prompt,
    required this.title,
    required this.category,

  });

  factory SessionModelHolder.empty() => SessionModelHolder(
    id: "",
    model: "",
    system_prompt: "",
    title: "",
    category: "",


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

    };
  }

  factory SessionModelHolder.fromMap(Map<String, dynamic> map) {
    return SessionModelHolder(
      id: map['id'] ?? "",
      model: map['model'] ?? "",
      system_prompt: map['system_prompt'] ?? "",
      title: map['title'] ?? "New Session",
      category: map['category'] ?? "",
      
    );
  }

  String toJson() => json.encode(toMap());

  factory SessionModelHolder.fromJson(String source) =>
      SessionModelHolder.fromMap(json.decode(source) as Map<String, dynamic>);
}
