import 'package:ai_asistant/Controller/auth_Controller.dart';
import 'package:ai_asistant/core/services/settings_service.dart';
import 'package:ai_asistant/core/shared/constants.dart';
import 'package:ai_asistant/core/shared/functions/is_today.dart';
import 'package:ai_asistant/ui/screen/home/chat_screen.dart';
import 'package:ai_asistant/ui/screen/home/emails/all_email_screen.dart';
import 'package:ai_asistant/ui/screen/soonToBeDeleted.dart';
import 'package:ai_asistant/ui/screen/task/create_task_sheet.dart';
import 'package:ai_asistant/ui/screen/task/task_parent_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  AuthController authController = Get.find<AuthController>();
  bool isSomeThingLoading = false;

  void fetchTaskData() async {
    if (await SettingsService.getSetting(AppConstants.appStateKey) ==
        AppConstants.appStateInitialized) {
      return;
    }
    handleLoading();
    await authController.fetchTask(initialLoad: true);
    await authController.fetchProject(isInitialFetch: true);
    await authController.fetchEmails(isInitialLoad: true);
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
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Overview",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Obx(() {
                  final tasks = authController.task;
                  final todayTasksCount =
                      tasks.where((t) => isToday(t.createdAt)).length;
                  final completedCount =
                      tasks.where((t) => t.is_completed == true).length;
                  final progress =
                      tasks.isEmpty
                          ? 0
                          : ((completedCount / tasks.length) * 100).round();
                  final todayMails = authController.emailMessages.where(
                    (e) => isToday(e.receivedAt),
                  );
                  return Wrap(
                    children: [
                      GestureDetector(
                        onTap:
                            isSomeThingLoading
                                ? null
                                : () {
                                  Get.to(() => AllEmailScreen());
                                },
                        child: OverviewCard(
                          title: "Emails",
                          subtitle: "${todayMails.length} Mails Today",
                          icon: Icons.email,
                        ),
                      ),
                      GestureDetector(
                        onTap:
                            isSomeThingLoading
                                ? null
                                : () {
                                  Get.to(() => TaskScreen());
                                },
                        child: OverviewCard(
                          title: "Tasks",
                          subtitle: "$todayTasksCount Tasks Due Today",
                          icon: Icons.task,
                        ),
                      ),
                      GestureDetector(
                        onTap:
                            isSomeThingLoading
                                ? null
                                : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) =>
                                              TaskScreen(filter: "completed"),
                                    ),
                                  );
                                },
                        child: OverviewCard(
                          title: "Progress",
                          subtitle: "$progress% Tasks Completed",
                          icon: Icons.bar_chart,
                        ),
                      ),
                    ],
                  );
                }),
                SizedBox(height: 20),
                Text(
                  "Quick Access",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.blue.withValues(alpha: 0.04),
                  ),
                  child: Column(
                    children: [

                      ListTile(
                        leading: Icon(Icons.assistant, color: Colors.blue),
                        title: Text("Assistant"),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap:
                        isSomeThingLoading
                            ? null
                            : () {
                          handleLoading();
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => Soontobedeleted(),
                            ),
                          );
                          handleLoading();
                        },
                      ),
                      ListTile(
                        leading: Icon(MdiIcons.briefcase, color: Colors.blue),
                        title: Text("Projects"),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap:
                            isSomeThingLoading
                                ? null
                                : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => TaskScreen(toSpecialIndex: 1),
                                    ),
                                  );
                                },
                      ),
                      ListTile(
                        leading: Icon(Icons.chat, color: Colors.blue),
                        title: Text("AI Chat"),
                        trailing: Icon(Icons.arrow_forward_ios),
                        onTap:
                            isSomeThingLoading
                                ? null
                                : () {
                                  handleLoading();
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(),
                                    ),
                                  );
                                  handleLoading();
                                },
                      ),

                      ListTile(
                        leading: Icon(
                          Icons.task_alt_outlined,
                          color: Colors.blue,
                        ),
                        title: Text("Add Task"),
                        trailing: Icon(Icons.add),
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
                                            await authController.createTask(
                                              task,
                                            );
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
        ),
        if (isSomeThingLoading)
          LinearProgressIndicator(
            color: Colors.blue,
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

  const OverviewCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.blue,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Icon container
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: Icon(icon, color: Colors.blue, size: 32),
            ),
            const SizedBox(width: 16),

            // Title & subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: textTheme.bodyLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),

            // Forward arrow icon
            const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
          ],
        ),
      ),
    );
  }
}
