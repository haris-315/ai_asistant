// ignore_for_file: use_build_context_synchronously

import 'package:ai_asistant/Controller/auth_Controller.dart';
import 'package:ai_asistant/core/shared/functions/show_snackbar.dart';
import 'package:ai_asistant/data/models/emails/threadDetail.dart';
import 'package:ai_asistant/data/models/threadmodel.dart';
import 'package:ai_asistant/state_mgmt/email/cubit/email_cubit.dart';
import 'package:ai_asistant/ui/screen/home/emails/email_details_screen.dart';
import 'package:ai_asistant/ui/screen/home/emails/newemail_screen.dart';
import 'package:ai_asistant/ui/widget/appbar.dart';
import 'package:ai_asistant/ui/widget/dateFormat.dart';
import 'package:ai_asistant/ui/widget/drawer.dart';
import 'package:ai_asistant/ui/widget/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';

class AllEmailScreen extends StatefulWidget {
  const AllEmailScreen({super.key});

  @override
  State<AllEmailScreen> createState() => _AllEmailScreenState();
}

class _AllEmailScreenState extends State<AllEmailScreen> {
  final TextEditingController searchController = TextEditingController();
  String currentFilter = "all";
  List<EmailThread> emails = [];
  List<EmailThread> emailsAll = [];
  bool isSearching = false;
  final AuthController authcontroller = Get.find<AuthController>();
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _showScrollToTop = false;
  Map<String, bool> expandedStates = {};
  Map<String, bool> summaryLoadingStates = {};

  @override
  void initState() {
    super.initState();
    context.read<EmailCubit>().getEmails();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    final cubit = context.read<EmailCubit>();
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore &&
        !cubit.hasReachedEnd) {
      setState(() => _isLoadingMore = true);
      cubit.getEmails(loadAgain: false);
    }

    if (_scrollController.position.pixels > 300 && !_showScrollToTop) {
      setState(() => _showScrollToTop = true);
    } else if (_scrollController.position.pixels <= 300 && _showScrollToTop) {
      setState(() => _showScrollToTop = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getSenderName(String? sender) {
    if (sender == null || sender.isEmpty) return "Unknown";
    final nameMatch = RegExp(r'^"?([^<"]+)"?\s*<[^>]+>$').firstMatch(sender);
    if (nameMatch != null && nameMatch.group(1)!.trim().isNotEmpty) {
      return nameMatch.group(1)!.trim();
    }
    return sender.contains('@') ? sender.split('@').first : sender;
  }

  Color getPriorityColor(int score) {
    if (score >= 81) return Colors.redAccent;
    if (score >= 61) return Colors.orangeAccent;
    if (score >= 41) return Colors.amber;
    return Colors.green;
  }

  String getPriorityLabel(int score) {
    if (score >= 81) return "Critical";
    if (score >= 61) return "High";
    if (score >= 41) return "Medium";
    return "Low";
  }

  void _toggleExpandEmail(String emailId) {
    setState(() {
      expandedStates[emailId] = !(expandedStates[emailId] ?? false);
    });
  }

  Future<void> _loadSummary(EmailThread email) async {
    if (email.summary != null && email.summary!.isNotEmpty) return;

    setState(() {
      summaryLoadingStates[email.conversationId] = true;
    });

    final res = await authcontroller.threadAiProccess(email.conversationId);

    setState(() {
      summaryLoadingStates[email.conversationId] = false;
    });

    if (res != null) {
      final index = emails.indexWhere(
        (e) => e.conversationId == email.conversationId,
      );
      if (index != -1) {
        setState(() {
          emails[index] = emails[index].copyWith(
            summary: res.summary,
            topic: res.topic,
          );
        });
      }
    }
  }

  Future<void> _handleReply(EmailThread email) async {
    final res = await authcontroller.GetThreadbyID(email.conversationId, email);
    if (res != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (_) => NewMessageScreen(
                isReplying: true,
                toEmail: (res['thread_mails'] as List<EmailMessage>).last,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EmailCubit, EmailState>(
      listener: (context, state) {
        if (state is EmailError) {
          showSnackBar(context: context, message: state.message, isError: true);
        } else if (state is EmailSuccess) {
          if (currentFilter == "all") emailsAll = state.emails;
          emails = state.emails;
          setState(() => _isLoadingMore = false);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: CustomAppBar(title: "AI Assistant"),
          drawer: SideMenu(),
          body: Stack(
            children: [
              RefreshIndicator(
                onRefresh: () async {
                  searchController.clear();
                  await authcontroller.syncMailboxPeriodically();
                  await context.read<EmailCubit>().getEmails();
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    children: [
                      TextField(
                        controller: searchController,
                        onChanged: (value) {
                          setState(() {
                            isSearching = value.isNotEmpty;
                            emails =
                                emailsAll
                                    .where(
                                      (email) =>
                                          email.subject?.toLowerCase().contains(
                                            value.toLowerCase(),
                                          ) ??
                                          false,
                                    )
                                    .toList();
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Search emails...',
                          prefixIcon: Icon(Icons.search),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.symmetric(horizontal: 16),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      SizedBox(height: 12),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ChoiceChip(
                              label: Text("All"),
                              selected: currentFilter == "all",
                              onSelected: (val) {
                                setState(() {
                                  currentFilter = "all";
                                  emails = emailsAll;
                                });
                              },
                            ),
                            SizedBox(width: 8),
                            ChoiceChip(
                              label: Text("With Tasks"),
                              selected: currentFilter == "tasks",
                              onSelected: (val) {
                                setState(() {
                                  currentFilter = "tasks";
                                  emails =
                                      emailsAll
                                          .where(
                                            (e) =>
                                                e.extracted_tasks != null &&
                                                e.extracted_tasks!.isNotEmpty,
                                          )
                                          .toList();
                                });
                              },
                            ),
                            SizedBox(width: 8),
                            ChoiceChip(
                              label: Text("Urgent"),
                              selected: currentFilter == "urgent",
                              onSelected: (val) {
                                setState(() {
                                  currentFilter = "urgent";
                                  emails =
                                      emailsAll
                                          .where((e) => e.category == "urgent")
                                          .toList();
                                });
                              },
                            ),
                            SizedBox(width: 8),
                            ChoiceChip(
                              label: Text("Informational"),
                              selected: currentFilter == "informational",
                              onSelected: (val) {
                                setState(() {
                                  currentFilter = "informational";
                                  emails =
                                      emailsAll
                                          .where(
                                            (e) =>
                                                e.category == "informational",
                                          )
                                          .toList();
                                });
                              },
                            ),
                            SizedBox(width: 8),
                            ChoiceChip(
                              label: Text("Normal"),
                              selected: currentFilter == "normal",
                              onSelected: (val) {
                                setState(() {
                                  currentFilter = "normal";
                                  emails =
                                      emailsAll
                                          .where((e) => e.category == "normal")
                                          .toList();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 12),

                      // 📩 Email List
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: emails.length,
                          itemBuilder: (context, index) {
                            final email = emails[index];
                            final senderName = _getSenderName(email.lastSender);
                            final priorityColor = getPriorityColor(
                              email.priority_score ?? 10,
                            );

                            final isExpanded =
                                expandedStates[email.conversationId] ?? false;
                            final isLoadingSummary =
                                summaryLoadingStates[email.conversationId] ??
                                false;

                            return Container(
                              margin: EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: priorityColor.withValues(
                                  alpha: 0.65,
                                ), // Increased opacity to 25%
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 4,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    onTap: () async {
                                      String? emailId = email.conversationId;
                                      if (emailId.isEmpty) {
                                        showCustomSnackbar(
                                          title: "Error",
                                          message: "Invalid email ID.",
                                          backgroundColor: Colors.red,
                                        );
                                        return;
                                      }
                                      var threadData =
                                          await authcontroller.GetThreadbyID(
                                            emailId,
                                            email,
                                          );
                                      if (threadData != null &&
                                          threadData.isNotEmpty) {
                                        Get.to(
                                          () => EmailDetailScreen(
                                            threadAndData: threadData,
                                          ),
                                        );
                                      } else {
                                        showCustomSnackbar(
                                          title: "Error",
                                          message:
                                              "Failed to load email details.",
                                          backgroundColor: Colors.red,
                                        );
                                      }
                                    },
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          Colors.primaries[(email
                                                      .lastSender
                                                      ?.hashCode ??
                                                  0) %
                                              Colors.primaries.length],
                                      child: Text(
                                        senderName.isNotEmpty
                                            ? senderName[0].toUpperCase()
                                            : "U",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    title: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          senderName,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(height: 6),
                                      ],
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        email.subject ?? "No Subject",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w900,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    trailing: ConstrainedBox(
                                      constraints: BoxConstraints(
                                        maxWidth: 120, // Prevent overflow
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          if (email.hasAttachments)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                right: 8.0,
                                              ),
                                              child: Icon(
                                                Icons.attach_file,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                          Text(
                                            email.lastEmailAt != null
                                                ? formatEmailDate(
                                                  email.lastEmailAt!
                                                      .toIso8601String(),
                                                )
                                                : "",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              isExpanded
                                                  ? Icons.keyboard_arrow_up
                                                  : Icons.keyboard_arrow_down,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                            padding: EdgeInsets.zero,
                                            constraints: BoxConstraints(),
                                            onPressed: () {
                                              _toggleExpandEmail(
                                                email.conversationId,
                                              );
                                              if (isExpanded &&
                                                  (email.summary == null ||
                                                      email.summary!.isEmpty)) {
                                                _loadSummary(email);
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  if (isExpanded)
                                    Container(
                                      padding: EdgeInsets.only(
                                        top: 16.0,
                                        left: 16.0,
                                        right: 16.0,
                                        bottom: 8,
                                        // vertical: 12.0,
                                      ),
                                      margin: EdgeInsets.only(top: 12),
                                      decoration: BoxDecoration(
                                        color: priorityColor.withValues(
                                          alpha: 0.65,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Summary:",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                              fontSize: 16,
                                            ),
                                          ),
                                          SizedBox(height: 8),
                                          isLoadingSummary
                                              ? Center(
                                                child:
                                                    CircularProgressIndicator(),
                                              )
                                              : Text(
                                                email.summary ??
                                                    "No summary available",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                ),
                                              ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ⬆️ Scroll to Top Button
              if (_showScrollToTop)
                Positioned(
                  bottom: 90,
                  right: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: Colors.grey[800],
                    onPressed: _scrollToTop,
                    child: Icon(Icons.arrow_upward, color: Colors.white),
                  ),
                ),
            ],
          ),

          // 📝 Compose Button
          floatingActionButton: FloatingActionButton.extended(
            heroTag: "bawoooo!",
            label: Text(
              "Compose",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: Colors.blue[600],
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            icon: Icon(Icons.send, color: Colors.white),
            onPressed: () => Get.to(() => NewMessageScreen()),
          ),
        );
      },
    );
  }
}
