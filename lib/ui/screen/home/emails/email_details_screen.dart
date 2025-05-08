import 'package:ai_asistant/ui/screen/home/emails/newemail_screen.dart';
import 'package:ai_asistant/ui/screen/home/emails/summarization_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../data/models/emails/threadDetail.dart';

class EmailDetailScreen extends StatelessWidget {
  final Map<String, dynamic> threadAndData;

  const EmailDetailScreen({super.key, required this.threadAndData});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    List<EmailMessage> emails = threadAndData['thread_mails'];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "AI Assistant",
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: colorScheme.onSurface),
            onPressed: () => print("Notification Clicked!"),
          ),
          IconButton(
            icon: Icon(Icons.person, color: colorScheme.onSurface),
            onPressed: () => print("Profile Clicked!"),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ...emails.map((email) => _buildEmailMessage(context, email)),
                SizedBox(height: 5.h),
                if (emails.isNotEmpty &&
                    emails.last.quick_replies != null &&
                    emails.last.quick_replies!.isNotEmpty)
                  _buildQuickRepliesSection(
                    context,
                    emails.last.quick_replies!,
                  ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 1.h),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(
                    context,
                    icon: Icons.reply,
                    label: "Reply",
                    onPressed: () {
                      Get.to(
                        () => NewMessageScreen(
                          isReplying: true,
                          toEmail: threadAndData['thread_mails'].first,
                        ),
                      );
                    },
                  ),
                  _buildActionButton(
                    context,
                    icon: Icons.forward,
                    label: "Forward",
                    onPressed: () {
                      Get.to(
                        () => NewMessageScreen(
                          isForwarding: true,
                          forwardBody: generateForwardedThread(emails),
                          subject:
                              threadAndData['thread'].subject ?? "No Subject",
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailMessage(BuildContext context, EmailMessage email) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final isLastEmail = email == threadAndData['thread_mails'].last;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sender info and actions
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _getAvatarColor(email.senderName),
                child: Text(
                  (email.senderName.toString().isNotEmpty)
                      ? email.senderName.toString()[0].toUpperCase()
                      : "?",
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            email.senderName.toString(),
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatDate(email.receivedAt),
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            PopupMenuButton<String>(
                              onSelected: (value) {
                                if (value == 'reply') {
                                  Get.to(
                                    () => NewMessageScreen(
                                      isReplying: true,
                                      toEmail: email,
                                    ),
                                  );
                                } else if (value == 'forward') {
                                  Get.to(
                                    () => NewMessageScreen(
                                      isForwarding: true,
                                      forwardBody: generateForwardedThread([
                                        email,
                                      ]),
                                      subject: email.subject,
                                    ),
                                  );
                                }
                              },
                              itemBuilder:
                                  (context) => [
                                    PopupMenuItem(
                                      value: 'reply',
                                      child: Text('Reply'),
                                    ),
                                    PopupMenuItem(
                                      value: 'forward',
                                      child: Text('Forward'),
                                    ),
                                  ],
                              icon: Icon(Icons.more_vert, size: 18),
                            ),
                          ],
                        ),
                      ],
                    ),

                    Row(
                      children: [
                        SizedBox(width: 6),
                        Icon(Icons.subdirectory_arrow_right_rounded, size: 22),
                        Column(
                          children: [
                            Text(
                              "from ${email.sender}",
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                            Text(
                              "to ${email.recipients.join(', ')}",
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),

          if (email.subject.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Text(
                email.subject,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

          Padding(
            padding: EdgeInsets.symmetric(vertical: 0.8.h),
            child: Text(
              email.bodyPreview,
              style: textTheme.bodyMedium?.copyWith(
                height: 1.6,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          if (email.hasAttachments) ...[
            SizedBox(height: 2.h),
            _buildAttachmentSection(context),
          ],

          if (isLastEmail)
            Padding(
              padding: EdgeInsets.only(top: 2.h),
              child: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      Get.to(
                        () =>
                            NewMessageScreen(isReplying: true, toEmail: email),
                      );
                    },
                    icon: Icon(Icons.reply, size: 18),
                    label: Text("Reply"),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () {
                      Get.to(
                        () => EmailSummaryScreen(
                          summary: threadAndData['thread'].summary ?? "",
                          topic: threadAndData['thread'].topic ?? "",
                        ),
                      );
                    },
                    icon: Icon(Icons.summarize, size: 18),
                    label: Text("Summarize"),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 1.h,
                      ),
                      side: BorderSide(
                        color: colorScheme.outline.withValues(alpha: 0.5),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuickRepliesSection(
    BuildContext context,
    List<dynamic> quickReplies,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Replies",
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: 1.5.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.5.h,
            children:
                quickReplies.map((reply) {
                  return InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Get.to(
                        () => NewMessageScreen(
                          isReplying: true,
                          toEmail: threadAndData['thread_mails'].first,
                          body: reply.toString(),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 4.w,
                        vertical: 1.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.5),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        reply.toString(),
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: Colors.black.withValues(alpha: .8),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachmentSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.attach_file,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              SizedBox(width: 2.w),
              Text(
                "Attachment.pdf",
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(width: 2.w),
              Icon(
                Icons.download,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.onSurface.withValues(alpha: 0.8),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22),
          SizedBox(height: 0.5.h),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }

  Color _getAvatarColor(dynamic sender) {
    final colors = [
      Colors.blue.shade700,
      Colors.red.shade700,
      Colors.purple.shade700,
      Colors.teal.shade700,
      Colors.orange.shade700,
      Colors.indigo.shade700,
    ];
    final safeSender = sender?.toString() ?? "default";
    return colors[safeSender.hashCode % colors.length];
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

String generateForwardedThread(List<EmailMessage> emails) {
  return emails
      .map((email) {
        return '''
---------- Forwarded message ----------
From: ${email.sender}
To: ${email.recipients.join(', ')}
Subject: ${email.subject}

${email.bodyPreview}
''';
      })
      .join('\n\n');
}
