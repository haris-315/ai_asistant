import 'package:ai_asistant/Controller/auth_controller.dart';
import 'package:ai_asistant/ui/widget/animted_typing_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

abstract interface class Summarizeable {
  final String id;
  final String? summary;
  Summarizeable({required this.summary, required this.id});
}

class EmailSummarizable implements Summarizeable {
  final String emailId;
  final String? hasSummary;

  EmailSummarizable({required this.hasSummary, required this.emailId});
  @override
  String get id => emailId;

  @override
  String? get summary => hasSummary;
}

class ThreadSummarizable implements Summarizeable {
  final String conversationId;
  final String? hasSummary;
  ThreadSummarizable({required this.hasSummary, required this.conversationId});
  @override
  String get id => conversationId;

  @override
  String? get summary => hasSummary;
}

class EmailSummaryScreen extends StatefulWidget {
  final Summarizeable toSummarize;

  const EmailSummaryScreen({super.key, required this.toSummarize});

  @override
  State<EmailSummaryScreen> createState() => _EmailSummaryScreenState();
}

class _EmailSummaryScreenState extends State<EmailSummaryScreen> {
  AuthController authController = Get.find<AuthController>();
  String summary = "";

  void summarize() async {
    final initialSummary = widget.toSummarize.summary;

    if (initialSummary != null && initialSummary.trim().isNotEmpty) {
      setState(() {
        summary = initialSummary;
      });
      return;
    }

    // Call API if no initial summary
    if (widget.toSummarize is EmailSummarizable) {
      final res = await authController.emailAiProccess(widget.toSummarize.id);
      if (res?.summary != null && res!.summary.trim().isNotEmpty) {
        setState(() {
          summary = res.summary;
        });
      } else {
        setState(() {
          summary =
              "There was an error summarizing this content or no summary is available.";
        });
      }
    } else if (widget.toSummarize is ThreadSummarizable) {
      final res = await authController.threadAiProccess(widget.toSummarize.id);
      if (res?.summary != null && res!.summary.trim().isNotEmpty) {
        setState(() {
          summary = res.summary;
        });
      } else {
        setState(() {
          summary =
              "There was an error summarizing this content or no summary is available.";
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    summarize();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Email Summary",
          style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 3.h),
            _buildSectionHeader("Summary", Icons.summarize, context),
            SizedBox(height: 1.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedTypingText(
                key: ValueKey(summary), // ✅ forces rebuild when summary changes
                text: summary,
                textStyle: textTheme.bodyLarge,
              ),
            ),
            SizedBox(height: 3.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    BuildContext context,
  ) {
    return Row(
      children: [
        Icon(icon, size: 20.sp, color: Theme.of(context).colorScheme.primary),
        SizedBox(width: 2.w),
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
