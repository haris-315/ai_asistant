import 'package:ai_asistant/Controller/auth_Controller.dart';
import 'package:ai_asistant/core/shared/functions/show_snackbar.dart';
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
import 'package:flutter_spinkit/flutter_spinkit.dart';
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
      setState(() {
        _isLoadingMore = true;
      });
      cubit.getEmails(loadAgain: false);
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String formatSender(String sender) {
    if (sender.length <= 20) return sender;
    return "${sender.substring(0, 17)}...";
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EmailCubit, EmailState>(
      listener: (context, state) {
        if (state is EmailError) {
          showSnackBar(context: context, message: state.message, isError: true);
        } else if (state is EmailSuccess) {
          if (currentFilter == "all") {
            emailsAll = state.emails;
          }
          emails = state.emails;
          setState(() {
            _isLoadingMore = false;
          });
        }
      },
      builder: (context, state) {
        return RefreshIndicator(
          onRefresh: () async {
            searchController.clear();
            await authcontroller.syncMailboxPeriodically();
            await authcontroller.fetchEmails();
          },
          child: Scaffold(
            appBar: CustomAppBar(
              title: "AI Assistant",
              onNotificationPressed: () => print("Notification Clicked!"),
              onProfilePressed: () => print("Profile Clicked!"),
            ),
            drawer: SideMenu(),
            backgroundColor: Colors.white,
            floatingActionButton: FloatingActionButton(
              backgroundColor: Colors.blue,
              shape: StarBorder.polygon(sides: 8),
              child: Icon(Icons.add, color: Colors.white),
              onPressed: () => Get.to(() => NewMessageScreen()),
            ),
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Builder(
                      //   builder: (context) {
                      //     return Container(
                      //       height: 6.5.h,
                      //       width: 13.w,
                      //       decoration: BoxDecoration(
                      //         borderRadius: BorderRadius.circular(8),
                      //         border: Border.all(color: Colors.grey, width: 1),
                      //         color: Colors.white,
                      //       ),
                      //       child: IconButton(
                      //         icon: Icon(Icons.menu, color: Colors.black),
                      //         onPressed: () => Scaffold.of(context).openDrawer(),
                      //       ),
                      //     );
                      //   },
                      // ),
                      // SizedBox(width: 3.w),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          onSubmitted: (val) {
                            if (val.trim().isNotEmpty) {
                              context.read<EmailCubit>().getEmailsBySearch(
                                query: val.trim(),
                              );
                              setState(() {
                                currentFilter = "all";
                                isSearching = true;
                              });
                            }
                          },
                          decoration: InputDecoration(
                            hintText: "Search",
                            prefixIcon: Icon(Icons.search),
                            suffixIcon:
                                !isSearching
                                    ? null
                                    : IconButton(
                                      icon: Icon(Icons.clear),
                                      onPressed: () {
                                        searchController.clear();
                                        context.read<EmailCubit>().getEmails(
                                          loadAgain: true,
                                        );
                                        setState(() {
                                          isSearching = false;
                                          currentFilter = "all";
                                        });
                                      },
                                    ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: Text("All"),
                          selected: currentFilter == "all",
                          onSelected: (val) {
                            setState(() => currentFilter = "all");
                            context.read<EmailCubit>().filterEmails(
                              "all",
                              emailsAll,
                            );
                          },
                        ),
                        SizedBox(width: 10),
                        FilterChip(
                          label: Text("Urgent"),
                          selected: currentFilter == "urgent",
                          onSelected: (val) {
                            setState(() => currentFilter = "urgent");
                            context.read<EmailCubit>().filterEmails(
                              "urgent",
                              emailsAll,
                            );
                          },
                        ),
                        SizedBox(width: 10),
                        FilterChip(
                          label: Text("Informational"),
                          selected: currentFilter == "informational",
                          onSelected: (val) {
                            setState(() => currentFilter = "informational");
                            context.read<EmailCubit>().filterEmails(
                              "informational",
                              emailsAll,
                            );
                          },
                        ),
                        SizedBox(width: 10),
                        FilterChip(
                          label: Text("Normal"),
                          selected: currentFilter == "normal",
                          onSelected: (val) {
                            setState(() => currentFilter = "normal");
                            context.read<EmailCubit>().filterEmails(
                              "normal",
                              emailsAll,
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20),
                  if (state is EmailLoading && emails.isEmpty)
                    Center(child: SpinKitFadingCircle(color: Colors.blue)),

                  if (state is EmailError)
                    Center(
                      child: Column(
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 34),
                          SizedBox(height: 10),
                          Text(
                            state.message,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (state is! EmailError && emails.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: emails.length,
                        itemBuilder: (context, index) {
                          final email = emails[index];

                          return Column(
                            children: [
                              ListTile(
                                leading: CircleAvatar(
                                  backgroundColor:
                                      Colors.primaries[(email
                                                  .lastSender
                                                  ?.hashCode ??
                                              0) %
                                          Colors.primaries.length],
                                  child: Text(
                                    email.lastSender?.isNotEmpty == true
                                        ? email.lastSender![0]
                                        : "U",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  formatSender(email.lastSender ?? "Unknown"),
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  email.subject ?? "No Subject",
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                trailing: Text(
                                  email.lastEmailAt != null
                                      ? formatEmailDate(
                                        email.lastEmailAt!.toIso8601String(),
                                      )
                                      : "",
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
                                      message: "Failed to load email details.",
                                      backgroundColor: Colors.red,
                                    );
                                  }
                                },
                              ),
                              Divider(),
                            ],
                          );
                        },
                      ),
                    ),

                  if (state is EmailLoading && emails.isNotEmpty) ...[
                    SizedBox(height: 20),
                    Center(child: SpinKitFadingCircle(color: Colors.blue)),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
