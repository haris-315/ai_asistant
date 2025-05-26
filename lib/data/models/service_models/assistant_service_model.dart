// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class AssistantServiceModel {
  final bool isBound;
  final bool isStoped;
  final bool isStandBy;
  final String mailsSyncHash;
  final String recognizedText;
  final bool initializing;
  final bool isWarmingTts;

  AssistantServiceModel({
    required this.isBound,
    required this.isStoped,
    required this.isStandBy,
    required this.mailsSyncHash,
    required this.recognizedText,
    required this.initializing,
    required this.isWarmingTts,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isBound': isBound,
      'isStoped': isStoped,
      'isStandBy': isStandBy,
      'mailsSyncHash': mailsSyncHash,
      'recognizedText': recognizedText,
      'initializing': initializing,
      'isWarmingTts': isWarmingTts,
    };
  }

  factory AssistantServiceModel.fromMap(Map<dynamic, dynamic> map) {
    return AssistantServiceModel(
      isBound: map['isBound'] as bool,
      isStoped: map['isStoped'] as bool,
      isStandBy: map['isStandBy'] as bool,
      recognizedText: map['recognizedText'] as String? ?? "",
      initializing: map['initializing'] as bool,
      isWarmingTts: map['isWarmingTts'] as bool,
      mailsSyncHash: map['mailsSyncHash']
    );
  }

  static empty() => AssistantServiceModel(
    isBound: false,
    isStoped: false,
    isStandBy: false,
    mailsSyncHash: "",
    recognizedText: '',
    initializing: false,
    isWarmingTts: false,
  );

  String toJson() => json.encode(toMap());

  factory AssistantServiceModel.fromJson(String source) =>
      AssistantServiceModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );

  AssistantServiceModel copyWith({
    bool? isBound,
    bool? isStoped,
    bool? isStandBy,
    String? channel,
    String? resultChannel,
    String? recognizedText,
    bool? initializing,
    bool? isWarmingTts,
    String? mailsSyncHash
  }) {
    return AssistantServiceModel(
      isBound: isBound ?? this.isBound,
      isStoped: isStoped ?? this.isStoped,
      isStandBy: isStandBy ?? this.isStandBy,
      recognizedText: recognizedText ?? this.recognizedText,
      initializing: initializing ?? this.initializing,
      isWarmingTts: isWarmingTts ?? this.isWarmingTts,
      mailsSyncHash: mailsSyncHash ?? this.mailsSyncHash,
    );
  }

  @override
  String toString() {
    return 'AssistantServiceModel(isBound: $isBound, isStoped: $isStoped, isStandBy: $isStandBy, recognizedText: $recognizedText, initializing: $initializing, isWarmingTts: $isWarmingTts)';
  }

  @override
  bool operator ==(covariant AssistantServiceModel other) {
    if (identical(this, other)) return true;

    return other.isBound == isBound &&
        other.isStoped == isStoped &&
        other.isStandBy == isStandBy &&
        other.recognizedText == recognizedText &&
        other.initializing == initializing &&
        other.isWarmingTts == isWarmingTts;
  }

  @override
  int get hashCode {
    return isBound.hashCode ^
        isStoped.hashCode ^
        isStandBy.hashCode ^
        recognizedText.hashCode ^
        initializing.hashCode ^
        isWarmingTts.hashCode;
  }
}
