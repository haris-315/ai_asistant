// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:ai_asistant/core/services/db_helper.dart';
import 'package:ai_asistant/data/models/service_models/meeting.dart';
import 'package:ai_asistant/ui/screen/assistant/meeting_details.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:page_transition/page_transition.dart';

class MeetingListPage extends StatefulWidget {
  const MeetingListPage({super.key});

  @override
  State<MeetingListPage> createState() => _MeetingListPageState();
}

class _MeetingListPageState extends State<MeetingListPage> {
  List<Meeting> _meetings = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMeetings();
  }

  Future<void> _loadMeetings() async {
    setState(() => _isLoading = true);
    _meetings = await MeetingDatabaseHelper.getAllMeetings();
    setState(() => _isLoading = false);
  }

  Future<void> _deleteMeeting(String id, int index) async {
    final result = await MeetingDatabaseHelper.deleteMeeting(id);
    if (result == DeletionStates.deleted) {
      setState(() => _meetings.removeAt(index));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.info,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
          backgroundColor: Colors.blueGrey[800],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  String _formatDateHeader(DateTime date) {
    final today = DateTime.now();
    final yesterday = today.subtract(const Duration(days: 1));

    if (date.year == today.year &&
        date.month == today.month &&
        date.day == today.day) {
      return 'Today';
    } else if (date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMMM d').format(date);
    }
  }

  String _formatTimeRange(String? startStr, String? endStr) {
    final start = DateTime.tryParse(startStr ?? '');
    final end = DateTime.tryParse(endStr ?? '');

    if (start == null) return "Unknown time";

    final timeFormat = DateFormat('h:mm a');
    final startFormatted = timeFormat.format(start);

    if (end == null) return startFormatted;

    final endFormatted = timeFormat.format(end);
    return '$startFormatted - $endFormatted';
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

  Widget _buildMeetingTile(Meeting meeting, int index) {
    final duration = _formatDuration(meeting.startTime, meeting.endTime);
    List<String> keypoints = [];
    try {
      keypoints =
          (jsonDecode(meeting.keypoints) as List<dynamic>).cast<String>();
    } catch (e) {
      keypoints = [];
    }

    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 500),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.blueGrey[50]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              PageTransition(
                type: PageTransitionType.rightToLeft,
                child: MeetingDetailsPage(meeting: meeting),
                duration: const Duration(milliseconds: 300),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        meeting.title,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.blueGrey[900],
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (duration.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          duration,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 18,
                      color: Colors.blueGrey[600],
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatTimeRange(meeting.startTime, meeting.endTime),
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blueGrey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                if (meeting.summary.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    meeting.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[800],
                      height: 1.5,
                    ),
                  ),
                ],
                if (keypoints.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Key Points',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.blueGrey[900],
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...keypoints
                      .take(2)
                      .map(
                        (point) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '•',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  point,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Colors.grey[800],
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  if (keypoints.length > 2)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'and ${keypoints.length - 2} more...',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueGrey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: Icon(
                      Icons.delete,
                      color: Theme.of(context).colorScheme.error,
                      size: 24,
                    ),
                    onPressed: () => _deleteMeeting(meeting.id, index),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateSection(DateTime date, List<Widget> meetingTiles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Text(
            _formatDateHeader(date),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.blueGrey[900],
              letterSpacing: 0.5,
            ),
          ),
        ),
        ...meetingTiles,
      ],
    );
  }

  List<Widget> _buildGroupedMeetingList() {
    if (_meetings.isEmpty) return [];

    final Map<String, List<Meeting>> groupedMeetings = {};
    for (final meeting in _meetings) {
      final start = DateTime.tryParse(meeting.startTime);
      if (start == null) continue;

      final dateKey = DateFormat('yyyy-MM-dd').format(start);
      groupedMeetings.putIfAbsent(dateKey, () => []);
      groupedMeetings[dateKey]!.add(meeting);
    }

    final sortedDates =
        groupedMeetings.keys.toList()..sort((a, b) => b.compareTo(a));

    final List<Widget> widgets = [];
    for (final dateKey in sortedDates) {
      final date = DateTime.parse(dateKey);
      final meetings = groupedMeetings[dateKey]!;

      final meetingTiles =
          meetings
              .asMap()
              .entries
              .map((entry) => _buildMeetingTile(entry.value, entry.key))
              .toList();

      widgets.add(_buildDateSection(date, meetingTiles));
    }

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: AppBar(
          title: const Text(
            'Meetings & Notes',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
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
      ),
      body:
          _isLoading
              ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                  strokeWidth: 3,
                ),
              )
              : _meetings.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_note,
                      size: 80,
                      color: Colors.blueGrey[300],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "No Meetings Found",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey[600],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Start a new meeting to see it here!",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueGrey[500],
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadMeetings,
                color: Theme.of(context).colorScheme.primary,
                backgroundColor: Colors.white,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 24),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate(
                          _buildGroupedMeetingList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
