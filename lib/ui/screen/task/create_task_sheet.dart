// ignore_for_file: use_build_context_synchronously

import 'package:ai_asistant/Controller/auth_Controller.dart';
import 'package:ai_asistant/data/models/projects/section_model.dart';
import 'package:ai_asistant/data/models/projects/task_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
  bool areSectionsLoading = false;
  List<SectionModel> sections = [];
  final _contentController = TextEditingController();
  final _descriptionController = TextEditingController();

  int _priority = 2;
  late int _projectId;
  int? _sectionId;
  bool _isCompleted = false;
  bool _showDetails = false;
  DateTime? _dueDate;
  DateTime? _reminderAt;

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
    _dueDate = task?.due_date;
    _reminderAt = task?.reminder_at;
  }

  @override
  void dispose() {
    _contentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDueDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      // Show time picker immediately
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_dueDate ?? DateTime.now()),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _dueDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
          // Set default reminder 10 minutes before due date if not set or invalid
          if (_reminderAt == null ||
              (_dueDate != null && _reminderAt!.isAfter(_dueDate!))) {
            _reminderAt = _dueDate!.subtract(const Duration(minutes: 10));
          }
        });
      } else {
        // Show message if time picker is cancelled
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a time for the due date'),
          ),
        );
      }
    }
  }

  Future<void> _selectReminderDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _reminderAt ?? _dueDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: _dueDate ?? DateTime(2100),
    );

    if (pickedDate != null) {
      // Show time picker immediately
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_reminderAt ?? DateTime.now()),
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: false),
            child: child!,
          );
        },
      );

      if (pickedTime != null) {
        final reminderDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Ensure reminder is not after due date
        if (_dueDate == null || reminderDateTime.isBefore(_dueDate!)) {
          setState(() {
            _reminderAt = reminderDateTime;
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder must be before due date')),
          );
        }
      } else {
        // Show message if time picker is cancelled
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a time for the reminder'),
          ),
        );
      }
    }
  }

  void _clearDueDate() {
    setState(() {
      _dueDate = null;
      _reminderAt = null; // Clear reminder if due date is cleared
    });
  }

  void _clearReminder() {
    setState(() {
      _reminderAt = null;
    });
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Focus(
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
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 6,
                          ),
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? "What's the Task?"
                                    : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      _buildPriorityChip(),
                      _buildProjectChip(),
                      _buildSectionChip(),
                      _buildDueDateChip(),
                      _buildReminderChip(),
                      _buildDetailsChip(),
                    ],
                  ),
                  const SizedBox(height: 20),
                  AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    crossFadeState:
                        _showDetails
                            ? CrossFadeState.showSecond
                            : CrossFadeState.showFirst,
                    firstChild: Container(),
                    secondChild: Column(
                      children: [
                        SizedBox(height: 4),
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
                        if (areSectionsLoading)
                          Center(
                            child: CircularProgressIndicator(
                              color: Colors.blue,
                            ),
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

  Widget _buildSectionChip() {
    final color = Colors.cyanAccent;
    final section =
        _sectionId != null
            ? _authController.sections.firstWhereOrNull(
              (s) => s.id == _sectionId,
            )
            : null;

    return ActionChip(
      label:
          areSectionsLoading
              ? SizedBox(
                height: 14,
                width: 32,
                child: CircularProgressIndicator(color: color),
              )
              : Text(
                section != null ? section.name : 'Section',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                ),
              ),
      backgroundColor: color.withValues(alpha: 0.2),
      avatar: Icon(Icons.view_kanban, color: color),
      onPressed: () async {
        await loadSections();
        _showSectionPicker(sections);
      },
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withValues(alpha: 0.5)),
      ),
    );
  }

  Widget _buildDueDateChip() {
    final color = Colors.blueAccent;
    return GestureDetector(
      onLongPress: _clearDueDate,
      child: ActionChip(
        label: Text(
          _dueDate != null
              ? 'Due: ${DateFormat('MMM d, yyyy h:mm a').format(_dueDate!)}'
              : 'Set Due Date',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: color.withValues(alpha: 0.2),
        avatar: Icon(Icons.calendar_today, color: color),
        onPressed: () => _selectDueDate(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
        side:
            _dueDate != null
                ? null
                : BorderSide(color: color.withValues(alpha: 0.5)),
        // onLongPress: _dueDate != null ? _clearDueDate : null,
      ),
    );
  }

  Widget _buildReminderChip() {
    final color = Colors.amberAccent;
    return GestureDetector(
      onLongPress: _clearReminder,
      child: ActionChip(
        label: Text(
          _reminderAt != null
              ? 'Reminder: ${DateFormat('MMM d, yyyy h:mm a').format(_reminderAt!)}'
              : 'Set Reminder',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),
        ),
        backgroundColor: color.withValues(alpha: 0.2),
        avatar: Icon(Icons.alarm, color: color),
        onPressed: () => _selectReminderDate(context),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: color.withValues(alpha: 0.5)),
        ),
        side:
            _reminderAt != null
                ? null
                : BorderSide(color: color.withValues(alpha: 0.5)),
        // : _reminderAt != null ? _clearReminder : null,
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
                    _buildPriorityOption(1, 'Low', Colors.green),
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
                          setState(() {
                            _projectId = project.id;
                            _sectionId = null;
                          });
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

  Future<List<SectionModel>> loadSections() async {
    setState(() {
      areSectionsLoading = true;
    });
    sections = await _authController.loadProjectSectionsid(_projectId) ?? [];
    setState(() {
      areSectionsLoading = false;
    });
    return sections;
  }

  void _showSectionPicker(List<SectionModel> sections) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) =>
              areSectionsLoading
                  ? Center(child: CircularProgressIndicator(color: Colors.blue))
                  : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Select Section',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                      Flexible(
                        child: ListView(
                          shrinkWrap: true,
                          children: [
                            ListTile(
                              leading: Icon(
                                Icons.clear,
                                color: Colors.grey.shade400,
                              ),
                              title: Text('No Section'),
                              onTap: () {
                                setState(() => _sectionId = null);
                                Navigator.pop(context);
                              },
                              trailing:
                                  _sectionId == null
                                      ? const Icon(
                                        Icons.check,
                                        color: Colors.cyan,
                                      )
                                      : null,
                            ),
                            if (sections.isNotEmpty)
                              ...sections.map((section) {
                                return ListTile(
                                  leading: Icon(
                                    Icons.view_kanban,
                                    color: Colors.cyan.shade400,
                                  ),
                                  title: Text(section.name),
                                  onTap: () {
                                    setState(() => _sectionId = section.id);
                                    Navigator.pop(context);
                                  },
                                  trailing:
                                      _sectionId == section.id
                                          ? const Icon(
                                            Icons.check,
                                            color: Colors.cyan,
                                          )
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
        due_date: _dueDate,
        reminder_at: _reminderAt,
      );

      widget.onSubmit?.call(task);
      Navigator.of(context).pop();
    }
  }
}
