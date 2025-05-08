import 'package:ai_asistant/data/models/projects/task_model.dart';
import 'package:ai_asistant/ui/screen/task/task_detail_screen.dart';
import 'package:ai_asistant/ui/widget/custom_linear_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../Controller/auth_Controller.dart';
import '../../widget/appbar.dart';

class TasksTrashScreen extends StatefulWidget {
  const TasksTrashScreen({super.key});

  @override
  State<TasksTrashScreen> createState() => _TasksTrashScreenState();
}

class _TasksTrashScreenState extends State<TasksTrashScreen> {
  final AuthController _controller = Get.find<AuthController>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool isDeleting = false;
  bool isRestroing = false;
  @override
  void initState() {
    super.initState();
    _controller.fetchTrashedTask();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.1,
      ),
      appBar: CustomAppBar(
        title: "Trashed Tasks",
        onNotificationPressed: _handleNotificationPress,
        onProfilePressed: _handleProfilePress,
      ),

      body: Column(
        children: [
          _buildSearchSection(colorScheme),
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value) {
                return Center(
                  child: CircularProgressIndicator(
                    color: colorScheme.primary,
                    strokeWidth: 2,
                  ),
                );
              }
              if (_controller.trashedTasks.isEmpty) {
                return _buildEmptyState(colorScheme);
              }

              return RefreshIndicator(
                onRefresh: () async {
                  await _controller.fetchTrashedTask();
                },
                color: colorScheme.primary,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.all(2.h),
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _controller.trashedTasks.length,
                  itemBuilder: (context, index) {
                    final task = _controller.trashedTasks[index];
                    return _buildTaskCard(task, colorScheme, textTheme);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskCard(
    TaskModel task,
    ColorScheme colorScheme,
    TextTheme textTheme,
  ) {
    final DateTime createdAt = task.createdAt;
    final bool isCompleted = task.is_completed == true;
    final int priority = task.priority ?? 1;
    final Color priorityColor = _getPriorityColor(priority);

    return GestureDetector(
      onLongPress: () => _showTaskOptions(context, task),
      child: Card(
        elevation: 4,
        margin: EdgeInsets.only(bottom: 2.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleTaskTap(task),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4,
                      height: 40,
                      decoration: BoxDecoration(
                        color: priorityColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Task Title
                          Text(
                            task.content,
                            style: textTheme.titleLarge?.copyWith(
                              decoration:
                                  isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                              color:
                                  isCompleted
                                      ? colorScheme.onSurface.withValues(
                                        alpha: 0.5,
                                      )
                                      : colorScheme.onSurface,
                            ),
                          ),
                          SizedBox(height: 1.h),
                          // Task Description
                          if (task.description != null &&
                              task.description.toString().trim().isNotEmpty)
                            Text(
                              task.description ?? "",
                              style: textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                color:
                                    isCompleted
                                        ? colorScheme.onSurface.withValues(
                                          alpha: 0.5,
                                        )
                                        : colorScheme.onSurface.withValues(
                                          alpha: 0.7,
                                        ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Completion Status
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isCompleted
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isCompleted ? Colors.green : Colors.orange,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        isCompleted ? "Completed" : "Incomplete",
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: isCompleted ? Colors.green : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                // Task Metadata
                Wrap(
                  spacing: 2.w,
                  runSpacing: 1.h,
                  children: [
                    // Priority Tag
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: priorityColor.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.flag_rounded,
                            size: 14.sp,
                            color: priorityColor,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            _getPriorityLabel(priority),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: priorityColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Date Tag
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.blue.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14.sp,
                            color: Colors.blue,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            DateFormat('MMM dd').format(createdAt),
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // ID Tag
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 3.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.purple.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.purple.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fingerprint_rounded,
                            size: 14.sp,
                            color: Colors.purple,
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            "ID: ${task.id}",
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.purple,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchSection(ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search tasks...',
              prefixIcon: Icon(
                Icons.search,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(
                vertical: 1.h,
                horizontal: 4.w,
              ),
              suffixIcon:
                  _searchController.text.isNotEmpty
                      ? IconButton(
                        icon: Icon(
                          Icons.clear,
                          color: colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                      : null,
            ),
            onChanged: (value) => setState(() {}),
          ),
          SizedBox(height: 2.h),
          if (isDeleting) CustomLinearIndicator(isDangrousAction: true),
          if (isRestroing) CustomLinearIndicator(),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_delete,
            size: 60,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          SizedBox(height: 2.h),
          Text(
            "No Tasks In Trash",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 1.h),
        ],
      ),
    );
  }

  void _showTaskOptions(BuildContext context, TaskModel task) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.task, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.content,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              _buildOptionItem(
                context,
                icon: Icons.restore,
                label: 'Restore Task',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _restoreTask(task);
                },
              ),
              _buildOptionItem(
                context,
                icon: Icons.delete_forever,
                label: 'Delete from trash',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteTask(context, task);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }

  void _confirmDeleteTask(BuildContext context, TaskModel task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Trash Task'),
          content: const Text(
            'Are you sure you want to delete this task?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _deleteTask(task);
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _restoreTask(TaskModel task) async {
    setState(() {
      isRestroing = true;
    });
    final _ = await _controller.restoreTask(task);
    setState(() {
      isRestroing = false;
    });
  }

  void _deleteTask(TaskModel task) async {
    setState(() {
      isDeleting = true;
    });
    final _ = await _controller.deleteTask(task);
    setState(() {
      isDeleting = false;
    });
  }

  Color _getPriorityColor(int priority) {
    switch (priority) {
      case 1:
        return Colors.teal;
      case 2:
        return Colors.amber.shade700;
      case 3:
        return Colors.redAccent;
      default:
        return Colors.blueGrey;
    }
  }

  String _getPriorityLabel(int priority) {
    switch (priority) {
      case 1:
        return 'Low';
      case 2:
        return 'Medium';
      case 3:
        return 'High';
      default:
        return 'None';
    }
  }

  void _handleTaskTap(TaskModel task) {
    // Implement task tap logic
    Get.to(
      () => TaskDetailScreen(task: task),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _handleNotificationPress() {
    // Implement notification press logic
  }

  void _handleProfilePress() {
    // Implement profile press logic
  }
  // ... [Keep all your existing methods below unchanged] ...
}
