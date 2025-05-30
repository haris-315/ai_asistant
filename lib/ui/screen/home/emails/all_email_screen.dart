// ignore_for_file: use_build_context_synchronously

import 'package:ai_asistant/Controller/auth_controller.dart';
import 'package:ai_asistant/core/shared/functions/is_today.dart';
import 'package:ai_asistant/core/shared/functions/show_snackbar.dart';
import 'package:ai_asistant/data/models/threadmodel.dart';
import 'package:ai_asistant/state_mgmt/email/cubit/email_cubit.dart';
import 'package:ai_asistant/ui/screen/home/emails/email_details_screen.dart';
import 'package:ai_asistant/ui/screen/home/emails/emails_search_screen.dart';
import 'package:ai_asistant/ui/widget/dateformat.dart';
import 'package:ai_asistant/ui/widget/snackbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:page_transition/page_transition.dart';

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
  bool _isRefreshing = false;
  bool _loadingDetails = false;
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
      if (mounted) setState(() => _isLoadingMore = true);
      cubit.getEmails(loadAgain: false);
    }

    if (_scrollController.position.pixels > 300 && !_showScrollToTop) {
      if (mounted) setState(() => _showScrollToTop = true);
    } else if (_scrollController.position.pixels <= 300 && _showScrollToTop) {
      if (mounted) setState(() => _showScrollToTop = false);
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: Duration(milliseconds: 660),
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
    if (mounted) {
      setState(() {
        expandedStates[emailId] = !(expandedStates[emailId] ?? false);
      });
    }
  }

  Future<void> _loadSummary(EmailThread email) async {
    if (email.summary != null && email.summary!.isNotEmpty) return;

    if (mounted) {
      setState(() {
        _loadingDetails = true;
        summaryLoadingStates[email.conversationId] = true;
      });
    }

    final res = await authcontroller.threadAiProccess(email.conversationId);

    if (mounted) {
      setState(() {
        _loadingDetails = false;
        summaryLoadingStates[email.conversationId] = false;
      });
    }

    if (res != null) {
      final index = emails.indexWhere(
        (e) => e.conversationId == email.conversationId,
      );
      if (index != -1) {
        if (mounted) {
          setState(() {
            emails[index] = emails[index].copyWith(
              summary: res.summary,
              topic: res.topic,
            );
          });
        }
      }
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
          if (mounted) setState(() => _isLoadingMore = false);
        }
      },
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh:
              _loadingDetails
                  ? () async {}
                  : () async {
                    if (mounted) {
                      setState(() {
                        _isRefreshing = true;
                      });
                    }
                    searchController.clear();
                    await authcontroller.syncMailboxbulk();
                    await context.read<EmailCubit>().getEmails();

                    if (mounted) {
                      setState(() {
                        _isRefreshing = false;
                      });
                    }
                  },
          child:
              (state is EmailLoading && emails.isEmpty && !_isRefreshing)
                  ? Center(
                    child: SpinKitSpinningLines(color: Colors.blue.shade800),
                  )
                  : Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "You have recived ${emails.where((t) => isToday(t.lastEmailAt ?? DateTime(1999))).length} emails today",
                                ),
                                IconButton.outlined(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      PageTransition(
                                        type: PageTransitionType.bottomToTop,
                                        child: EmailSearchScreen(
                                          initialQuery: '',
                                        ),
                                      ),
                                    );
                                  },
                                  icon: Icon(Icons.search),
                                  style: ButtonStyle(),
                                  color: Colors.blue,
                                ),
                              ],
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
                                      if (mounted) {
                                        setState(() {
                                          currentFilter = "all";
                                          emails = emailsAll;
                                        });
                                      }
                                    },
                                  ),
                                  SizedBox(width: 8),
                                  // ChoiceChip(
                                  //   label: Text("With Tasks"),
                                  //   selected: currentFilter == "tasks",
                                  //   onSelected:
                                  //       _loadingDetails
                                  //           ? (v) {}
                                  //           : (val) {
                                  //             if (mounted) setState(() {
                                  //               currentFilter = "tasks";
                                  //               emails =
                                  //                   emailsAll
                                  //                       .where(
                                  //                         (e) =>
                                  //                             e.extracted_tasks !=
                                  //                                 null &&
                                  //                             e
                                  //                                 .extracted_tasks!
                                  //                                 .isNotEmpty,
                                  //                       )
                                  //                       .toList();
                                  //             });
                                  //           },
                                  // ),
                                  // SizedBox(width: 8),
                                  ChoiceChip(
                                    label: Text("Urgent"),
                                    selected: currentFilter == "urgent",
                                    onSelected: (val) {
                                      if (mounted) {
                                        setState(() {
                                          currentFilter = "urgent";
                                          emails =
                                              emailsAll
                                                  .where(
                                                    (e) =>
                                                        e.category == "urgent",
                                                  )
                                                  .toList();
                                        });
                                      }
                                    },
                                  ),
                                  SizedBox(width: 8),
                                  ChoiceChip(
                                    label: Text("Informational"),
                                    selected: currentFilter == "informational",
                                    onSelected: (val) {
                                      if (mounted) {
                                        setState(() {
                                          currentFilter = "informational";
                                          emails =
                                              emailsAll
                                                  .where(
                                                    (e) =>
                                                        e.category ==
                                                        "informational",
                                                  )
                                                  .toList();
                                        });
                                      }
                                    },
                                  ),
                                  SizedBox(width: 8),
                                  ChoiceChip(
                                    label: Text("Normal"),
                                    selected: currentFilter == "normal",
                                    onSelected: (val) {
                                      if (mounted) {
                                        setState(() {
                                          currentFilter = "normal";
                                          emails =
                                              emailsAll
                                                  .where(
                                                    (e) =>
                                                        e.category == "normal",
                                                  )
                                                  .toList();
                                        });
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 3),
                            if (_loadingDetails)
                              LinearProgressIndicator(color: Colors.blue),
                            SizedBox(height: 12),

                            Expanded(
                              child: ListView.builder(
                                controller: _scrollController,
                                itemCount: emails.length,
                                itemBuilder: (context, index) {
                                  EmailThread email = emails[index];
                                  final senderName =
                                      email.last_sender_name != null &&
                                              email.last_sender_name!.isNotEmpty
                                          ? email.last_sender_name
                                          : _getSenderName(email.lastSender);

                                  final isExpanded =
                                      expandedStates[email.conversationId] ??
                                      false;
                                  final isLoadingSummary =
                                      summaryLoadingStates[email
                                          .conversationId] ??
                                      false;
                                  Color emailColor =
                                      email.is_read
                                          ? Colors.grey[700] ?? Colors.grey
                                          : Colors.black;
                                  FontWeight emailFontWeight =
                                      email.is_read
                                          ? FontWeight.w400
                                          : FontWeight.bold;

                                  return Container(
                                    margin: EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
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
                                        Container(
                                          decoration: BoxDecoration(
                                            border:
                                                (email.priority_score ?? 10) >=
                                                            80 &&
                                                        !email.is_read
                                                    ? BorderDirectional(
                                                      start: BorderSide(
                                                        color: Colors.redAccent,
                                                        width: 6,
                                                      ),
                                                    )
                                                    : null,
                                            borderRadius: BorderRadius.only(
                                              topLeft: Radius.circular(12),
                                              topRight: Radius.circular(12),
                                              bottomLeft: Radius.circular(
                                                isExpanded ? 0 : 12,
                                              ),
                                              bottomRight: Radius.circular(
                                                isExpanded ? 0 : 12,
                                              ),
                                            ),
                                          ),
                                          child: ListTile(
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 12,
                                                ),
                                            onTap:
                                                _loadingDetails
                                                    ? null
                                                    : () async {
                                                      if (mounted) {
                                                        setState(() {
                                                          int index = emails
                                                              .indexOf(email);
                                                          if (index != 1) {
                                                            emails[index] =
                                                                email.copyWith(
                                                                  is_read: true,
                                                                );

                                                            _loadingDetails =
                                                                true;
                                                          }
                                                        });
                                                      }
                                                      String? emailId =
                                                          email.conversationId;
                                                      if (emailId.isEmpty) {
                                                        showCustomSnackbar(
                                                          title: "Error",
                                                          message:
                                                              "Invalid email ID.",
                                                          backgroundColor:
                                                              Colors.red,
                                                        );
                                                        return;
                                                      }
                                                      var threadData =
                                                          await authcontroller.GetThreadbyID(
                                                            emailId,
                                                            email,
                                                            notToShowLoader:
                                                                true,
                                                          );
                                                      if (mounted) {
                                                        setState(() {
                                                          _loadingDetails =
                                                              false;
                                                        });
                                                      }
                                                      if (threadData != null &&
                                                          threadData
                                                              .isNotEmpty) {
                                                        Get.to(
                                                          () =>
                                                              EmailDetailScreen(
                                                                threadAndData:
                                                                    threadData,
                                                              ),
                                                        );
                                                      } else {
                                                        showCustomSnackbar(
                                                          title: "Error",
                                                          message:
                                                              "Failed to load email details.",
                                                          backgroundColor:
                                                              Colors.red,
                                                        );
                                                      }
                                                    },
                                            leading: CircleAvatar(
                                              backgroundColor: Colors
                                                  .primaries[(email
                                                              .lastSender
                                                              ?.hashCode ??
                                                          0) %
                                                      Colors.primaries.length]
                                                  .withValues(alpha: 0.7),
                                              child: Text(
                                                senderName!.isNotEmpty
                                                    ? senderName[0]
                                                        .toUpperCase()
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
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        senderName,
                                                        maxLines: 1,
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                        style: TextStyle(
                                                          color: emailColor,
                                                          fontWeight:
                                                              emailFontWeight,
                                                        ),
                                                      ),
                                                    ),
                                                    SizedBox(width: 3),
                                                    if ((email.totalCount ??
                                                            0) !=
                                                        1)
                                                      Text(
                                                        "(${(email.totalCount ?? 0).toString()})",
                                                        style: TextStyle(
                                                          color:
                                                              Colors.grey[600],
                                                          fontWeight:
                                                              FontWeight.w600,
                                                          fontSize: 9,
                                                        ),
                                                        overflow:
                                                            TextOverflow
                                                                .ellipsis,
                                                      ),
                                                    SizedBox(width: 2),
                                                    if (!email.is_read)
                                                      Container(
                                                        width: 7,
                                                        height: 7,
                                                        decoration:
                                                            const BoxDecoration(
                                                              color:
                                                                  Colors
                                                                      .greenAccent,
                                                              shape:
                                                                  BoxShape
                                                                      .circle,
                                                            ),
                                                      ),
                                                    if (email.has_attachments ??
                                                        false) ...[
                                                      SizedBox(width: 3),
                                                      Icon(Icons.attach_email),
                                                    ],
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                              ],
                                            ),

                                            subtitle: Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8.0,
                                                bottom: 8.0,
                                              ),
                                              child: Text(
                                                email.subject ?? "No Subject",
                                                style: TextStyle(
                                                  color: emailColor,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            trailing: GestureDetector(
                                              onTap:
                                                  _loadingDetails
                                                      ? null
                                                      : () {
                                                        _toggleExpandEmail(
                                                          email.conversationId,
                                                        );
                                                        if (!isExpanded &&
                                                            (email.summary ==
                                                                    null ||
                                                                email
                                                                    .summary!
                                                                    .isEmpty)) {
                                                          _loadSummary(email);
                                                        }
                                                      },
                                              child: ConstrainedBox(
                                                constraints: BoxConstraints(
                                                  maxWidth:
                                                      MediaQuery.of(
                                                        context,
                                                      ).size.width *
                                                      0.25,
                                                ),
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    SizedBox(height: 4),
                                                    Row(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      children: [
                                                        Flexible(
                                                          child: Text(
                                                            email.lastEmailAt !=
                                                                    null
                                                                ? formatEmailDate(
                                                                  email
                                                                      .lastEmailAt!
                                                                      .toIso8601String(),
                                                                )
                                                                : "",
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.black,
                                                              fontSize: 12,
                                                            ),
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            maxLines: 1,
                                                          ),
                                                        ),
                                                        SizedBox(width: 4),
                                                        Icon(
                                                          isExpanded
                                                              ? Icons
                                                                  .keyboard_arrow_up
                                                              : Icons
                                                                  .keyboard_arrow_down,
                                                          color: emailColor,
                                                          size: 18,
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),
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
                                            ),
                                            margin: EdgeInsets.only(top: 12),
                                            decoration: BoxDecoration(
                                              color: const Color.fromRGBO(
                                                255,
                                                255,
                                                255,
                                                1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  "Summary:",
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black,
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
                                                        color: Colors.black,
                                                        fontWeight:
                                                            FontWeight.w700,
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
                            SizedBox(height: 20),
                            if (state is EmailLoading &&
                                emails.isNotEmpty &&
                                !_isRefreshing)
                              Center(
                                child: SpinKitPouringHourGlassRefined(
                                  size: 35,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            SizedBox(height: 5),
                          ],
                        ),
                      ),
                      if (_showScrollToTop)
                        Positioned(
                          bottom: 90,
                          right: 16,
                          child: FloatingActionButton(
                            mini: true,
                            heroTag: "allemailscreenfab_____",
                            backgroundColor: Colors.blue[600],
                            onPressed: _scrollToTop,
                            child: Icon(
                              Icons.arrow_upward,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
        );
      },
    );
  }
}
