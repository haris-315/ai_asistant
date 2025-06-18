// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class EmailTask {
  final String content;
  final String description;
  final int priority;

  EmailTask({
    required this.content,
    required this.description,
    required this.priority,
  });

  EmailTask copyWith({
    String? content,
    String? description,
    int? priority,
  }) {
    return EmailTask(
      content: content ?? this.content,
      description: description ?? this.description,
      priority: priority ?? this.priority,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'content': content,
      'description': description,
      'priority': priority,
    };
  }

  factory EmailTask.fromMap(Map<String, dynamic> map) {
    return EmailTask(
      content: map['content'] as String,
      description: map['description'] as String,
      priority: map['priority'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory EmailTask.fromJson(String source) => EmailTask.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'EmailTask(content: $content, description: $description, priority: $priority)';

  @override
  bool operator ==(covariant EmailTask other) {
    if (identical(this, other)) return true;
  
    return 
      other.content == content &&
      other.description == description &&
      other.priority == priority;
  }

  @override
  int get hashCode => content.hashCode ^ description.hashCode ^ priority.hashCode;
}
