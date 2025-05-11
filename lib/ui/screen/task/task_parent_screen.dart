import 'package:ai_asistant/ui/screen/task/todotask_Screen.dart';
import 'package:ai_asistant/ui/screen/task/trash_screen.dart';
import 'package:ai_asistant/ui/widget/task_navbar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Controller/bar_controller.dart';
import 'project_screen.dart';

class TaskScreen extends StatelessWidget {
  final int toSpecialIndex;
  final TaskController controller = Get.find<TaskController>();
  final String filter;

  final List<Widget> screens = [
    Center(child: Text('Today’s Tasks')),
    Center(child: Text('Upcoming Tasks')),
    Center(child: Text('Trash')),
  ];

  TaskScreen({super.key, this.filter = "today", this.toSpecialIndex = 0}) {
    controller.selectedIndex = RxInt(toSpecialIndex);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        body: IndexedStack(
          index: controller.selectedIndex.value,
          children: [
            TodotaskScreen(filter: filter),
            ProjectScreen(),
            TasksTrashScreen(),
          ],
        ),

        // bottomNavigationBar: BottomNavigationBar(
        //   selectedItemColor: Colors.white,
        //   backgroundColor: Colors.blue,
        //   elevation: 8,
        //   currentIndex: controller.selectedIndex.value,
        //   onTap: (index) {
        //     controller.selectedIndex.value = index;
        //   },
        //   items: [
        //     BottomNavigationBarItem(
        //       icon: Icon(Icons.task_alt_outlined),
        //       label: "Tasks",
        //     ),
        //     BottomNavigationBarItem(
        //       icon: Icon(MdiIcons.briefcaseAccountOutline),
        //       label: "Projects",
        //     ),
        //     BottomNavigationBarItem(
        //       icon: Icon(Icons.delete_outline),
        //       label: "Trash",
        //     ),
        //   ],
        // ),
        // bottomNavigationBar: BottomAppBar(
        //   child: Container(
        //     color: Colors.blue,
        //     child: Row(
        //       children: [
        //         Container(
        //           decoration: BoxDecoration(
        //             color: Colors.white,

        //             shape: BoxShape.circle,
        //           ),
        //         ),
        //       ],
        //     ),
        //   ),
        // ),
        bottomNavigationBar: TaskNavbar(controller: controller),
      ),
    );
  }
}
