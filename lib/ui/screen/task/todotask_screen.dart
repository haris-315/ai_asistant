import 'package:ai_asistant/data/models/projects/label_model.dart';
import 'package:ai_asistant/data/models/projects/task_model.dart';
import 'package:ai_asistant/ui/screen/task/create_task_sheet.dart';
import 'package:ai_asistant/ui/screen/task/task_detail_screen.dart';
import 'package:ai_asistant/ui/widget/custom_linear_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../Controller/auth_Controller.dart';

class TodotaskScreen extends StatefulWidget {
  final String filter;
  const TodotaskScreen({super.key, this.filter = "today"});

  @override
  State<TodotaskScreen> createState() => _TodotaskScreenState();
}

class _TodotaskScreenState extends State<TodotaskScreen> {
  final AuthController _controller = Get.find<AuthController>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late String _currentFilter;
  String _currentSort = 'newest';
  bool isTrashing = false;
  bool isExpanded = false;
  @override
  void initState() {
    super.initState();
    

    _loadTasks();
  }

  Future<void> _loadTasks() async {
    await _controller.fetchTask();
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
    if (widget.filter != "") {
      _currentFilter = widget.filter;
    } else {
      _currentFilter = "today";
    }

    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        _buildSearchAndFilterSection(colorScheme),
        SizedBox(height: 2.3),
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

            final filteredTasks = _getFilteredTasks();

            if (filteredTasks.isEmpty) {
              return _buildEmptyState(colorScheme);
            }

            return RefreshIndicator(
              onRefresh: _loadTasks,
              color: colorScheme.primary,
              child: ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.all(2.h),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: filteredTasks.length,
                itemBuilder: (context, index) {
                  final task = filteredTasks[index];
                  return _buildTaskCard(task, colorScheme, textTheme);
                },
              ),
            );
          }),
        ),
      ],
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
        shadowColor: Colors.black.withValues(alpha: .5),
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
                    // Checkbox for completion status
                    Checkbox(
                      value: isCompleted,
                      onChanged: (value) {
                        _toggleTaskCompletion(task);
                      },
                      activeColor: Colors.green,
                      checkColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Priority Indicator
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
                                fontWeight: FontWeight.w800,
                                fontSize: 11,
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

  Widget _buildSearchAndFilterSection(ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Column(
        children: [
          // Search Bar
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
          if (isTrashing) CustomLinearIndicator(isDangrousAction: true),
          SizedBox(height: 2.h),
          // Filter and Sort Chips
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip("Today's", 'today', colorScheme),
                      SizedBox(width: 2.w),
                      _buildFilterChip('All', 'all', colorScheme),
                      SizedBox(width: 2.w),
                      _buildFilterChip('Completed', 'completed', colorScheme),
                      SizedBox(width: 2.w),
                      _buildFilterChip('High Priority', 'high', colorScheme),
                    ],
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.sort, color: colorScheme.primary),
                onPressed: _showSortOptions,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ColorScheme colorScheme) {
    final isSelected = _currentFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _currentFilter = selected ? value : 'all';
        });
      },
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primary.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        fontWeight: FontWeight.w600,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : Colors.transparent,
          width: 1.5,
        ),
      ),
      elevation: 0,
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
    );
  }



  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sort By',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 2.h),
              _buildSortOption('Newest First', 'newest'),
              _buildSortOption('Oldest First', 'oldest'),
              _buildSortOption('Priority (High to Low)', 'priority_high'),
              _buildSortOption('Priority (Low to High)', 'priority_low'),
              SizedBox(height: 2.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSortOption(String label, String value) {
    return ListTile(
      title: Text(label),
      trailing:
          _currentSort == value
              ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
              : null,
      onTap: () {
        setState(() {
          _currentSort = value;
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.task_alt_rounded,
            size: 60,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          SizedBox(height: 2.h),
          Text(
            _currentFilter == 'all'
                ? "No Tasks Found"
                : "No ${_currentFilter.capitalizeFirst} Tasks",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            "Tap the + button to add a new task",
            style: TextStyle(
              fontSize: 14.sp,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
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
              // Options
              _buildOptionItem(
                context,
                icon: Icons.edit,
                label: 'Edit Task',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _editTask(task);
                },
              ),
              _buildOptionItem(
                context,
                icon: Icons.label,
                label: task.label_id != null ? "Remove Label" : 'Label Task',
                color: Colors.purpleAccent,
                onTap:
                    task.label_id != null
                        ? () async {
                          await _controller.removeTaskLabel(
                            task.label_id,
                            task,
                          );
                        }
                        : () async {
                          Navigator.pop(context);
                          _showSelectLabel(task);
                        },
              ),
              _buildOptionItem(
                context,
                icon: Icons.auto_delete_rounded,
                label: 'Move task to trash',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  _confirmTrashTask(context, task);
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

  void _confirmTrashTask(BuildContext context, TaskModel task) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Trash Task'),
          content: const Text(
            'Are you sure you want to move this task to trash?',
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
                _trashTask(task);
              },
              child: const Text('Move', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  void _showSelectLabel(TaskModel task) {
    List<LabelModel> labels = _controller.labels;
    showModalBottomSheet(
      context: context,
      builder: (_) {
        return Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ListView(
            children:
                labels
                    .map(
                      (l) => ListTile(
                        title: Text(
                          l.name,
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        leading: Icon(Icons.label, color: Colors.blue),
                        onTap: () async {
                          await _controller.labelTask(l, task);
                        },
                      ),
                    )
                    .toList(),
          ),
        );
      },
    );
  }

  void _toggleTaskCompletion(TaskModel task) {
    _controller.updateTask(task.copyWith(is_completed: !task.is_completed));
  }

  void _editTask(TaskModel task) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => TaskCreateEditSheet(
            task: task,
            onSubmit: (task) => _controller.updateTask(task),
          ),
    );
  }

  void _trashTask(TaskModel task) async {
    setState(() {
      isTrashing = true;
    });
    final _ = await _controller.moveTaskToTrash(task);
    setState(() {
      isTrashing = false;
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

  List<TaskModel> _getFilteredTasks() {
    var tasks = List<TaskModel>.from(_controller.task);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (_searchController.text.isNotEmpty) {
      tasks =
          tasks.where((task) {
            final content = task.content.toString().toLowerCase();
            final description = task.description.toString().toLowerCase();
            final searchTerm = _searchController.text.toLowerCase();
            return content.contains(searchTerm) ||
                description.contains(searchTerm);
          }).toList();
    }

    // Apply status filter
    switch (_currentFilter) {
      case 'active':
        tasks = tasks.where((task) => task.is_completed != true).toList();
        break;
      case 'completed':
        tasks = tasks.where((task) => task.is_completed == true).toList();
        break;
      case 'high':
        tasks = tasks.where((task) => (task.priority ?? 0) == 3).toList();
        break;
      case 'today':
        tasks =
            tasks.where((task) {
              final taskDate = DateTime(
                task.createdAt.year,
                task.createdAt.month,
                task.createdAt.day,
              );
              return taskDate.isAtSameMomentAs(today);
            }).toList();
        break;
    }

    // Apply sorting
    switch (_currentSort) {
      case 'oldest':
        tasks.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'priority_high':
        tasks.sort((a, b) => (b.priority ?? 0).compareTo(a.priority ?? 0));
        break;
      case 'priority_low':
        tasks.sort((a, b) => (a.priority ?? 0).compareTo(b.priority ?? 0));
        break;
      default: // 'newest'
        tasks.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return tasks;
  }

  void _handleTaskTap(TaskModel task) {
    Get.to(
      () => TaskDetailScreen(task: task),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 300),
    );
  }
}
