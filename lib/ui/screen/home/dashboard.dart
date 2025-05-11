import 'package:ai_asistant/core/services/settings_service.dart';
import 'package:ai_asistant/core/shared/constants.dart';
import 'package:ai_asistant/ui/screen/home/emails/newemail_screen.dart';
import 'package:ai_asistant/ui/screen/task/create_task_sheet.dart';
import 'package:ai_asistant/ui/screen/task/project_screen.dart';
import 'package:ai_asistant/ui/screen/task/todotask_screen.dart';
import 'package:ai_asistant/ui/screen/task/trash_screen.dart';
import 'package:ai_asistant/ui/widget/appbar.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:page_transition/page_transition.dart';

import '../../../Controller/auth_Controller.dart';
import '../../widget/drawer.dart';
import '../home/emails/all_email_screen.dart';
import 'navigationScreen/home_screen_content.dart';

class HomeController extends GetxController {
  var selectedIndex = 0.obs;
  dynamic currentParam;
  void goToSpecialPage<T>(int theIndex, T theParam) {
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

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  final HomeController controller = Get.put(HomeController());
  final AuthController authcontroller = AuthController();
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _animationController;
  bool isExpanded = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    fetch();
    if (authcontroller.projects.isEmpty) {
      authcontroller.fetchProject(isInitialFetch: true);
    }
  }

  fabs() => [
    null,
    FloatingActionButton.extended(
      heroTag: "bawoooo!",
      label: Text(
        "Compose",
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      backgroundColor: Colors.blue[600],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Icon(Icons.send, color: Colors.white),
      onPressed: () => Get.to(() => NewMessageScreen()),
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
              setState(() => isExpanded = false);
              _animationController.reverse();
              Navigator.push(
                context,
                PageTransition(
                  type: PageTransitionType.rightToLeft,
                  child: TasksTrashScreen(),
                ),
              );
            },
          ),
          SizedBox(height: 16),
          _buildSpeedDialButton(
            icon: Icons.add_task,
            label: "Quick Task",
            color: Colors.green,
            onTap: () {
              setState(() => isExpanded = false);
              _animationController.reverse();
              _handleAddTask();
            },
          ),
          SizedBox(height: 16),
        ],
        FloatingActionButton(
          backgroundColor: Colors.blue,
          elevation: 6,
          highlightElevation: 12,
          heroTag: "sdfksljkcslkfdlks",
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onPressed: () {
            setState(() => isExpanded = !isExpanded);
            isExpanded
                ? _animationController.forward()
                : _animationController.reverse();
          },
          child: AnimatedSwitcher(
            duration: Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return ScaleTransition(scale: animation, child: child);
            },
            child:
                isExpanded
                    ? Icon(
                      Icons.close,
                      color: Colors.white,
                      key: ValueKey('close'),
                    )
                    : Icon(
                      Icons.expand_less,
                      color: Colors.white,
                      key: ValueKey('add'),
                    ),
          ),
        ),
      ],
    ),
    FloatingActionButton(
      backgroundColor: Colors.blue,
      heroTag: "project_screen_fab_tadsfg",
      elevation: 6,
      shape: StarBorder.polygon(sides: 8),

      onPressed: _handleAddTask,
      child: Icon(Icons.add, color: Colors.white, size: 24),
    ),
  ];

  Widget _buildSpeedDialButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ScaleTransition(
      key: ValueKey('speed_dial_$label'), // Unique key
      scale: CurvedAnimation(
        parent: _animationController,
        curve: Interval(
          isExpanded ? 0.0 : 0.5,
          isExpanded ? 0.5 : 1.0,
          curve: Curves.easeOutBack,
        ),
      ),
      child: FadeTransition(
        key: ValueKey('speed_d32ial_$label'), // Unique key

        opacity: _animationController,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(28),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: Offset(0, 4),
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
                SizedBox(width: 8),
                Text(
                  label,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<dynamic> _handleAddTask() {
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

  void fetch() async {
    if (await SettingsService.getSetting(AppConstants.appStateKey) ==
        AppConstants.appStateInitialized) {
      return;
    }
    await authcontroller.syncMailboxbulk();
    SettingsService.storeSetting(
      AppConstants.appStateKey,
      AppConstants.appStateInitialized,
    );
  }

  Map<int, String> titles = {0: "Home", 1: "Mails", 2: "Tasks", 3: "Projects"};
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        appBar: CustomAppBar(
          title: titles[controller.selectedIndex.value] ?? "AI Assistant",
        ),
        key: scaffoldKey,
        floatingActionButton: fabs()[controller.selectedIndex.value],
        drawer: const SideMenu(),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white, Colors.white],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            child: IndexedStack(
              index: controller.selectedIndex.value,
              children: [
                HomeContent(),
                AllEmailScreen(),
                TodotaskScreen(filter: controller.currentParam ?? "today"),
                ProjectScreen(),
              ],
            ),
          ),
        ),
        bottomNavigationBar: AnimatedNotchBottomBar(
          kBottomRadius: 18,
          kIconSize: 22,
          notchBottomBarController: controller.notchBottomBarController,
          color: Colors.white,
          showLabel: true,
          notchColor: const Color(0xFF1976D2),
          bottomBarItems: [
            BottomBarItem(
              inActiveItem: const Icon(Icons.home_outlined, color: Colors.grey),
              activeItem: const Icon(Icons.home, color: Colors.white),
              itemLabelWidget: Text(
                'Home',
                style: GoogleFonts.poppins(
                  color:
                      controller.selectedIndex.value == 0
                          ? const Color(0xFF1976D2)
                          : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            BottomBarItem(
              inActiveItem: const Icon(
                Icons.email_outlined,
                color: Colors.grey,
              ),
              activeItem: const Icon(Icons.email, color: Colors.white),
              itemLabelWidget: Text(
                'Emails',
                style: GoogleFonts.poppins(
                  color:
                      controller.selectedIndex.value == 1
                          ? const Color(0xFF1976D2)
                          : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            BottomBarItem(
              inActiveItem: const Icon(Icons.task_outlined, color: Colors.grey),
              activeItem: const Icon(Icons.task, color: Colors.white),
              itemLabelWidget: Text(
                'Tasks',
                style: GoogleFonts.poppins(
                  color:
                      controller.selectedIndex.value == 2
                          ? const Color(0xFF1976D2)
                          : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            BottomBarItem(
              inActiveItem: Icon(MdiIcons.domain, color: Colors.grey),
              activeItem: const Icon(Icons.domain_rounded, color: Colors.white),
              itemLabelWidget: Text(
                'Projects',
                style: GoogleFonts.poppins(
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
