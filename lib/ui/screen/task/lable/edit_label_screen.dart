import 'package:ai_asistant/data/models/projects/label_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../Controller/auth_controller.dart';
import '../../../widget/input_field.dart';

class EditLabelscreen extends StatefulWidget {
  final LabelModel? label;
  final String? title;

  const EditLabelscreen({super.key, this.label, this.title});

  @override
  State<EditLabelscreen> createState() => _EditLabelscreenState();
}

class _EditLabelscreenState extends State<EditLabelscreen> {
  final _formKey = GlobalKey<FormState>();
  final AuthController controller = Get.find<AuthController>();

  late TextEditingController nameController;

  late String selectedViewStyle;
  late String selectedColor;
  late bool isFavorite;
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
    final label = widget.label;

    nameController = TextEditingController(text: label?.name ?? '');

    id = label?.id;
    selectedColor = label?.color ?? 'charcoal';
    isFavorite = label?.is_favorite ?? false;
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void saveLabel() async {
    if (_formKey.currentState?.validate() ?? false) {
      final updatedLabel = LabelModel(
        name: nameController.text.trim(),
        color: selectedColor,
        id: id ?? 0,
        is_favorite: isFavorite,
      );

      if (id != null) {
        final isSuccess = await controller.editlabel(updatedLabel);
        if (isSuccess == true) {
          final res = await controller.fetchProject(isInitialFetch: true);
          if (res == true) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pop(context);
            });
          }
        }
      } else {
        final isSuccess = await controller.addNewLabel(updatedLabel);
        if (isSuccess == true) {
          final res = await controller.fetchProject(isInitialFetch: true);
          if (res == true) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              Navigator.pop(context);
            });
          }
        }
      }
    } else {
      if (kDebugMode) {
        print('Form validation failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          widget.title ?? 'Edit Label',
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
            onPressed: saveLabel,
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
              Text(
                'Label Details',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              CustomFormTextField(
                label: 'Label Name',
                controller: nameController,
              ),
              const SizedBox(height: 24),

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

              Text(
                'Label Settings',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),

              _buildSettingSwitch(
                context,
                icon: Icons.star_border_rounded,
                title: 'Favorite',
                value: isFavorite,
                onChanged: (val) => setState(() => isFavorite = val),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: saveLabel,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: theme.primaryColor,
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
