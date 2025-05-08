import 'package:ai_asistant/data/models/projects/label_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../Controller/auth_Controller.dart';
import '../../../widget/icon_btn_customized.dart';
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

  late String selectedColor;
  late bool isFavorite;

  int? id;
  final List<String> viewStyleOptions = ['list', 'board', 'calendar'];
  final List<String> colorOptions = [
    'charcoal',
    'blue',
    'red',
    'green',
    'yellow',
  ];

  @override
  void initState() {
    super.initState();
    final label = widget.label;

    nameController = TextEditingController(text: label?.name ?? '');
    id = label?.id ?? 0;
    selectedColor = label?.color ?? 'charcoal';

    isFavorite = label?.is_favorite ?? false;
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  void saveProject() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        if (widget.label != null) {
          bool? isSuccess;

          try {
            isSuccess = await controller.editlabel(
              widget.label!.copyWith(
                name: nameController.text.trim(),
                color: selectedColor,
                is_favorite: isFavorite,
                id: widget.label?.id,
                user_id: widget.label?.user_id,
              ),
            );
            if (isSuccess == true) {
              int count = 0;
              Get.until((_) => count++ == 2);
              controller.fetchLabels();
            }
          } catch (e) {
            print('Error occurred: $e');
          }
        } else {
          print("newwwwww");
          final isSuccess = await controller.addNewLabel(
            LabelModel(
              name: nameController.text.trim(),
              color: selectedColor,
              is_favorite: isFavorite,
            ),
          );

          if (isSuccess == true) {
            int count = 0;
            Get.until((_) => count++ == 1);
          }
        }
      } catch (e) {
        print('Error updating project: $e');
      }
    } else {
      print('Form validation failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(widget.title ?? 'Edit Label'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 16),

              CustomFormTextField(
                label: 'Label Name',
                controller: nameController,
                // keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              SwitchListTile(
                value: isFavorite,
                onChanged: (val) => setState(() => isFavorite = val),
                title: const Text('Is Favorite'),
              ),

              const SizedBox(height: 24),

              CustomIconButton(
                title: (widget.title ?? 'Save Changes'),
                iconData: Icons.save,
                onPressed: saveProject,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
