// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: non_constant_identifier_names

class EmailThread {
  final String conversationId;
  final String? subject;
  final String? lastSender;
  final DateTime? lastEmailAt;
  final String? lastBodyPreview;
  final String? summary;
  final String? category;
  final String? topic;
  final String? last_sender_name;
  final bool? is_processing;
  final String? extracted_tasks;
  final int? unreadCount;
  final int? totalCount;
  final int? priority_score;
  final String? importance;
  final List<String>? quick_replies;
  final bool is_read;

  EmailThread({
    required this.conversationId,
    required this.is_read,
    this.last_sender_name,
    this.subject,
    this.is_processing,
    this.extracted_tasks,
    this.summary,
    this.priority_score,
    this.lastSender,
    this.lastEmailAt,
    this.lastBodyPreview,
    this.unreadCount,
    this.totalCount,
    this.topic,
    this.category,
    this.importance,
    this.quick_replies,
  });

  factory EmailThread.fromJson(Map<String, dynamic> json) {
    return EmailThread(
      conversationId: json['conversation_id'],
      subject: json['subject'],
      is_read: json['is_read'] ?? true,
      lastSender: json['last_sender'],
      lastEmailAt: DateTime.parse(json['last_email_at']),
      lastBodyPreview: json['last_body_preview'],
      unreadCount: json['unread_count'],
      totalCount: json['total_count'],
      summary: json['summary'],
      category: json['category'],
      topic: json['topic'],
      is_processing: json['is_processing'],
      extracted_tasks: json['extracted_tasks'] ?? "",
      priority_score: json['priority_score'],
      importance: json['importance'],
      quick_replies: json['quick_replies'],
      last_sender_name: json['last_sender_name'] ?? ""
    );
  }

  @override
  String toString() {
    return 'EmailThread(subject: $subject, lastSender: $lastSender, unreadCount: $unreadCount)';
  }

  EmailThread copyWith({
    String? conversationId,
    String? subject,
    String? lastSender,
    DateTime? lastEmailAt,
    String? lastBodyPreview,
    String? summary,
    String? category,
    String? topic,
    bool? is_processing,
    String? extracted_tasks,
    int? unreadCount,
    int? totalCount,
    int? priority_score,
    String? importance,
    List<String>? quick_replies,
    bool? is_read,
    String? last_sender_name
  }) {
    return EmailThread(
      conversationId: conversationId ?? this.conversationId,
      subject: subject ?? this.subject,
      is_read: is_read ?? this.is_read,
      lastSender: lastSender ?? this.lastSender,
      lastEmailAt: lastEmailAt ?? this.lastEmailAt,
      lastBodyPreview: lastBodyPreview ?? this.lastBodyPreview,
      summary: summary ?? this.summary,
      last_sender_name: last_sender_name ?? this.last_sender_name,
      category: category ?? this.category,
      topic: topic ?? this.topic,
      is_processing: is_processing ?? this.is_processing,
      extracted_tasks: extracted_tasks ?? this.extracted_tasks,
      unreadCount: unreadCount ?? this.unreadCount,
      totalCount: totalCount ?? this.totalCount,
      priority_score: priority_score ?? this.priority_score,
      importance: importance ?? this.importance,
      quick_replies: quick_replies ?? this.quick_replies,
    );
  }
}
