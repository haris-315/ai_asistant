import 'package:ai_asistant/ui/screen/task/trash_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Controller/bar_controller.dart';

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
      () => IndexedStack(
        index: controller.selectedIndex.value,
        children: [TasksTrashScreen()],
      ),

      // bottomNavigationBar: CustomNavBar(),
    );
  }
}
