import 'package:ai_asistant/data/models/projects/project_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../Controller/auth_controller.dart';
import '../../../widget/input_field.dart';

class EditProjectScreen extends StatefulWidget {
  final Project? project;
  final String? title;

  const EditProjectScreen({super.key, this.project, this.title});

  @override
  State<EditProjectScreen> createState() => _EditProjectScreenState();
}

class _EditProjectScreenState extends State<EditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthController controller = Get.find<AuthController>();

  late TextEditingController nameController;
  late TextEditingController orderController;

  late String selectedViewStyle;
  late String selectedColor;
  late bool isShared;
  late bool isFavorite;
  late bool isInboxProject;
  late bool isTeamInbox;
  int? id;

  final List<String> viewStyleOptions = ['List', 'Board', 'Calendar'];
  final Map<String, Color> colorOptions = {
    'charcoal': Colors.grey.shade800,
    'red': Colors.redAccent,
    'blue': Colors.blueAccent,
    'green': Colors.greenAccent,
    'purple': Colors.purpleAccent,
    'orange': Colors.orangeAccent,
    'teal': Colors.tealAccent,
    'yellow': Colors.yellowAccent,
    'pink': Colors.pinkAccent,
    'amber': Colors.amberAccent,
    'cyan': Colors.cyanAccent,
  };

  @override
  void initState() {
    super.initState();
    final project = widget.project;

    nameController = TextEditingController(text: project?.name ?? '');
    orderController = TextEditingController(
      text: project?.order.toString() ?? '1',
    );
    id = project?.id;
    selectedViewStyle = project?.viewStyle ?? 'list';
    selectedColor = project?.color ?? 'charcoal';
    isShared = project?.isShared ?? false;
    isFavorite = project?.isFavorite ?? false;
    isInboxProject = project?.isInboxProject ?? false;
    isTeamInbox = project?.isTeamInbox ?? false;
  }

  @override
  void dispose() {
    nameController.dispose();
    orderController.dispose();
    super.dispose();
  }

  void saveProject() async {
    if (_formKey.currentState?.validate() ?? false) {
      final order = int.tryParse(orderController.text.trim()) ?? 1;

      final updatedProject = Project(
        name: nameController.text.trim(),
        color: selectedColor,
        order: order,
        isShared: isShared,
        isFavorite: isFavorite,
        isInboxProject: isInboxProject,
        isTeamInbox: isTeamInbox,
        viewStyle: selectedViewStyle.toLowerCase(),
        id: id ?? 0,
        url: null,
      );

      try {
        if (widget.title == null) {
          if (id != null) {
            final isSuccess = await controller.editProject(updatedProject);
            if (isSuccess == true) {
              final res = await controller.fetchProject(isInitialFetch: true);
              if (res == true) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.pop(context);
                });
              }
            }
          } else {}
        } else {
          final isSuccess = await controller.addNewProject(updatedProject);
          if (isSuccess == true) {
            final res = await controller.fetchProject(isInitialFetch: true);
            if (res == true) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pop(context);
              });
            }
          }
        }
      } catch (_) {}
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.title ?? 'Edit Project',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 20),
        ),
        backgroundColor: isDark ? Colors.grey.shade900 : Colors.white,
        foregroundColor: theme.primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: saveProject,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project Name
              Text(
                'Project Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              CustomFormTextField(
                label: 'Project Name',
                controller: nameController,
              ),
              const SizedBox(height: 24),

              // View Style & Color
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Color',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.8,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: theme.colorScheme.outline.withValues(
                                alpha: 0.3,
                              ),
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: selectedColor,
                            items:
                                colorOptions.entries
                                    .map(
                                      (entry) => DropdownMenuItem(
                                        value: entry.key,
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 16,
                                              height: 16,
                                              decoration: BoxDecoration(
                                                color: entry.value,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Text(
                                              entry.key.capitalizeFirst ?? '',
                                            ),
                                          ],
                                        ),
                                      ),
                                    )
                                    .toList(),
                            onChanged:
                                (value) => setState(() {
                                  selectedColor = value!;
                                }),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                            icon: const Icon(Icons.arrow_drop_down_rounded),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Settings Section
              Text(
                'Project Settings',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // _buildSettingSwitch(
              //   context,
              //   icon: MdiIcons.shareVariant,
              //   title: 'Shared Project',
              //   value: isShared,
              //   onChanged: (val) => setState(() => isShared = val),
              // ),
              _buildSettingSwitch(
                context,
                icon: Icons.star_border_rounded,
                title: 'Favorite',
                value: isFavorite,
                onChanged: (val) => setState(() => isFavorite = val),
              ),
              // _buildSettingSwitch(
              //   context,
              //   icon: Icons.inbox_rounded,
              //   title: 'Inbox Project',
              //   value: isInboxProject,
              //   onChanged: (val) => setState(() => isInboxProject = val),
              // ),
              // _buildSettingSwitch(
              //   context,
              //   icon: MdiIcons.accountGroup,
              //   title: 'Team Inbox',
              //   value: isTeamInbox,
              //   onChanged: (val) => setState(() => isTeamInbox = val),
              // ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveProject,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: colorOptions[selectedColor] ?? Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(
                    widget.title ?? 'Save Changes',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingSwitch(
    BuildContext context, {
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: theme.primaryColor,
          ),
        ],
      ),
    );
  }
}
