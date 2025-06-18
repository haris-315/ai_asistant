// ignore_for_file: use_build_context_synchronously

import 'dart:io';
import 'dart:typed_data';

import 'package:ai_asistant/Controller/auth_controller.dart';
import 'package:ai_asistant/data/models/emails/attachment.dart';
import 'package:ai_asistant/data/models/emails/thread_detail.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mime/mime.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class NewMessageScreen extends StatefulWidget {
  final bool isReplying;
  final EmailMessage? toEmail;
  final String body;
  final String? subject;
  final String? forwardBody;
  final bool isForwarding;
  const NewMessageScreen({
    super.key,
    this.isReplying = false,
    this.toEmail,
    this.body = "",
    this.subject,
    this.forwardBody,
    this.isForwarding = false,
  });

  @override
  State<NewMessageScreen> createState() => _NewMessageScreenState();
}

class _NewMessageScreenState extends State<NewMessageScreen> {
  final AuthController authcontroller = Get.find<AuthController>();
  final TextEditingController tocontroller = TextEditingController();
  final TextEditingController subjectcontroller = TextEditingController();
  final TextEditingController bodycontroller = TextEditingController();

  List<Attachment> attachments = [];

  void setControllers(EmailMessage email) {
    tocontroller.text = email.sender ?? "";
    subjectcontroller.text = "Re: ${email.subject}";
    bodycontroller.text = widget.body;
  }

  Future<void> pickFiles() async {
    PermissionStatus status =
        !Platform.isAndroid
            ? PermissionStatus.granted
            : await Permission.storage.request();

    if (status.isGranted) {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final newAttachments =
            result.files.map((file) {
              final mimeType =
                  lookupMimeType(file.name) ?? 'application/octet-stream';
              return Attachment(
                id: UniqueKey().toString(),
                name: file.name,
                size: file.size,
                content_type: mimeType,
                content_bytes: file.bytes ?? Uint8List(0),
              );
            }).toList();

        setState(() {
          attachments.addAll(newAttachments);
        });
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Storage permission is required to pick files.'),
        ),
      );
    }
  }

  Future<void> sendEmail({bool reply = false, String? emailId}) async {
    if (reply) {
      bool? success = await authcontroller.emailReply(
        emailId ?? "",
        bodycontroller.text,
      );
      if (success == true) {
        tocontroller.clear();
        subjectcontroller.clear();
        bodycontroller.clear();
        setState(() {
          attachments.clear();
        });
      }
      return;
    }

    bool? success = await authcontroller.SendNewEmail(
      tocontroller.text,
      subjectcontroller.text,
      bodycontroller.text,
      attachments: attachments,
    );

    if (success == true) {
      tocontroller.clear();
      subjectcontroller.clear();
      bodycontroller.clear();
      setState(() {
        attachments.clear();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isReplying) {
      setControllers(widget.toEmail!);
    } else if (widget.isForwarding) {
      bodycontroller.text = widget.forwardBody ?? "";
      subjectcontroller.text = "Fwd: ${widget.subject ?? ''}";
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final borderColor = isDark ? Colors.grey[700] : Colors.grey[300];
    final cardColor = isDark ? Colors.grey[900] : Colors.grey[50];

    final bool isReplying = widget.isReplying;
    final bool isForwarding = widget.isForwarding;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isReplying
              ? "Replying to ${widget.toEmail?.sender}"
              : isForwarding
              ? "Forwarding Mail"
              : "Composing Mail",
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
            fontSize: 14,
          ),
        ),
        actions: [
          IconButton(
            icon: Transform(
              alignment: Alignment.center,
              transform:
                  Matrix4.identity()
                    ..scale(-1.0, 1.0, 1.0), // Flip horizontally
              child: Icon(Icons.reply), // or any icon
            ),
            onPressed: () {
              sendEmail(
                reply: isReplying,
                emailId: widget.toEmail != null ? widget.toEmail?.id : "",
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Recipient Field
            TextField(
              controller: tocontroller,
              style: theme.textTheme.bodyLarge,
              readOnly: isReplying,
              decoration: InputDecoration(
                hintText: "To",
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.hintColor,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: 2.h,
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: borderColor),

            // Subject Field
            TextField(
              controller: subjectcontroller,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              readOnly: isReplying,
              decoration: InputDecoration(
                hintText: "Subject",
                hintStyle: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.hintColor,
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 3.w,
                  vertical: 2.h,
                ),
              ),
            ),
            Divider(height: 1, thickness: 1, color: borderColor),

            // Body Field
            Expanded(
              child: TextField(
                controller: bodycontroller,
                maxLines: null,
                expands: true,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: isReplying ? "Reply..." : "Compose email...",
                  hintStyle: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.hintColor,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 3.w,
                    vertical: 2.h,
                  ),
                ),
              ),
            ),

            // Attachments
            if (attachments.isNotEmpty) ...[
              Divider(height: 1, thickness: 1, color: borderColor),
              SizedBox(
                height: 6.h,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: attachments.length,
                  itemBuilder: (context, index) {
                    final att = attachments[index];
                    return Container(
                      margin: EdgeInsets.only(
                        right: 2.w,
                        top: 1.h,
                        bottom: 1.h,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.5.h,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.insert_drive_file,
                            size: 16.sp,
                            color: theme.primaryColor,
                          ),
                          SizedBox(width: 2.w),
                          SizedBox(
                            width: 20.w,
                            child: Text(
                              att.name,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
                            ),
                          ),
                          SizedBox(width: 2.w),
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                attachments.removeAt(index);
                              });
                            },
                            child: Icon(
                              Icons.close,
                              size: 14.sp,
                              color: theme.iconTheme.color,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: cardColor,
          border: Border(top: BorderSide(color: borderColor!, width: 1)),
        ),
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.attach_file,
                size: 20.sp,
                color: theme.iconTheme.color,
              ),
              onPressed: pickFiles,
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20.sp,
                color: theme.iconTheme.color,
              ),
              onPressed: () async {
                if (tocontroller.text.isEmpty &&
                    bodycontroller.text.isEmpty &&
                    subjectcontroller.text.isEmpty) {
                  return;
                }
                final option = await showDialog<bool>(
                  context: context,
                  builder:
                      (_) => AlertDialog(
                        title: Text("Clear draft?"),
                        content: Text(
                          "This will clear all content in this message.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text("CANCEL"),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              "CLEAR",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                );
                if (option ?? false) {
                  tocontroller.clear();
                  subjectcontroller.clear();
                  bodycontroller.clear();
                  setState(() {
                    attachments.clear();
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
