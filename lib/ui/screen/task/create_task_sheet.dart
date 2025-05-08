import 'package:ai_asistant/Controller/auth_Controller.dart';
import 'package:ai_asistant/data/models/projects/task_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class TaskCreateEditSheet extends StatefulWidget {
  final TaskModel? task;
  final Function(TaskModel)? onSubmit;

  const TaskCreateEditSheet({super.key, this.task, this.onSubmit});

  @override
  State<TaskCreateEditSheet> createState() => _TaskCreateEditSheetState();
}

class _TaskCreateEditSheetState extends State<TaskCreateEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final _authController = Get.find<AuthController>();

  final _contentController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _priority = 2;
  late int _projectId;
  int? _sectionId;
  bool _isCompleted = false;
  bool _showDetails = false;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _contentController.text = task?.content ?? '';
    _descriptionController.text = task?.description ?? '';
    _priority = task?.priority ?? 2;
    _projectId = task?.project_id ?? _authController.projects.first.id;
    _sectionId = task?.section_id;
    _isCompleted = task?.is_completed ?? false;
  }

  @override
  void dispose() {
    _contentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = [
      Colors.blue.shade400,
      Colors.purple.shade200,
      Colors.blue.shade500,
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder:
          (context, scrollController) => Container(
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Form(
              key: _formKey,
              child: ListView(
                controller: scrollController,
                children: [
                  // Handle with gradient
                  Center(
                    child: Container(
                      width: 60,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: colors),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),

                  // Title with gradient text
                  Row(
                    children: [
                      Expanded(
                        child: ShaderMask(
                          shaderCallback:
                              (bounds) => LinearGradient(
                                colors: colors,
                              ).createShader(bounds),
                          child: Text(
                            widget.task == null
                                ? 'Create New Task'
                                : 'Edit Task',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: colors),
                            shape: BoxShape.circle,
                          ),
                          padding: const EdgeInsets.all(8),
                          child: const Icon(Icons.check, color: Colors.white),
                        ),
                        onPressed: _submitForm,
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Focus(
                    onFocusChange: (hasFocus) {
                      if (hasFocus) {
                        setState(() => _showDetails = true);
                      }
                    },
                    child: TextFormField(
                      controller: _contentController,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'What needs to be done?',
                        hintStyle: TextStyle(
                          color: theme.hintColor.withValues(alpha: 0.7),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 12,
                        ),
                      ),
                      validator:
                          (value) =>
                              value == null || value.isEmpty
                                  ? 'Task name is required'
                                  : null,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Colorful action chips
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildPriorityChip(),
                      _buildProjectChip(),
                      _buildStatusChip(),
                      _buildDetailsChip(),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Animated details section
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState:
                        _showDetails
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                    firstChild: Container(),
                    secondChild: Column(
                      children: [
                        // Description field
                        TextFormField(
                          controller: _descriptionController,
                          decoration: InputDecoration(
                            labelText: 'Description',
                            labelStyle: TextStyle(
                              color: colors[1],
                              fontWeight: FontWeight.bold,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors[2]),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: colors[0],
                                width: 2,
                              ),
                            ),
                          ),
                          maxLines: 3,
                          style: theme.textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _buildPriorityChip() {
    final priorityData = {
      1: {'label': 'Low', 'color': Colors.greenAccent},
      2: {'label': 'Medium', 'color': Colors.orangeAccent},
      3: {'label': 'High', 'color': Colors.redAccent},
    };
    final current = priorityData[_priority]!;

    return ActionChip(
      label: Text(
        'Priority: ${current['label']}',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: (current['color'] as Color).withValues(alpha: 0.2),
      avatar: Icon(Icons.flag, color: current['color'] as Color),
      onPressed: _showPrioritySelector,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: (current['color'] as Color).withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Widget _buildProjectChip() {
    final project = _authController.projects.firstWhereOrNull(
      (p) => p.id == _projectId,
    );
    final color = Colors.purpleAccent;

    return ActionChip(
      label: Text(
        project != null ? project.name : 'Project',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.2),
      avatar: Icon(Icons.folder, color: color),
      onPressed: _showProjectPicker,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _buildStatusChip() {
    final color = _isCompleted ? Colors.tealAccent : Colors.blueAccent;
    return ActionChip(
      label: Text(
        _isCompleted ? 'Completed' : 'Pending',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.2),
      avatar: Icon(
        _isCompleted ? Icons.check_circle : Icons.pending_actions,
        color: color,
      ),
      onPressed: () => setState(() => _isCompleted = !_isCompleted),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _buildDetailsChip() {
    final color = Colors.pinkAccent;
    return ActionChip(
      label: Text(
        _showDetails ? 'Less' : 'More',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.2),
      avatar: Icon(
        _showDetails ? Icons.expand_less : Icons.expand_more,
        color: color,
      ),
      onPressed: () => setState(() => _showDetails = !_showDetails),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
    );
  }

  void _showPrioritySelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Priority',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildPriorityOption(1, 'Low', Colors.greenAccent),
                    _buildPriorityOption(2, 'Medium', Colors.orangeAccent),
                    _buildPriorityOption(3, 'High', Colors.redAccent),
                  ],
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
    );
  }

  Widget _buildPriorityOption(int value, String label, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() => _priority = value);
        Navigator.pop(context);
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color:
                  _priority == value
                      ? color.withValues(alpha: 0.2)
                      : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: _priority == value ? color : Colors.grey.shade300,
                width: 2,
              ),
            ),
            child: Icon(Icons.flag, color: color, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: _priority == value ? color : Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _showProjectPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Select Project',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    ..._authController.projects.map((project) {
                      return ListTile(
                        leading: Icon(
                          Icons.folder,
                          color: Colors.purple.shade400,
                        ),
                        title: Text(project.name),
                        onTap: () {
                          setState(() => _projectId = project.id);
                          Navigator.pop(context);
                        },
                        trailing:
                            _projectId == project.id
                                ? const Icon(Icons.check, color: Colors.purple)
                                : null,
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      final task = TaskModel(
        id: widget.task?.id,
        content: _contentController.text.trim(),
        description: _descriptionController.text.trim(),
        priority: _priority,
        project_id: _projectId,
        section_id: _sectionId,
        is_completed: _isCompleted,
        createdAt: widget.task?.createdAt ?? DateTime.now(),
      );

      widget.onSubmit?.call(task);
      Navigator.of(context).pop();
    }
  }
}
