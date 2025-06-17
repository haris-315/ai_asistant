import 'package:ai_asistant/Controller/auth_controller.dart';
import 'package:ai_asistant/data/models/projects/task_model.dart';
import 'package:ai_asistant/ui/screen/task/create_task_sheet.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  AuthController authController = Get.find<AuthController>();
  late TaskModel task;

  @override
  void initState() {
    super.initState();
    task = widget.task;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;
    final createdAt = task.createdAt;
    final formattedDate = DateFormat('MMMM d, y • h:mm a').format(createdAt);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        centerTitle: false,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: colorScheme.primary.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.edit, color: Colors.blue),
            ),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder:
                    (context) => TaskCreateEditSheet(
                      task: task,
                      onSubmit: (updatedTask) async {
                        final res = await authController.updateTask(
                          updatedTask,
                        );
                        if (res != null) {
                          setState(() {
                            task = updatedTask;
                          });
                        }
                      },
                    ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AnimatedUnderline(
              child: Text(
                task.content,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 16),

            _PulseAnimation(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getPriorityColor(
                    task.priority ?? 0,
                    colorScheme,
                  ).withAlpha(50),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.flag,
                      color: _getPriorityColor(task.priority ?? 0, colorScheme),
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getPriorityText(task.priority ?? 0),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: _getPriorityColor(
                          task.priority ?? 0,
                          colorScheme,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            if (task.description != null && task.description!.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      'DESCRIPTION',
                      style: textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.2,
                        color: colorScheme.outline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(13),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      task.description ?? "",
                      style: textTheme.bodyLarge?.copyWith(height: 1.5),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
              ),

            // Meta info section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildDetailRow(
                    context: context,
                    icon: Icons.calendar_today_outlined,
                    label: 'Created at',
                    value: formattedDate,
                  ),
                  if (task.due_date != null) ...[
                    const Divider(height: 24, thickness: 0.5),
                    _buildDetailRow(
                      context: context,
                      icon: Icons.event,
                      label: 'Due Date',
                      value: DateFormat(
                        'MMMM d, y • h:mm a',
                      ).format(task.due_date!.toLocal()),
                    ),
                  ],
                  if (task.reminder_at != null) ...[
                    const Divider(height: 24, thickness: 0.5),
                    _buildDetailRow(
                      context: context,
                      icon: Icons.alarm,
                      label: 'Reminder',
                      value: DateFormat(
                        'MMMM d, y • h:mm a',
                      ).format(task.reminder_at!),
                    ),
                  ],
                  if (task.project_id != 0 &&
                      authController.projects.isNotEmpty) ...[
                    const Divider(height: 24, thickness: 0.5),
                    _buildDetailRow(
                      context: context,
                      icon: Icons.folder_outlined,
                      label: 'Project',
                      value: getProjectName(authController, task),
                    ),
                  ],
                  if (task.section_id != null) ...[
                    const Divider(height: 24, thickness: 0.5),
                    _buildDetailRow(
                      context: context,
                      icon: Icons.list_alt_outlined,
                      label: 'Section',
                      value: 'Section ${task.section_id}',
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),
            Center(
              child: _BounceAnimation(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color:
                        task.is_completed
                            ? colorScheme.primary.withAlpha(25)
                            : colorScheme.errorContainer.withAlpha(75),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color:
                          task.is_completed
                              ? colorScheme.primary.withAlpha(75)
                              : colorScheme.errorContainer.withAlpha(125),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        task.is_completed
                            ? Icons.check_circle
                            : Icons.pending_actions,
                        size: 20,
                        color:
                            task.is_completed
                                ? colorScheme.primary
                                : colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        task.is_completed ? 'Completed' : 'Pending',
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color:
                              task.is_completed
                                  ? colorScheme.primary
                                  : colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _ScaleAnimation(
        child: FloatingActionButton(
          shape: StarBorder.polygon(
            sides: 8,
            side: BorderSide(
              color: task.is_completed ? Colors.blue : Colors.white,
            ),
          ),
          onPressed: () async {
            final res = await authController.updateTask(
              task.copyWith(is_completed: !task.is_completed),
            );
            if (res != null) {
              setState(() {
                task = res;
              });
            }
          },
          backgroundColor: task.is_completed ? Colors.white : Colors.blue,
          elevation: 4,
          child: Icon(
            task.is_completed ? Icons.refresh : Icons.check,
            color:
                task.is_completed
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.outline),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.outline,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getPriorityColor(int priority, ColorScheme colorScheme) {
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

  String _getPriorityText(int priority) {
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
}

String getProjectName(AuthController authController, TaskModel task) {
  try {
    final project = authController.projects.firstWhere(
      (p) => p.id == task.project_id,
    );
    return project.name;
  } catch (e) {
    return 'Not loaded...';
  }
}

class _PulseAnimation extends StatefulWidget {
  final Widget child;

  const _PulseAnimation({required this.child});

  @override
  _PulseAnimationState createState() => _PulseAnimationState();
}

class _PulseAnimationState extends State<_PulseAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

class _ScaleAnimation extends StatefulWidget {
  final Widget child;

  const _ScaleAnimation({required this.child});

  @override
  _ScaleAnimationState createState() => _ScaleAnimationState();
}

class _ScaleAnimationState extends State<_ScaleAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

class _BounceAnimation extends StatefulWidget {
  final Widget child;

  const _BounceAnimation({required this.child});

  @override
  _BounceAnimationState createState() => _BounceAnimationState();
}

class _BounceAnimationState extends State<_BounceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true);
    _animation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.05),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.05, end: 1.0),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(scale: _animation, child: widget.child);
  }
}

class _AnimatedUnderline extends StatefulWidget {
  final Widget child;

  const _AnimatedUnderline({required this.child});

  @override
  _AnimatedUnderlineState createState() => _AnimatedUnderlineState();
}

class _AnimatedUnderlineState extends State<_AnimatedUnderline>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();
    _animation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.child,
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Container(
              height: 2,
              width: 100 * _animation.value,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.secondary,
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            );
          },
        ),
      ],
    );
  }
}
