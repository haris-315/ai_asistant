import 'package:ai_asistant/data/models/projects/label_model.dart';
import 'package:ai_asistant/ui/screen/task/task_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../../Controller/auth_Controller.dart';
import '../../../widget/icon_btn_customized.dart';
import 'edit_LabelSCreen.dart';

class LabelDetailsscreen extends StatelessWidget {
  final LabelModel label;
  LabelDetailsscreen({super.key, required this.label});

  final AuthController controller = Get.find<AuthController>();

  Color getColorFromName(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'charcoal':
        return Colors.grey.shade800;
      case 'red':
        return Colors.red;
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = label.is_favorite == true;
    final color = getColorFromName(label.color);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: Text(
          label.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(4.w),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          shadowColor: color.withOpacity(0.2),
          child: Padding(
            padding: EdgeInsets.all(5.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: color.withOpacity(0.1),
                      radius: 28,
                      child: Icon(Icons.label, color: color, size: 28),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label.name,
                            style: TextStyle(
                              fontSize: 20.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: 0.5.h),
                          Row(
                            children: [
                              if (isFavorite)
                                Row(
                                  children: [
                                    Icon(
                                      Icons.star,
                                      size: 18,
                                      color: Colors.orange,
                                    ),
                                    SizedBox(width: 1.w),
                                    Text(
                                      "Favorite",
                                      style: TextStyle(
                                        fontSize: 15.sp,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                              if (isFavorite) SizedBox(width: 2.w),
                              Text(
                                "#ID ${label.id}",
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 4.h),

                // Edit Button
                CustomIconButton(
                  title: 'Edit Label',
                  iconData: Icons.edit,
                  onPressed: () {
                    Get.to(EditLabelscreen(label: label));
                  },
                ),

                SizedBox(height: 2.h),

                // Delete Button
                CustomIconButton(
                  title: 'Delete Label',
                  iconData: Icons.delete,
                  backgroundColor: Colors.red,
                  borderColor: Colors.red,
                  onPressed: () async {
                    final confirm = await Get.dialog<bool>(
                      AlertDialog(
                        title: const Text("Confirm Delete"),
                        content: const Text(
                          "Are you sure you want to delete this label?",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(result: false),
                            child: const Text("Cancel"),
                          ),
                          TextButton(
                            onPressed: () => Get.back(result: true),
                            child: const Text(
                              "Delete",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      bool? del = await controller.deleteLabel(label);
                      if (del == true) {
                        await controller.fetchLabels();
                        if (context.mounted) Navigator.pop(context);
                      }
                    }
                  },
                ),

                SizedBox(height: 3.h),

                // Tasks Section
                Text(
                  "Tasks with this Label",
                  style: TextStyle(
                    fontSize: 17.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 1.5.h),

                Obx(() {
                  final tasks =
                      controller.task
                          .where(
                            (tsk) =>
                                tsk.label_id != null &&
                                tsk.label_id == label.id,
                          )
                          .toList();

                  if (tasks.isEmpty) {
                    return Padding(
                      padding: EdgeInsets.only(top: 2.h),
                      child: Text(
                        "No tasks associated with this label.",
                        style: TextStyle(fontSize: 16.sp, color: Colors.grey),
                      ),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: tasks.length,
                    separatorBuilder: (_, __) => Divider(height: 2.5.h),
                    itemBuilder: (context, index) {
                      final tsk = tasks[index];
                      return ListTile(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        tileColor: Colors.white,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 4.w,
                          vertical: 1.h,
                        ),
                        title: Text(
                          tsk.content,
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios,
                          size: 18,
                          color: Colors.grey,
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskDetailScreen(task: tsk),
                            ),
                          );
                        },
                      );
                    },
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
