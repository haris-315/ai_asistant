import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MarkdownViewer extends StatelessWidget {
  final String markdownText;

  const MarkdownViewer({super.key, required this.markdownText});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: MarkdownBody(
        data: markdownText,
        selectable: true,
        styleSheet: MarkdownStyleSheet(
          codeblockDecoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(8.0),
          ),
          code: const TextStyle(color: Colors.orangeAccent),
        ),
      ),
    );
  }
}
