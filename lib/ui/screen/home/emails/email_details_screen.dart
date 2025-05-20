import 'dart:convert';

import 'package:ai_asistant/Controller/auth_controller.dart';
import 'package:ai_asistant/ui/screen/home/emails/newemail_screen.dart';
import 'package:ai_asistant/ui/screen/home/emails/summarization_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:html/parser.dart' show parse;
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../data/models/emails/thread_detail.dart';

class EmailDetailScreen extends StatefulWidget {
  final Map<String, dynamic> threadAndData;

  const EmailDetailScreen({super.key, required this.threadAndData});

  @override
  State<EmailDetailScreen> createState() => _EmailDetailScreenState();
}

class _EmailDetailScreenState extends State<EmailDetailScreen> {
  bool isLoadingQuickReplies = false;
  late WebViewController _webViewController;
  double _webViewHeight = 300; // Initial height
  bool _isWebViewLoading = true; // Track loading state

  @override
  void initState() {
    super.initState();
    _webViewController =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setBackgroundColor(Theme.of(Get.context!).colorScheme.surface)
          ..setNavigationDelegate(
            NavigationDelegate(
              onNavigationRequest: (NavigationRequest request) {
                if (request.url.startsWith('http')) {
                  launchUrl(Uri.parse(request.url));
                  return NavigationDecision.prevent;
                }
                return NavigationDecision.navigate;
              },
              onPageFinished: (url) {
                // Inject JavaScript to calculate content height
                _webViewController.runJavaScript('''
              window.postMessage({
                type: 'contentHeight',
                height: document.body.scrollHeight
              }, '*');
            ''');
              },
            ),
          )
          ..addJavaScriptChannel(
            'HeightChannel',
            onMessageReceived: (JavaScriptMessage message) {
              try {
                final data = jsonDecode(message.message);
                if (data['type'] == 'contentHeight') {
                  final newHeight = double.parse(data['height'].toString());
                  if (mounted) {
                    setState(() {
                      _webViewHeight = newHeight + 20; // Add padding
                      _isWebViewLoading = false;
                    });
                  }
                }
              } catch (e) {
                print('Error parsing height: $e');
              }
            },
          );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    List<EmailMessage> emails = widget.threadAndData['thread_mails'];

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.threadAndData['thread'].subject ?? "No Subject",
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ...emails.asMap().entries.map(
                  (entry) => _buildEmailMessage(
                    context,
                    entry.value,
                    entry.key,
                    emails.length,
                  ),
                ),
                SizedBox(height: 5.h),
                if (emails.isNotEmpty &&
                    emails.last.quick_replies != null &&
                    emails.last.quick_replies!.isNotEmpty)
                  _buildQuickRepliesSection(context, emails.last.quick_replies!)
                else if (emails.last.summary == null &&
                    !isLoadingQuickReplies) ...[
                  SizedBox(height: 60),
                  Center(
                    child: ElevatedButton(
                      onPressed: () async {
                        setState(() {
                          isLoadingQuickReplies = true;
                        });

                        var extension = await Get.find<AuthController>()
                            .emailAiProccess(
                              emails.last.id,
                              shouldShowLoader: false,
                            );
                        if (extension != null) {
                          setState(() {
                            emails[emails.length - 1] = emails.last.copyWith(
                              summary: extension.summary,
                              quick_replies: extension.quick_replies,
                              ai_draft: extension.ai_draft,
                              topic: extension.topic,
                            );
                          });
                        }
                        setState(() {
                          isLoadingQuickReplies = false;
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        foregroundColor: colorScheme.onPrimary,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                        shadowColor: Colors.black.withOpacity(0.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.auto_awesome, size: 20),
                          SizedBox(width: 8),
                          Text(
                            "Generate Quick Replies",
                            style: textTheme.labelLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                SizedBox(height: 15),
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
              child: Column(
                children: [
                  if (isLoadingQuickReplies) ...[
                    LinearProgressIndicator(color: Colors.blue),
                    SizedBox(height: 2),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      if (emails.length == 1)
                        _buildActionButton(
                          context,
                          icon: Icons.reply,
                          label: "Reply",
                          onPressed: () {
                            Get.to(
                              () => NewMessageScreen(
                                isReplying: true,
                                toEmail: emails.last,
                                subject: widget.threadAndData['thread'].subject,
                              ),
                            );
                          },
                        ),
                      _buildActionButton(
                        context,
                        icon: Icons.summarize,
                        label: "Summarize",
                        onPressed: () {
                          Get.to(
                            () => EmailSummaryScreen(
                              toSummarize: ThreadSummarizable(
                                hasSummary:
                                    widget.threadAndData['thread'].summary,
                                conversationId:
                                    widget
                                        .threadAndData['thread']
                                        .conversationId ??
                                    "",
                              ),
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
                                  widget.threadAndData['thread'].subject ??
                                  "No Subject",
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailMessage(
    BuildContext context,
    EmailMessage email,
    int index,
    int totalEmails,
  ) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color:
            index % 2 == 0
                ? colorScheme.surface
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.05),
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: _getAvatarColor(email.senderName),
                child: Text(
                  email.senderName.isNotEmpty
                      ? email.senderName[0].toUpperCase()
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
                            email.senderName,
                            style: textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (email.hasAttachments)
                              Icon(
                                Icons.attach_email,
                                color: Colors.grey[600],
                                size: 22,
                              ),
                            SizedBox(width: 5),
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
                                      subject: email.subject,
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
                                } else if (value == 'aireply') {
                                  Get.to(
                                    () => NewMessageScreen(
                                      isReplying: true,
                                      isForwarding: true,
                                      toEmail: email,
                                      body: email.ai_draft ?? "",
                                      subject: email.subject,
                                    ),
                                  );
                                } else if (value == 'summarize') {
                                  Get.to(
                                    () => EmailSummaryScreen(
                                      toSummarize: EmailSummarizable(
                                        hasSummary: email.summary,
                                        emailId: email.id,
                                      ),
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
                                      value: 'aireply',
                                      child: Text('AI Reply'),
                                    ),
                                    PopupMenuItem(
                                      value: 'summarize',
                                      child: Text('Summarize'),
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
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Icon(
                          Icons.subdirectory_arrow_right_rounded,
                          size: 16,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        SizedBox(width: 4),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "from ${email.sender}",
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                "to ${email.recipients.join(', ')}",
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurface.withValues(
                                    alpha: 0.6,
                                  ),
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ],
                          ),
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
            child: _buildEmailBody(email.bodyHtml, context),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailBody(String htmlContent, BuildContext context) {
    return EmailWebViewWidget(htmlContent: htmlContent);
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
                          toEmail: widget.threadAndData['thread_mails'].last,
                          body: reply.toString(),
                          subject: widget.threadAndData['thread'].subject,
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
                          color: Colors.black.withValues(alpha: 0.8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
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

  Color _getAvatarColor(String? sender) {
    final colors = [
      Colors.blue.shade700,
      Colors.red.shade700,
      Colors.purple.shade700,
      Colors.teal.shade700,
      Colors.orange.shade700,
      Colors.indigo.shade700,
    ];
    final safeSender = sender ?? "default";
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

${_stripHtmlTags(email.bodyHtml)}
''';
      })
      .join('\n\n');
}

String _stripHtmlTags(String htmlString) {
  final document = parse(htmlString);
  return document.body?.text.trim() ?? htmlString;
}

class EmailWebViewWidget extends StatefulWidget {
  final String htmlContent;

  const EmailWebViewWidget({super.key, required this.htmlContent});

  @override
  State<EmailWebViewWidget> createState() => _EmailWebViewWidgetState();
}

class _EmailWebViewWidgetState extends State<EmailWebViewWidget> {
  late final WebViewController _controller;
  double _webViewHeight = 1;

  @override
  void initState() {
    super.initState();
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..addJavaScriptChannel(
            'HeightChannel',
            onMessageReceived: (JavaScriptMessage message) {
              try {
                final height = double.tryParse(message.message);
                if (height != null && mounted) {
                  setState(() => _webViewHeight = height + 20);
                }
              } catch (_) {}
            },
          )
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageFinished: (_) {
                _controller.runJavaScript('''
              setTimeout(() => {
                HeightChannel.postMessage(document.body.scrollHeight.toString());
              }, 300);
            ''');
              },
            ),
          );

    _loadHtml(widget.htmlContent);
  }

  void _loadHtml(String htmlContent) {
    final html = '''
      <!DOCTYPE html>
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
              font-size: 14px;
              line-height: 1.6;
              margin: 0;
              padding: 0;
              color: #333;
            }
            a {
              color: #1E88E5;
              text-decoration: underline;
            }
            img {
              max-width: 100%;
              height: auto;
            }
          </style>
        </head>
        <body>${widget.htmlContent}</body>
      </html>
    ''';

    _controller.loadHtmlString(html);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _webViewHeight,
      child: WebViewWidget(controller: _controller),
    );
  }
}
