// ignore_for_file: public_member_api_docs, sort_constructors_first
class Meeting {
  final String id;
  final String title;
  final String startTime;
  final String endTime;
  final String actualTranscript;
  final String summary;
  final String keypoints;

  Meeting({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.actualTranscript,
    required this.summary,
    required this.keypoints,
  });

  factory Meeting.fromMap(Map<String, dynamic> map) => Meeting(
        id: map['id'],
        title: map['title'],
        startTime: map['startTime'],
        endTime: map['endTime'],
        actualTranscript: map['actualTranscript'],
        summary: map['summary'],
        keypoints: map['keypoints'] ?? '[]', //
      );

  @override
  String toString() {
    return """
            A Meeting about '$title' on '$startTime'
            Key Points: $keypoints
            """;
  }
}