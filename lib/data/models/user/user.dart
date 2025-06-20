// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class User {
  final String name;
  final String email;
  final String provider;
  User({required this.name, required this.email, required this.provider});

  User copyWith({String? name, String? email, String? provider}) {
    return User(
      name: name ?? this.name,
      email: email ?? this.email,
      provider: provider ?? this.provider,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name,
      'email': email,
      'auth_provider': provider,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      name: map['name'] as String,
      email: map['email'] as String,
      provider: map['auth_provider'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);

  @override
  String toString() => 'User(name: $name, email: $email, provider: $provider)';

  @override
  bool operator ==(covariant User other) {
    if (identical(this, other)) return true;

    return other.name == name &&
        other.email == email &&
        other.provider == provider;
  }

  @override
  int get hashCode => name.hashCode ^ email.hashCode ^ provider.hashCode;
}
