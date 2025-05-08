class EmailNotification {
  final String? subject;
  final String? header;
  final String? body;
  final String? sender;
  final String? recipient;
  final String? actionText;
  final String? actionUrl;
  final String? secondaryActionText;
  final String? secondaryActionUrl;
  final String? footer;
  final String? signature;
  final String? privacyPolicyUrl;
  final String? companyInfo;
  
  // Metadata
  final String webLink;
  final String messageId;
  final String importance;
  final String? summary;
  final List<String>? quickReplies;
  final String? aiDraft;
  final int? priorityScore;
  final Map<String, dynamic> categories;
  final String? topic;
  final List<String>? extractedTasks;

  EmailNotification({
    this.subject,
    this.header,
    this.body,
    this.sender,
    this.recipient,
    this.actionText,
    this.actionUrl,
    this.secondaryActionText,
    this.secondaryActionUrl,
    this.footer,
    this.signature,
    this.privacyPolicyUrl,
    this.companyInfo,
    required this.webLink,
    required this.messageId,
    required this.importance,
    this.summary,
    this.quickReplies,
    this.aiDraft,
    this.priorityScore,
    this.categories = const {},
    this.topic,
    this.extractedTasks,
  });

  factory EmailNotification.fromMap(Map<String, dynamic> map) {
    return EmailNotification(
      subject: map['subject'],
      header: map['header'],
      body: map['body'],
      sender: map['sender'],
      recipient: map['recipient'],
      actionText: map['actionText'],
      actionUrl: map['actionUrl'],
      secondaryActionText: map['secondaryActionText'],
      secondaryActionUrl: map['secondaryActionUrl'],
      footer: map['footer'],
      signature: map['signature'],
      privacyPolicyUrl: map['privacyPolicyUrl'],
      companyInfo: map['companyInfo'],
      webLink: map['web_link'] ?? map['webLink'],
      messageId: map['message_id'] ?? map['messageId'],
      importance: map['importance'] ?? 'normal',
      summary: map['summary'],
      quickReplies: map['quick_replies'] != null 
          ? List<String>.from(map['quick_replies'])
          : null,
      aiDraft: map['ai_draft'] ?? map['aiDraft'],
      priorityScore: map['priority_score'] ?? map['priorityScore'],
      categories: map['categories'] != null
          ? Map<String, dynamic>.from(map['categories'])
          : {},
      topic: map['topic'],
      extractedTasks: map['extracted_tasks'] != null
          ? List<String>.from(map['extracted_tasks'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subject': subject,
      'header': header,
      'body': body,
      'sender': sender,
      'recipient': recipient,
      'actionText': actionText,
      'actionUrl': actionUrl,
      'secondaryActionText': secondaryActionText,
      'secondaryActionUrl': secondaryActionUrl,
      'footer': footer,
      'signature': signature,
      'privacyPolicyUrl': privacyPolicyUrl,
      'companyInfo': companyInfo,
      'web_link': webLink,
      'message_id': messageId,
      'importance': importance,
      'summary': summary,
      'quick_replies': quickReplies,
      'ai_draft': aiDraft,
      'priority_score': priorityScore,
      'categories': categories,
      'topic': topic,
      'extracted_tasks': extractedTasks,
    };
  }

  @override
  String toString() {
    return 'EmailNotification{subject: $subject, recipient: $recipient, messageId: $messageId}';
  }
}