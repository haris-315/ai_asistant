import 'package:ai_asistant/ui/widget/animted_typing_text.dart';
import 'package:flutter/material.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class EmailSummaryScreen extends StatelessWidget {
  final String summary;
  final String topic;

  const EmailSummaryScreen({
    super.key,
    required this.summary,
    required this.topic,
  });

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
            // Topic Section
            _buildSectionHeader("Topic", Icons.label_important, context),
            SizedBox(height: 1.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.2,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                topic,
                style: textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(height: 3.h),

            // Summary Section
            _buildSectionHeader("Summary", Icons.summarize, context),
            SizedBox(height: 1.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.1,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: AnimatedTypingText(
                text: summary,
                textStyle: textTheme.bodyLarge,
              ),
            ),
            SizedBox(height: 3.h),

            // Quick Replies Section
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
