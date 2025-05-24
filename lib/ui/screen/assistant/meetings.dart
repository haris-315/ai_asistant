// ignore_for_file: use_build_context_synchronously

import 'package:ai_asistant/core/services/db_helper.dart';
import 'package:ai_asistant/data/models/service_models/meeting.dart';
import 'package:ai_asistant/ui/screen/assistant/meeting_details.dart';
import 'package:ai_asistant/ui/widget/appbar.dart';
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
          content: Text(result.info),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      meeting.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (duration.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        duration,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTimeRange(meeting.startTime, meeting.endTime),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              if (meeting.summary.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  meeting.summary,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(
                    Icons.delete,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  onPressed: () => _deleteMeeting(meeting.id, index),
                ),
              ),
            ],
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
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Text(
            _formatDateHeader(date),
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
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
      backgroundColor: Colors.white,
      appBar: CustomAppBar(title: "Meetings And Notes"),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _meetings.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.event_note,
                      size: 64,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "No meetings found",
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadMeetings,
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.only(bottom: 16),
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
