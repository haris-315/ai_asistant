// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class Voice {
  final String? name;
  final String? locale;
  final int? latency;
  final bool? isOnline;
  Voice({this.name, this.locale, this.latency, this.isOnline});

  Voice copyWith({String? name, String? locale, int? latency, bool? isOnline}) {
    return Voice(
      name: name ?? this.name,
      locale: locale ?? this.locale,
      latency: latency ?? this.latency,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'locale': locale,
      'latency': latency,
      'isOnline': isOnline,
    };
  }

  factory Voice.fromMap(Map<Object?, Object?> map) {
    return Voice(
      name: map['name'] != null ? map['name'] as String : null,
      locale: map['locale'] != null ? map['locale'] as String : null,
      latency: map['latency'] != null ? map['latency'] as int : null,
      isOnline: map['isOnline'] != null ? map['isOnline'] as bool : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory Voice.fromJson(String source) =>
      Voice.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() {
    return 'Voice(name: $name, locale: $locale, latency: $latency, isOnline: $isOnline)';
  }

  @override
  bool operator ==(covariant Voice other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.locale == locale &&
        other.latency == latency &&
        other.isOnline == isOnline;
  }

  @override
  int get hashCode {
    return name.hashCode ^
        locale.hashCode ^
        latency.hashCode ^
        isOnline.hashCode;
  }
}
