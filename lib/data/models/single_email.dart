import 'package:ai_asistant/data/models/emails/attachment.dart';

class EmailAddress {
  final String name;
  final String email;

  EmailAddress({required this.name, required this.email});

  factory EmailAddress.fromJson(Map<String, dynamic> json) {
    return EmailAddress(
      name: json['name'] ?? '',
      email: json['email'] ?? '',
    );
  }

  @override
  String toString() => '$name <$email>';
}



class SingleEmail {
  final String id;
  final String subject;
  final String bodyPreview;
  final String body;
  final DateTime date;
  final bool isRead;
  final bool hasAttachments;
  final String conversationId;
  final EmailAddress sender;
  final List<EmailAddress> toRecipients;
  final List<EmailAddress> ccRecipients;
  final String webLink;
  final List<Attachment> attachments;

  SingleEmail({
    required this.id,
    required this.subject,
    required this.bodyPreview,
    required this.body,
    required this.date,
    required this.isRead,
    required this.hasAttachments,
    required this.conversationId,
    required this.sender,
    required this.toRecipients,
    required this.ccRecipients,
    required this.webLink,
    required this.attachments,
  });

  factory SingleEmail.fromJson(Map<String, dynamic> json) {
    return SingleEmail(
      id: json['id'],
      subject: json['subject'],
      bodyPreview: json['body_preview'],
      body: json['body'],
      date: DateTime.parse(json['date']),
      isRead: json['isRead'],
      hasAttachments: json['hasAttachments'],
      conversationId: json['conversationId'],
      sender: EmailAddress.fromJson(json['sender']),
      toRecipients: List<Map<String, dynamic>>.from(json['toRecipients'])
          .map((e) => EmailAddress.fromJson(e))
          .toList(),
      ccRecipients: List<Map<String, dynamic>>.from(json['ccRecipients'])
          .map((e) => EmailAddress.fromJson(e))
          .toList(),
      webLink: json['webLink'],
      attachments: List<Map<String, dynamic>>.from(json['attachments'])
          .map((e) => Attachment.fromMap(e))
          .toList(),
    );
  }
}
