import 'package:ai_asistant/data/models/emails/thread_detail.dart';
import 'package:ai_asistant/ui/screen/home/emails/email_details_screen.dart';
import 'package:ai_asistant/ui/widget/dateformat.dart';
import 'package:ai_asistant/ui/widget/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class EmailsWithTasksScreen extends StatefulWidget {
  const EmailsWithTasksScreen({super.key});

  @override
  State<EmailsWithTasksScreen> createState() => _EmailsWithTasksScreenState();
}

class _EmailsWithTasksScreenState extends State<EmailsWithTasksScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _searchFocusNode = FocusNode();

  List<EmailMessage> _emails = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasReachedEnd = false;
  bool _isLoadingDetails = false;
  int _skip = 0;
  static const int _limit = 6;

  @override
  void initState() {
    super.initState();
    _searchEmails();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedEnd) {
      _loadMoreEmails();
    }
  }

  Future<void> _searchEmails() async {
    setState(() {
      _isLoading = true;
      _emails = [];
      _skip = 0;
      _hasReachedEnd = false;
    });

    try {
      final box = await _openBox();

      final results =
          box.values
              .where(
                (email) =>
                    email.extracted_tasks != null &&
                    email.extracted_tasks!.isNotEmpty,
              )
              .skip(_skip)
              .take(_limit)
              .toList();

      setState(() {
        _emails = results.cast<EmailMessage>();
        _skip += results.length;
        _hasReachedEnd = results.length < _limit;
        _isLoading = false;
      });
    } catch (e) {
      _showErrorSnackbar('An error occurred while searching emails: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreEmails() async {
    if (_isLoadingMore || _hasReachedEnd) return;
    setState(() => _isLoadingMore = true);

    try {
      final box = await _openBox();
      final results =
          box.values
              .where(
                (email) =>
                    email.extracted_tasks != null &&
                    email.extracted_tasks!.isNotEmpty,
              )
              .skip(_skip)
              .take(_limit)
              .toList();

      setState(() {
        _emails.addAll(results.cast<EmailMessage>());
        _skip += results.length;
        _hasReachedEnd = results.length < _limit;
        _isLoadingMore = false;
      });
    } catch (e) {
      _showErrorSnackbar('An error occurred while loading more emails: $e');
      setState(() => _isLoadingMore = false);
    }
  }

  Future<Box<EmailMessage>> _openBox() async {
    if (!Hive.isBoxOpen('emails')) {
      await Hive.openBox<EmailMessage>('emails');
    }
    return Hive.box<EmailMessage>('emails');
  }

  void _showErrorSnackbar(String message) {
    showCustomSnackbar(
      title: 'Error',
      message: message,
      backgroundColor: Colors.red,
    );
  }

  Future<void> _navigateToDetails(EmailMessage email) async {
    if (_isLoadingDetails) return;
    setState(() => _isLoadingDetails = true);

    try {
      final threadId = email.id ?? '';
      if (threadId.isEmpty) {
        _showErrorSnackbar('Invalid email ID.');
        return;
      }

      Get.to(
        () => EmailDetailScreen(
          subject: email.subject ?? "",
          summary: email.summary ?? "",
          conversationId: email.id ?? "",
          threadAndData: {
            "thread_mails": [email],
          },
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
        ),
        title: Text(
          "Emails Including Tasks",
          style: TextStyle(color: Colors.grey[450]),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[50]!, Colors.grey[100]!],
          ),
        ),
        child: _buildBody(),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  Widget _buildBody() {
    if (_isLoading && _emails.isEmpty) {
      return const Center(
        child: SpinKitFadingCircle(color: Colors.blue, size: 50.0),
      );
    }

    if (_emails.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.email_outlined, size: 64, color: Colors.blue[300]),
            const SizedBox(height: 16),
            Text(
              "You have no emails that include tasks.",
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Text(
                '${_emails.length} ${_emails.length == 1 ? 'result' : 'results'}',
                style: TextStyle(
                  color: Colors.blue[800],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(),
              if (_emails.isNotEmpty)
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[800],
                  ),
                  onPressed: () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  child: const Text('Back to top'),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.only(bottom: 16),
            itemCount: _emails.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _emails.length) {
                return _buildLoadingMoreIndicator();
              }
              return _buildEmailCard(_emails[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmailCard(EmailMessage email) {
    final isRead = email.isRead ?? false;
    final senderName = email.senderName ?? email.sender ?? 'Unknown';
    final initials = senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U';
    final hasAttachment = email.hasAttachments ?? false;
    final date = formatEmailDate(email.receivedAt?.toIso8601String() ?? '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToDetails(email),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            Colors.primaries[senderName.hashCode %
                                Colors.primaries.length],
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        initials,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  senderName,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        isRead
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                    color:
                                        isRead
                                            ? Colors.grey[600]
                                            : Colors.grey[800],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (!isRead)
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            date,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasAttachment)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(
                          Icons.attach_file,
                          size: 20,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  email.subject ?? 'No Subject',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: isRead ? FontWeight.normal : FontWeight.w600,
                    color: isRead ? Colors.grey[700] : Colors.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.summary?.isNotEmpty ?? false) ...[
                  const SizedBox(height: 8),
                  Text(
                    email.summary!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.blue[800],
          ),
        ),
      ),
    );
  }

  // ignore: unused_element
  Widget? _buildFloatingActionButton() {
    if (_emails.isEmpty) return null;

    return FloatingActionButton(
      backgroundColor: Colors.blue[800],
      child: const Icon(Icons.arrow_upward, color: Colors.white),
      onPressed: () {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      },
    );
  }
}
