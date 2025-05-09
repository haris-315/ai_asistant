// ignore_for_file: public_member_api_docs, sort_constructors_first, non_constant_identifier_names
import 'dart:convert';

class SectionModel {
  final String name;
  final int project_id;
  final int id;
  SectionModel({
    required this.name,
    required this.project_id,
    required this.id,
  });

  SectionModel copyWith({
    String? name,
    int? project_id,
    int? id,
  }) {
    return SectionModel(
      name: name ?? this.name,
      project_id: project_id ?? this.project_id,
      id: id ?? this.id,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'project_id': project_id,
      'id': id,
    };
  }

  factory SectionModel.fromMap(Map<String, dynamic> map) {
    return SectionModel(
      name: map['name'] as String,
      project_id: map['project_id'] as int,
      id: map['id'] as int,
    );
  }

  String toJson() => json.encode(toMap());

  factory SectionModel.fromJson(String source) => SectionModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'SectionModel(name: $name, project_id: $project_id, id: $id)';

  @override
  bool operator ==(covariant SectionModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.name == name &&
      other.project_id == project_id &&
      other.id == id;
  }

  @override
  int get hashCode => name.hashCode ^ project_id.hashCode ^ id.hashCode;
}
