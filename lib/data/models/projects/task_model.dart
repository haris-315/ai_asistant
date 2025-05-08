// ignore_for_file: public_member_api_docs, sort_constructors_first, non_constant_identifier_names
import 'dart:convert';

class TaskModel {
  final String content;
  final String? description;
  final DateTime createdAt;
  final int? project_id;
  final int? section_id;
  final int? priority;
  final bool is_completed;
  final int? id;
  final bool? is_deleted;
  final int? label_id;
  TaskModel({
    required this.content,
    this.description,
    required this.createdAt,
    this.project_id,
    this.section_id,
    this.priority,
    required this.is_completed,
    required this.id,
    this.is_deleted,
    this.label_id
  });

  TaskModel copyWith({
    String? content,
    String? description,
    DateTime? createdAt,
    int? project_id,
    int? section_id,
    int? priority,
    bool? is_completed,
    int? id,
    bool? is_deleted,
    int? label_id
  }) {
    return TaskModel(
      content: content ?? this.content,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      project_id: project_id ?? this.project_id,
      section_id: section_id ?? this.section_id,
      priority: priority ?? this.priority,
      is_completed: is_completed ?? this.is_completed,
      id: id ?? this.id,
      is_deleted: is_deleted ?? this.is_deleted,
      label_id: label_id ?? this.label_id
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'content': content,
      'description': description,
      'created_at': createdAt.toString(),
      'project_id': project_id,
      'section_id': section_id,
      'priority': priority,
      'is_completed': is_completed,
      'id': id,
      'is_deleted': is_deleted,
      'label_id' : label_id
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map) {
    return TaskModel(
      content: map['content'] as String,
      description:
          map['description'] != null ? map['description'] as String : null,
      createdAt: DateTime.parse(map['created_at']),
      project_id: map['project_id'] != null ? map['project_id'] as int : null,
      section_id: map['section_id'] != null ? map['section_id'] as int : null,
      priority: map['priority'] != null ? map['priority'] as int : null,
      is_completed: map['is_completed'] as bool,
      id: map['id'] != null ? map['id'] as int : null,
      is_deleted: map['is_deleted'] != null ? map['is_deleted'] as bool : null,
      label_id: map['label_id'] != null ? map['label_id'] as int : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory TaskModel.fromJson(String source) =>
      TaskModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'TaskModel(content: $content, description: $description, createdAt: $createdAt, project_id: $project_id, section_id: $section_id, priority: $priority, is_completed: $is_completed, id: $id, is_deleted: $is_deleted)';
  }

  @override
  bool operator ==(covariant TaskModel other) {
    if (identical(this, other)) return true;

    return other.content == content &&
        other.description == description &&
        other.createdAt == createdAt &&
        other.project_id == project_id &&
        other.section_id == section_id &&
        other.priority == priority &&
        other.is_completed == is_completed &&
        other.id == id &&
        other.label_id == label_id &&
        other.is_deleted == is_deleted;
  }

  @override
  int get hashCode {
    return content.hashCode ^
        description.hashCode ^
        createdAt.hashCode ^
        project_id.hashCode ^
        section_id.hashCode ^
        priority.hashCode ^
        is_completed.hashCode ^
        id.hashCode ^
        label_id.hashCode ^
        is_deleted.hashCode;
  }
}
