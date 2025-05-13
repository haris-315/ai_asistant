// ignore_for_file: public_member_api_docs, sort_constructors_first
// ignore_for_file: non_constant_identifier_names

class EmailMessage {
  final String id;
  final String subject;
  final String senderName;
  final String sender;
  final List<String> recipients;
  final List<String> cc;
  final DateTime receivedAt;
  final bool isRead;
  final bool hasAttachments;
  final String bodyPreview;
  final String bodyPlain;
  final String bodyHtml;
  final List<dynamic>? quick_replies;
  final String? summary;
  final String? topic;
  final String? ai_draft;

  EmailMessage({
    required this.id,
    required this.subject,
    required this.sender,
    required this.senderName,
    required this.recipients,
    required this.cc,
    required this.receivedAt,
    required this.isRead,
    required this.hasAttachments,
    required this.bodyPreview,
    required this.bodyPlain,
    required this.bodyHtml,
    this.quick_replies,
    this.summary,
    this.topic,
    this.ai_draft,
  });

  // factory EmailMessage.fromJson(Map<String, dynamic> json) {
  //   return EmailMessage(
  //     id: json['id'],
  //     subject: json['subject'],
  //     sender: json['sender'],
  //     recipients: List<String>.from(json['recipients']),
  //     cc: List<String>.from(json['cc']),
  //     receivedAt: DateTime.parse(json['received_at']),
  //     isRead: json['is_read'],
  //     hasAttachments: json['has_attachments'],
  //     bodyPreview: json['body_preview'],
  //     bodyPlain: json['body_plain'],
  //     bodyHtml: json['body_html'],
  //   );
  // }
  factory EmailMessage.fromJson(Map<String, dynamic> json) {
    return EmailMessage(
      id: json['id'],
      subject: json['subject'],
      senderName: json['sender_name'],
      // Fix sender field, assuming it's a single string
      sender: json['sender'],
      recipients: List<String>.from(json['recipients']),
      cc: List<String>.from(json['cc']),
      receivedAt: DateTime.parse(json['received_at']),
      isRead: json['is_read'],
      hasAttachments: json['has_attachments'],
      bodyPreview: json['body_preview'],
      bodyPlain: json['body_plain'],
      bodyHtml: json['body_html'],
      summary: json['summary'],
      topic: json['topic'],
      ai_draft: json["ai_draft"],
      quick_replies: json["quick_replies"],
    );
  }

  @override
  String toString() {
    return 'EmailMessage(summary: $summary subject: $subject, sender: $sender, receivedAt: $receivedAt, quickReplies: $quick_replies)';
  }

  EmailMessage copyWith({
    String? id,
    String? subject,
    String? senderName,
    String? sender,
    List<String>? recipients,
    List<String>? cc,
    DateTime? receivedAt,
    bool? isRead,
    bool? hasAttachments,
    String? bodyPreview,
    String? bodyPlain,
    String? bodyHtml,
    List<dynamic>? quick_replies,
    String? summary,
    String? topic,
    String? ai_draft,
  }) {
    return EmailMessage(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      senderName: senderName ?? this.senderName,
      sender: sender ?? this.sender,
      recipients: recipients ?? this.recipients,
      cc: cc ?? this.cc,
      receivedAt: receivedAt ?? this.receivedAt,
      isRead: isRead ?? this.isRead,
      hasAttachments: hasAttachments ?? this.hasAttachments,
      bodyPreview: bodyPreview ?? this.bodyPreview,
      bodyPlain: bodyPlain ?? this.bodyPlain,
      bodyHtml: bodyHtml ?? this.bodyHtml,
      quick_replies: quick_replies ?? this.quick_replies,
      summary: summary ?? this.summary,
      topic: topic ?? this.topic,
      ai_draft: ai_draft ?? this.ai_draft,
    );
  }
}
