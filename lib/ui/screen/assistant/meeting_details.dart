import 'package:ai_asistant/data/models/service_models/meeting.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MeetingDetailsPage extends StatelessWidget {
  final Meeting meeting;

  const MeetingDetailsPage({super.key, required this.meeting});

  String _formatDateTime(String? dateTimeStr) {
    if (dateTimeStr == null) return "Not specified";
    final dateTime = DateTime.tryParse(dateTimeStr);
    if (dateTime == null) return "Invalid date";

    return DateFormat('EEEE, MMMM d, y • h:mm a').format(dateTime);
  }

  String _formatDuration(String? startStr, String? endStr) {
    final start = DateTime.tryParse(startStr ?? '');
    final end = DateTime.tryParse(endStr ?? '');

    if (start == null || end == null) return "";

    final duration = end.difference(start);
    if (duration.inMinutes < 1) return "";

    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0 && minutes > 0) {
      return '${hours}h ${minutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${minutes}m';
    }
  }

  Widget _buildInfoRow(String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String? content) {
    if (content == null || content.isEmpty) return const SizedBox();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              content,
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duration = _formatDuration(meeting.startTime, meeting.endTime);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meeting Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Add share functionality
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey[300]!, width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      meeting.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (duration.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Chip(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        label: Text(
                          duration,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoRow('When', _formatDateTime(meeting.startTime)),
            _buildInfoRow('Ended', _formatDateTime(meeting.endTime)),
            const SizedBox(height: 24),
            _buildSection('Meeting Summary', meeting.summary),
            _buildSection('Full Transcript', meeting.actualTranscript),
          ],
        ),
      ),
    );
  }
}
