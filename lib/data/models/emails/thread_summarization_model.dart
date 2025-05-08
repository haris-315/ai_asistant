// ignore_for_file: non_constant_identifier_names

final class SummarizationModel {
  final String summary;
  final String topic;
  final String category;
  final int priority_score;

  SummarizationModel({
    required this.summary,
    required this.topic,
    required this.category,
    required this.priority_score,
  });

  factory SummarizationModel.fromJson(Map<String, dynamic> json) {
    return SummarizationModel(
      category: json["category"],
      topic: json['topic'],
      summary: json['summary'],
      priority_score: json['priority_score'],
    );
  }
}
