import 'package:ai_asistant/core/services/settings_service.dart';
import 'package:ai_asistant/core/shared/constants.dart';
import 'package:ai_asistant/data/models/projects/project_model.dart';
import 'package:ai_asistant/state_mgmt/email/cubit/email_cubit.dart';
import 'package:ai_asistant/ui/screen/home/emails/newemail_screen.dart';
import 'package:ai_asistant/ui/screen/task/create_task_sheet.dart';
import 'package:ai_asistant/ui/screen/task/project_screen.dart';
import 'package:ai_asistant/ui/screen/task/todotask_screen.dart';
import 'package:ai_asistant/ui/screen/task/trash_screen.dart';
import 'package:ai_asistant/ui/widget/appbar.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:page_transition/page_transition.dart';

import '../../../Controller/auth_controller.dart';
import '../../widget/drawer.dart';
import '../home/emails/all_email_screen.dart';
import 'navigationScreen/home_screen_content.dart';

class HomeController extends GetxController {
  var selectedIndex = 0.obs;
  dynamic currentParam;
  void goToSpecialPage<T>(int theIndex, T? theParam) {
    currentParam = theParam;
    selectedIndex.value = theIndex;
    notchBottomBarController.jumpTo(theIndex);
  }

  final notchBottomBarController = NotchBottomBarController(index: 0);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController controller = Get.put(HomeController());
  final AuthController authcontroller = Get.find<AuthController>();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  final PageController pageController = PageController();
  GlobalKey<HomeContentState> key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _fetchAsync();
  }

  @override
  void didChangeDependencies() {
    // TODO: implement didChangeDependencies
    super.didChangeDependencies();
        context.read<EmailCubit>().backLoadEmails(key);

  }

  void _fetchAsync() async {
    if (await SettingsService.getSetting(AppConstants.appStateKey) ==
        AppConstants.appStateInitialized) {
      return;
    }
    await authcontroller.syncMailboxbulk();
    if (authcontroller.projects.isEmpty) {
      await authcontroller.fetchProject(isInitialFetch: true);
    }
    if (authcontroller.projects.isNotEmpty &&
        authcontroller.projects.any(
          (p) => p.isInboxProject && p.name == "Inbox",
        )) {
    } else {
      authcontroller.addNewProject(
        Project(
          name: "Inbox",
          color: "blue",
          order: 0,
          isShared: false,
          isFavorite: false,
          isInboxProject: true,
          isTeamInbox: false,
          viewStyle: "grid",
          id: 0,
        ),
      );
    }
    await SettingsService.storeSetting(
      AppConstants.appStateKey,
      AppConstants.appStateInitialized,
    );
  }

  Future<void> _handleAddTask() {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => TaskCreateEditSheet(
            onSubmit: (task) => authcontroller.createTask(task),
          ),
    );
  }

  Widget _buildScreen() {
    switch (controller.selectedIndex.value) {
      case 0:
        return const HomeContent();
      case 1:
        return const AllEmailScreen();
      case 2:
        return TodotaskScreen(filter: controller.currentParam ?? "today");
      case 3:
        return const ProjectScreen();
      default:
        return HomeContent(key: key);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: Colors.white,
        key: scaffoldKey,
        appBar: CustomAppBar(
          title:
              {0: "Home", 1: "Mails", 2: "Tasks", 3: "Projects"}[controller
                  .selectedIndex
                  .value] ??
              "AI Assistant",
        ),
        floatingActionButton: SpeedDialFab(
          selectedIndex: controller.selectedIndex.value,
          onAddTask: _handleAddTask,
        ),
        drawer: const SideMenu(),
        body: SafeArea(child: _buildScreen()),

        bottomNavigationBar: AnimatedNotchBottomBar(
          kBottomRadius: 18,
          kIconSize: 22,
          notchBottomBarController: controller.notchBottomBarController,
          color: Colors.white,
          showLabel: true,
          notchColor: const Color(0xFF1976D2),
          bottomBarItems: const [
            BottomBarItem(
              inActiveItem: Icon(Icons.home_outlined, color: Colors.grey),
              activeItem: Icon(Icons.home, color: Colors.white),
              itemLabelWidget: Text(
                'Home',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            BottomBarItem(
              inActiveItem: Icon(Icons.email_outlined, color: Colors.grey),
              activeItem: Icon(Icons.email, color: Colors.white),
              itemLabelWidget: Text(
                'Emails',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            BottomBarItem(
              inActiveItem: Icon(Icons.task_outlined, color: Colors.grey),
              activeItem: Icon(Icons.task, color: Colors.white),
              itemLabelWidget: Text(
                'Tasks',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            BottomBarItem(
              inActiveItem: Icon(Icons.domain, color: Colors.grey),
              activeItem: Icon(Icons.domain_rounded, color: Colors.white),
              itemLabelWidget: Text(
                'Projects',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          onTap: (index) {
            controller.goToSpecialPage<Null>(index, null);
          },
        ),
      ),
    );
  }
}

class SpeedDialFab extends StatefulWidget {
  final int selectedIndex;
  final VoidCallback onAddTask;

  const SpeedDialFab({
    super.key,
    required this.selectedIndex,
    required this.onAddTask,
  });

  @override
  State<SpeedDialFab> createState() => _SpeedDialFabState();
}

class _SpeedDialFabState extends State<SpeedDialFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  fabs() => [
    null,
    FloatingActionButton.extended(
      heroTag: "compose_fab",
      label: const Text(
        "Compose",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: const Color(0xFF1976D2),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: const Icon(Icons.send, color: Colors.white),
      onPressed: () => Get.to(() => const NewMessageScreen()),
    ),
    Column(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (isExpanded) ...[
          _buildSpeedDialButton(
            icon: Icons.delete_outlined,
            label: "Trash",
            color: Colors.redAccent,
            onTap: () {
              if (mounted) if (mounted) setState(() => isExpanded = false);
              _animationController.reverse();
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: const TasksTrashScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          _buildSpeedDialButton(
            icon: Icons.add_task,
            label: "Quick Task",
            color: Colors.green,
            onTap: () {
              if (mounted) if (mounted) setState(() => isExpanded = false);
              _animationController.reverse();
              widget.onAddTask();
            },
          ),
          const SizedBox(height: 16),
        ],
        FloatingActionButton(
          backgroundColor: const Color(0xFF1976D2),
          elevation: 6,
          heroTag: "task_fab",
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onPressed: () {
            if (mounted) if (mounted) setState(() => isExpanded = !isExpanded);
            isExpanded
                ? _animationController.forward()
                : _animationController.reverse();
          },
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child:
                isExpanded
                    ? const Icon(
                      Icons.close,
                      color: Colors.white,
                      key: ValueKey('close'),
                    )
                    : const Icon(
                      Icons.add,
                      color: Colors.white,
                      key: ValueKey('add'),
                    ),
          ),
        ),
      ],
    ),
    FloatingActionButton(
      backgroundColor: const Color(0xFF1976D2),
      heroTag: "project_fab",
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: widget.onAddTask,
      child: const Icon(Icons.add, color: Colors.white, size: 24),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return fabs()[widget.selectedIndex] ?? const SizedBox.shrink();
  }

  Widget _buildSpeedDialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return FadeTransition(
      opacity: _animationController,
      child: ScaleTransition(
        scale: CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOut,
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



        // SafeArea(
        // child: AnimatedSwitcher(
        //   duration: Duration(milliseconds: 400),
        //   switchInCurve: Curves.easeInOut,
        //   switchOutCurve: Curves.easeInOut,
        //   transitionBuilder: (child, animation) {
        //     final rotateAnim = Tween(begin: 1.0, end: 0.0).animate(animation);
        //     final slideAnim = Tween<Offset>(
        //       begin: const Offset(1, 0),
        //       end: Offset.zero,
        //     ).animate(animation);

        //     return AnimatedBuilder(
        //       animation: animation,
        //       child: child,
        //       builder: (context, child) {
        //         return Transform(
        //           alignment: Alignment.center,
        //           transform:
        //               Matrix4.identity()
        //                 ..setEntry(3, 2, 0.001) // perspective
        //                 ..rotateY(rotateAnim.value * 0.5), // rotate
        //           child: SlideTransition(position: slideAnim, child: child),
        //         );
        //       },
        //     );
        //   },
        //   child: _buildScreen(),
        // ),
        // ),
