import 'package:ai_asistant/Controller/auth_controller.dart';
import 'package:ai_asistant/data/models/emails/thread_detail.dart';
import 'package:ai_asistant/ui/widget/dateformat.dart';
import 'package:ai_asistant/ui/widget/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:hive/hive.dart';

class EmailSearchScreen extends StatefulWidget {
  final String initialQuery;

  const EmailSearchScreen({super.key, required this.initialQuery});

  @override
  State<EmailSearchScreen> createState() => _EmailSearchScreenState();
}

class _EmailSearchScreenState extends State<EmailSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AuthController _authController = Get.find<AuthController>();
  final FocusNode _searchFocusNode = FocusNode();

  List<EmailMessage> _emails = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasReachedEnd = false;
  bool _isLoadingDetails = false;
  int _skip = 0;
  static const int _limit = 15;
  String _currentQuery = '';

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.initialQuery;
    _currentQuery = widget.initialQuery;
    if (widget.initialQuery.isNotEmpty) {
      _searchEmails(widget.initialQuery);
    }
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        !_hasReachedEnd &&
        _currentQuery.isNotEmpty) {
      _loadMoreEmails();
    }
  }

  Future<void> _searchEmails(String query) async {
    if (_isLoading || query.isEmpty) return;

    setState(() {
      _isLoading = true;
      _emails = [];
      _skip = 0;
      _hasReachedEnd = false;
      _currentQuery = query;
    });

    try {
      final box = await _openBox();
      final queryLower = query.toLowerCase();
      final results =
          box.values
              .where(
                (email) =>
                    (email.subject?.toLowerCase() ?? '').contains(queryLower) ||
                    (email.senderName?.toLowerCase() ?? '').contains(
                      queryLower,
                    ) ||
                    (email.sender?.toLowerCase() ?? '').contains(queryLower) ||
                    (email.bodyPlain?.toLowerCase() ?? '').contains(
                      queryLower,
                    ) ||
                    (email.summary?.toLowerCase() ?? '').contains(queryLower),
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
      final queryLower = _currentQuery.toLowerCase();
      final results =
          box.values
              .where(
                (email) =>
                    (email.subject?.toLowerCase() ?? '').contains(queryLower) ||
                    (email.senderName?.toLowerCase() ?? '').contains(
                      queryLower,
                    ) ||
                    (email.sender?.toLowerCase() ?? '').contains(queryLower) ||
                    (email.bodyPlain?.toLowerCase() ?? '').contains(
                      queryLower,
                    ) ||
                    (email.summary?.toLowerCase() ?? '').contains(queryLower),
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

      // Uncomment when you have the actual implementation
      // final threadData = await _authController.GetThreadbyID(
      //   threadId,
      //   null,
      //   notToShowLoader: true,
      // );

      // if (threadData != null && threadData.isNotEmpty) {
      //   Get.to(() => EmailDetailScreen(threadAndData: threadData));
      // } else {
      //   _showErrorSnackbar('Failed to load email details.');
      // }
    } finally {
      if (mounted) {
        setState(() => _isLoadingDetails = false);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: Icon(Icons.arrow_drop_down),
        ),
        title: _buildSearchField(),
        actions: [
          if (_currentQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                _searchEmails('');
              },
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: _buildFloatingActionButton(),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      focusNode: _searchFocusNode,
      decoration: InputDecoration(
        hintText: 'Search emails...',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(12),
        ),
        suffixIcon:
            _isLoading
                ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
                : null,
      ),
      onChanged: (value) => _debounceSearch(value),
      onSubmitted: (value) => _searchEmails(value),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _emails.isEmpty) {
      return const Center(child: SpinKitSpinningLines(color: Colors.blue));
    }

    if (_emails.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.search, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _currentQuery.isEmpty
                    ? 'Search for emails by sender, subject or content'
                    : 'No results found for "$_currentQuery"',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_emails.length} results',
                style: TextStyle(color: Colors.grey[600], fontSize: 14),
              ),
              const Spacer(),
              if (_emails.isNotEmpty)
                TextButton(
                  onPressed: () {
                    _scrollController.animateTo(
                      0,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  },
                  child: const Text('Top'),
                ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _emails.length + (_isLoadingMore ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _emails.length) {
                return _buildLoadingMoreIndicator();
              }
              return EmailSearchItem(
                email: _emails[index],
                onTap: () => _navigateToDetails(_emails[index]),
                isLoadingDetails: _isLoadingDetails,
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton() {
    if (_emails.isEmpty) return null;

    return FloatingActionButton(
      backgroundColor: Theme.of(context).primaryColor,
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

  void _debounceSearch(String value) {
    // Implement debounce logic if needed
    _searchEmails(value);
  }
}

class EmailSearchItem extends StatelessWidget {
  final EmailMessage email;
  final VoidCallback onTap;
  final bool isLoadingDetails;

  const EmailSearchItem({
    super.key,
    required this.email,
    required this.onTap,
    required this.isLoadingDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = email.isRead ?? false;
    final textColor = isRead ? Colors.grey[600] : Colors.grey[800];
    final fontWeight = isRead ? FontWeight.normal : FontWeight.w500;
    final senderName = email.senderName ?? email.sender ?? 'Unknown';
    final initials = senderName.isNotEmpty ? senderName[0].toUpperCase() : 'U';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: isLoadingDetails ? null : onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        Colors.primaries[senderName.hashCode %
                            Colors.primaries.length],
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          senderName,
                          style: TextStyle(
                            color: textColor,
                            fontWeight: fontWeight,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatEmailDate(
                            email.receivedAt?.toIso8601String() ?? '',
                          ),
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 12,
                          ),
                        ),
                      ],
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
                  if (email.hasAttachments ?? false)
                    const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.attach_file,
                        size: 18,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                email.subject ?? 'No Subject',
                style: TextStyle(
                  color: textColor,
                  fontWeight: fontWeight,
                  fontSize: 16,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (email.summary?.isNotEmpty ?? false) ...[
                const SizedBox(height: 8),
                Text(
                  email.summary!,
                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
