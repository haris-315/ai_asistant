// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

class AssistantServiceModel {
  final bool isBound;
  final bool isStoped;
  final bool isStandBy;
  final String channel;
  final String resultChannel;
  final String recognizedText;
  final bool initializing;


  AssistantServiceModel({
    required this.recognizedText,
    required this.isBound,
    required this.initializing,
    required this.isStoped,
    required this.isStandBy,
    required this.channel,
    required this.resultChannel,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'isBound': isBound,
      'isStoped': isStoped,
      'isStandBy': isStandBy,
      'channel': channel,
      'result_channel': resultChannel,
      'recognizedText': recognizedText,
      'initializing' : initializing
    };
  }

  factory AssistantServiceModel.fromMap(Map<dynamic, dynamic> map) {
    return AssistantServiceModel(
      isBound: map['isBound'] as bool,
      isStoped: map['isStoped'] as bool,
      isStandBy: map['isStandBy'] as bool,
      channel: map['channel'] as String,
      resultChannel: map['result_channel'] as String,
      recognizedText: map['recognizedText'] ?? "",
      initializing: map['initializing'] ?? false
    );
  }

  static empty() => AssistantServiceModel(
    isBound: false,
    isStoped: false,
    isStandBy: false,
    channel: "empty",
    resultChannel: "empty",
    recognizedText: '',
    initializing: true
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
    bool? initializing
  }) {
    return AssistantServiceModel(
      isBound: isBound ?? this.isBound,
      isStoped: isStoped ?? this.isStoped,
      isStandBy: isStandBy ?? this.isStandBy,
      channel: channel ?? this.channel,
      resultChannel: resultChannel ?? this.resultChannel,
      recognizedText: recognizedText ?? this.recognizedText,
      initializing: initializing ?? this.initializing
    );
  }
}
