import 'dart:convert';

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
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.blueGrey[700],
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.grey[900],
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context,
    String title,
    String? content, {
    bool isKeypoints = false,
  }) {
    if (content == null ||
        content.isEmpty ||
        (isKeypoints && content == '[]')) {
      return const SizedBox();
    }

    List<String> keypoints = [];
    if (isKeypoints) {
      try {
        keypoints = (jsonDecode(content) as List<dynamic>).cast<String>();
      } catch (e) {
        return const SizedBox();
      }
    }

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: Colors.blueGrey[900],
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.white, Colors.grey[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    spreadRadius: 2,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child:
                  isKeypoints
                      ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children:
                            keypoints.asMap().entries.map((entry) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '•',
                                      style: TextStyle(
                                        fontSize: 18,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        entry.value,
                                        style: TextStyle(
                                          fontSize: 16,
                                          height: 1.6,
                                          color: Colors.grey[900],
                                          fontWeight: FontWeight.w400,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                      )
                      : Text(
                        content,
                        style: TextStyle(
                          fontSize: 16,
                          height: 1.6,
                          color: Colors.grey[900],
                          fontWeight: FontWeight.w400,
                        ),
                      ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final duration = _formatDuration(meeting.startTime, meeting.endTime);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text(
          'Meeting Details',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.blueGrey[800],
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blueGrey[900]!, Colors.blueGrey[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.blueGrey[50]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      meeting.title,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.blueGrey[900],
                        letterSpacing: 0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (duration.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Chip(
                        backgroundColor: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.15),
                        label: Text(
                          duration,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            _buildInfoRow('When', _formatDateTime(meeting.startTime)),
            _buildInfoRow(
              'Ended',
              _formatDateTime(meeting.endTime),
              isLast: true,
            ),
            const SizedBox(height: 32),
            _buildSection(
              context,
              'Key Points',
              meeting.keypoints,
              isKeypoints: true,
            ),
            _buildSection(context, 'Summary', meeting.summary),
            _buildSection(context, 'Full Transcript', meeting.actualTranscript),
          ],
        ),
      ),
    );
  }
}
