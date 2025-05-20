// ignore_for_file: use_build_context_synchronously

import 'package:ai_asistant/Controller/auth_controller.dart';
import 'package:ai_asistant/core/services/settings_service.dart';
import 'package:ai_asistant/core/shared/constants.dart';
import 'package:ai_asistant/core/shared/functions/is_today.dart';
import 'package:ai_asistant/data/models/threadmodel.dart';
import 'package:ai_asistant/state_mgmt/email/cubit/email_cubit.dart';
import 'package:ai_asistant/ui/screen/assistant/assistant_control_page.dart';
import 'package:ai_asistant/ui/screen/home/chat_screen.dart';
import 'package:ai_asistant/ui/screen/home/dashboard.dart';
import 'package:ai_asistant/ui/screen/task/create_task_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  AuthController authController = Get.find<AuthController>();
  HomeController homeController = Get.find<HomeController>();
  bool isSomeThingLoading = false;

  void fetchTaskData() async {
    if (await SettingsService.getSetting(AppConstants.appStateKey) ==
        AppConstants.appStateInitialized) {
      return;
    }
    handleLoading();
    context.read<EmailCubit>().getEmails();
    await authController.fetchTask(initialLoad: true);
    await authController.fetchProject(isInitialFetch: true);
    handleLoading();
  }

  void handleLoading() {
    setState(() {
      isSomeThingLoading = !isSomeThingLoading;
    });
  }

  @override
  void initState() {
    super.initState();
    fetchTaskData();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Padding(
              //   padding: const EdgeInsets.symmetric(
              //     horizontal: 16,
              //     vertical: 10,
              //   ),
              //   child: TextField(
              //     decoration: InputDecoration(
              //       hintText: "Search",
              //       hintStyle: GoogleFonts.poppins(color: Colors.grey[600]),
              //       prefixIcon: const Icon(
              //         Icons.search,
              //         color: Color(0xFF1976D2),
              //       ),
              //       filled: true,
              //       fillColor: Colors.white.withValues(alpha: 0.9),
              //       border: OutlineInputBorder(
              //         borderRadius: BorderRadius.circular(30),
              //         borderSide: BorderSide.none,
              //       ),
              //     ),
              //   ),
              // ),
              Text(
                "Today's Overview",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 16),
              Obx(() {
                final tasks = authController.task;
                final projects = authController.projects;
                final todayTasksCount =
                    tasks.where((t) => isToday(t.createdAt)).length;
                final completedCount =
                    tasks.where((t) => t.is_completed == true).length;
                final progress =
                    tasks.isEmpty
                        ? 0
                        : ((completedCount / tasks.length) * 100).round();
                List<EmailThread> mails = context.watch<EmailCubit>().allEmails;
                final todayMails = mails.where(
                  (e) => isToday(e.lastEmailAt ?? DateTime(1999)),
                );
                return GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,

                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    OverviewCard(
                      title: "Emails",
                      subtitle:
                          "${todayMails.length} ${todayMails.length == 1 ? "Mail" : "Mails"} Today",
                      icon: Icons.email,
                      onTap:
                          isSomeThingLoading
                              ? null
                              : () {
                                homeController.goToSpecialPage<Null>(1, null);
                              },
                    ),
                    OverviewCard(
                      title: "Tasks",
                      subtitle: "$todayTasksCount Tasks Today",
                      icon: Icons.task,
                      onTap:
                          isSomeThingLoading
                              ? null
                              : () {
                                homeController.goToSpecialPage<String>(
                                  2,
                                  "today",
                                );
                              },
                    ),
                    OverviewCard(
                      title: "Progress",
                      subtitle: "$progress% Tasks Completed",
                      icon: Icons.bar_chart,
                      onTap:
                          isSomeThingLoading
                              ? null
                              : () {
                                homeController.goToSpecialPage<String>(
                                  2,
                                  "completed",
                                );
                              },
                    ),
                    OverviewCard(
                      title: "Projects",
                      subtitle: "${projects.length} Total Projects",
                      icon: Icons.domain,
                      onTap:
                          isSomeThingLoading
                              ? null
                              : () {
                                homeController.goToSpecialPage<Null>(3, null);
                              },
                    ),
                  ],
                );
              }),
              const SizedBox(height: 24),
              Text(
                "Quick Access",
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1976D2),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.white.withValues(alpha: 0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QuickAccessTile(
                      icon: Icons.assistant,
                      title: "Assistant",
                      onTap:
                          isSomeThingLoading
                              ? null
                              : () {
                                handleLoading();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (_) => const AssistantControlPage(),
                                  ),
                                );
                                handleLoading();
                              },
                    ),
                    // QuickAccessTile(
                    //   icon: MdiIcons.briefcase,
                    //   title: "Projects",
                    //   onTap:
                    //       isSomeThingLoading
                    //           ? null
                    //           : () =>
                    //               Get.to(() => TaskScreen(toSpecialIndex: 1)),
                    // ),
                    QuickAccessTile(
                      icon: Icons.chat,
                      title: "AI Chat",
                      onTap:
                          isSomeThingLoading
                              ? null
                              : () {
                                handleLoading();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const ChatScreen(),
                                  ),
                                );
                                handleLoading();
                              },
                    ),
                    QuickAccessTile(
                      icon: Icons.task_alt_outlined,
                      title: "Add Task",
                      onTap:
                          isSomeThingLoading
                              ? null
                              : () async {
                                await showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder:
                                      (context) => TaskCreateEditSheet(
                                        onSubmit: (task) async {
                                          await authController.createTask(task);
                                        },
                                      ),
                                );
                              },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isSomeThingLoading)
          LinearProgressIndicator(
            color: const Color(0xFF1976D2),
            backgroundColor: Colors.grey[200],
          ),
      ],
    );
  }
}

class OverviewCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onTap;

  const OverviewCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(minHeight: 130),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickAccessTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const QuickAccessTile({
    super.key,
    required this.icon,
    required this.title,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: const Color(0xFF1976D2).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF1976D2), size: 24),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w500),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Colors.grey,
      ),
      onTap: onTap,
    );
  }
}
