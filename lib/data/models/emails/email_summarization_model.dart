// ignore_for_file: public_member_api_docs, sort_constructors_first, non_constant_identifier_names
import 'dart:convert';

class EmailSummarizationModel {
  final String ai_draft;
  final String summary;
  final List<dynamic> quick_replies;
  final String topic;

  EmailSummarizationModel({
    required this.ai_draft,
    required this.summary,
    required this.quick_replies,
    required this.topic,
  });

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'ai_draft': ai_draft,
      'summary': summary,
      'quick_replies': quick_replies,
      'topic': topic,
    };
  }

  factory EmailSummarizationModel.fromMap(Map<String, dynamic> map) {
    return EmailSummarizationModel(
      ai_draft: map['ai_draft'] as String,
      summary: map['summary'] as String,
      quick_replies: map['quick_replies'] as List<String>,
      topic: map['topic'] as String,
    );
  }

  String toJson() => json.encode(toMap());

  factory EmailSummarizationModel.fromJson(String source) =>
      EmailSummarizationModel.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
}
