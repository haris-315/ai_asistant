// ignore_for_file: public_member_api_docs, sort_constructors_first, non_constant_identifier_names
import 'dart:convert';

class LabelModel {
  final String name;
  final String color;
  final bool is_favorite;
  final int? id;
  final int? user_id;
  LabelModel({
    required this.name,
    required this.color,
    required this.is_favorite,
     this.id,
     this.user_id,
  });

  LabelModel copyWith({
    String? name,
    String? color,
    bool? is_favorite,
    int? id,
    int? user_id,
  }) {
    return LabelModel(
      name: name ?? this.name,
      color: color ?? this.color,
      is_favorite: is_favorite ?? this.is_favorite,
      id: id ?? this.id,
      user_id: user_id ?? this.user_id,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'color': color,
      'is_favorite': is_favorite,
      'id': id ?? 0,
      'user_id': user_id ?? 0,
    };
  }

  factory LabelModel.fromMap(Map<String, dynamic> map) {
    return LabelModel(
      name: map['name'] as String,
      color: map['color'] as String,
      is_favorite: map['is_favorite'] as bool,
      id: map['id'] as int?,
      user_id: map['user_id'] as int?,
    );
  }

  String toJson() => json.encode(toMap());

  factory LabelModel.fromJson(String source) => LabelModel.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'LabelModel(name: $name, color: $color, is_favorite: $is_favorite, id: $id, user_id: $user_id)';
  }

  @override
  bool operator ==(covariant LabelModel other) {
    if (identical(this, other)) return true;
  
    return 
      other.name == name &&
      other.color == color &&
      other.is_favorite == is_favorite &&
      other.id == id &&
      other.user_id == user_id;
  }

  @override
  int get hashCode {
    return name.hashCode ^
      color.hashCode ^
      is_favorite.hashCode ^
      id.hashCode ^
      user_id.hashCode;
  }
}
