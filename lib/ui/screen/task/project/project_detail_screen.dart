// ignore_for_file: use_build_context_synchronously

import 'package:ai_asistant/data/models/projects/project_model.dart';
import 'package:ai_asistant/data/models/projects/section_model.dart';
import 'package:ai_asistant/data/models/projects/task_model.dart';
import 'package:ai_asistant/ui/screen/task/task_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:responsive_sizer/responsive_sizer.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../../../../Controller/auth_controller.dart';
import 'create_edit_project_screen.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;
  const ProjectDetailScreen({super.key, required this.project});
  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  Color getColorFromName(String colorName) {
    final colors = {
      'charcoal': Colors.grey.shade800,
      'red': Colors.redAccent,
      'blue': Colors.blueAccent,
      'green': Colors.greenAccent,
      'purple': Colors.purpleAccent,
      'orange': Colors.orangeAccent,
      'teal': Colors.tealAccent,
      'yellow': Colors.yellow,
      'pink': Colors.pinkAccent,
      'amber': Colors.amber,
      'cyan': Colors.cyan,
    };
    return colors[colorName.toLowerCase()] ?? Colors.blueAccent;
  }

  final AuthController controller = Get.find<AuthController>();
  List<TaskModel> tasks = [];
  bool isLoadingSections = true;
  bool isSectionOperationInProgress = false;
  List<SectionModel> sections = [];
  String? selectedSectionId;
  final TextEditingController _sectionNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchSections();
    sections = controller.sections;
  }

  Future<void> _fetchSections() async {
    setState(() {
      isLoadingSections = true;
    });
    sections = await controller.loadProjectSectionsid(widget.project.id) ?? [];
    tasks =
        controller.task
            .where((t) => t.project_id == widget.project.id)
            .toList();
    setState(() {
      isLoadingSections = false;
    });
  }

  Future<void> _refreshTasks() async {
    await controller.fetchTask();
    await _fetchSections();
  }

  void _showSectionDialog({SectionModel? section}) async {
    _sectionNameController.text = section?.name ?? '';
    await showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                child: Container(
                  padding: EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        section == null ? 'New Section' : 'Edit Section',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        controller: _sectionNameController,
                        decoration: InputDecoration(
                          labelText: 'Section Name',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: getColorFromName(widget.project.color),
                            ),
                          ),
                          labelStyle: TextStyle(color: Colors.grey.shade600),
                        ),
                        style: TextStyle(color: Colors.black),
                      ),
                      SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed:
                                isSectionOperationInProgress
                                    ? null
                                    : () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.grey.shade600,
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            child: Text('Cancel'),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed:
                                isSectionOperationInProgress
                                    ? null
                                    : () async {
                                      if (_sectionNameController
                                          .text
                                          .isNotEmpty) {
                                        setState(() {
                                          isSectionOperationInProgress = true;
                                        });
                                        try {
                                          if (section == null) {
                                            // Add new section
                                            await controller.createSection(
                                              SectionModel(
                                                name:
                                                    _sectionNameController.text
                                                        .trim(),
                                                project_id: widget.project.id,
                                                id: 0,
                                              ),
                                            );
                                            Navigator.pop(context);
                                            Future.microtask(() {
                                              setState(() {});
                                            });
                                          } else {
                                            await controller.updateSection(
                                              section.copyWith(
                                                name:
                                                    _sectionNameController.text
                                                        .trim(),
                                              ),
                                            );
                                            Navigator.pop(context);
                                            Future.microtask(() {
                                              setState(() {});
                                            });
                                          }
                                        } finally {
                                          setState(() {
                                            isSectionOperationInProgress =
                                                false;
                                          });
                                        }
                                      }
                                    },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: getColorFromName(
                                widget.project.color,
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child:
                                isSectionOperationInProgress
                                    ? SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                    : Text('Save'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
    setState(() {});
  }

  void _showSectionOptions(SectionModel section) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => Container(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Icon(Icons.edit, color: Colors.blue),
                  title: Text('Edit', style: TextStyle(color: Colors.blue)),
                  onTap: () {
                    Navigator.pop(context);
                    _showSectionDialog(section: section);
                  },
                ),
                Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red),
                  title: Text('Delete', style: TextStyle(color: Colors.red)),
                  onTap: () async {
                    Navigator.pop(context);
                    final shouldDelete = await showDialog(
                      context: context,
                      builder:
                          (context) => AlertDialog(
                            title: Text("Confirm Delete"),
                            content: Text(
                              "Are you sure you want to delete this section?",
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text("Cancel"),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(
                                  "Delete",
                                  style: TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                    );
                    if (shouldDelete == true) {
                      setState(() {
                        isSectionOperationInProgress = true;
                      });
                      try {
                        await controller.deleteSection(section);
                      } finally {
                        setState(() {
                          isSectionOperationInProgress = false;
                        });
                      }
                    }
                  },
                ),
              ],
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = getColorFromName(widget.project.color);
    final filteredTasks =
        selectedSectionId == null
            ? tasks
            : tasks
                .where(
                  (task) => task.section_id.toString() == selectedSectionId,
                )
                .toList();

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          widget.project.name,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.sp),
        ),
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 4,
        shadowColor: color.withValues(alpha: 0.5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshTasks,
        color: Colors.blue,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(16),
          children: [
            Hero(
              tag: 'project-${widget.project.id}',
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                shadowColor: color.withValues(alpha: 0.3),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.white, color.withValues(alpha: 0.05)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 500),
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.rocket_launch_rounded,
                                color: color,
                                size: 6.w,
                              ),
                            ),
                            SizedBox(width: 4.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.project.name,
                                    style: TextStyle(
                                      fontSize: 20.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey.shade800,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                    "Project ID: #${widget.project.id}",
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 3.h),
                        if (widget.project.isShared == true ||
                            widget.project.isInboxProject == true ||
                            widget.project.isTeamInbox == true)
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (widget.project.isShared == true)
                                Chip(
                                  label: const Text('Shared'),
                                  backgroundColor: Colors.tealAccent.withValues(
                                    alpha: 0.2,
                                  ),
                                  labelStyle: TextStyle(
                                    color: Colors.teal.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  avatar: Icon(
                                    Icons.share,
                                    size: 16,
                                    color: Colors.teal.shade800,
                                  ),
                                ),
                              if (widget.project.isInboxProject == true)
                                Chip(
                                  label: const Text('Inbox'),
                                  backgroundColor: Colors.indigoAccent
                                      .withValues(alpha: 0.2),
                                  labelStyle: TextStyle(
                                    color: Colors.indigo.shade800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  avatar: Icon(
                                    Icons.inbox,
                                    size: 16,
                                    color: Colors.indigo.shade800,
                                  ),
                                ),
                            ],
                          ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              color: color,
                              onPressed: () {
                                Get.to(
                                  () => EditProjectScreen(
                                    project: widget.project,
                                  ),
                                  transition: Transition.rightToLeftWithFade,
                                  duration: const Duration(milliseconds: 400),
                                );
                              },
                              icon: const Icon(Icons.edit),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete, color: color),
                              onPressed: () async {
                                await showDialog(
                                  context: context,
                                  builder:
                                      (context) => AlertDialog(
                                        title: const Text("Confirm Delete"),
                                        content: const Text(
                                          "Are you sure you want to delete this project?",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () => Navigator.pop(context),
                                            child: const Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              Get.back();
                                              WidgetsBinding.instance
                                                  .addPostFrameCallback((_) {
                                                    Navigator.pop(context);
                                                  });
                                              await controller.deleteProject(
                                                widget.project.id.toString(),
                                              );
                                            },
                                            child: const Text(
                                              "Delete",
                                              style: TextStyle(
                                                color: Colors.red,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                );
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 3.h),
                        if (widget.project.url != null)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "PROJECT LINK",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey.shade600,
                                  letterSpacing: 1,
                                ),
                              ),
                              SizedBox(height: 1.h),
                              InkWell(
                                onTap: () async {
                                  final url = widget.project.url ?? '';
                                  if (await canLaunchUrlString(url)) {
                                    await launchUrlString(url);
                                  } else {
                                    Get.snackbar(
                                      "Invalid URL",
                                      "Cannot open the project link",
                                    );
                                  }
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: EdgeInsets.all(2.w),
                                  decoration: BoxDecoration(
                                    color: Colors.blueAccent.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blueAccent.withValues(
                                        alpha: 0.3,
                                      ),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.link,
                                        color: Colors.blueAccent,
                                        size: 20,
                                      ),
                                      SizedBox(width: 3.w),
                                      Expanded(
                                        child: Text(
                                          widget.project.url ?? "",
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            color: Colors.blueAccent,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 3.h),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12.0, left: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "SECTIONS",
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16.sp,
                    ),
                  ),
                  IconButton(
                    onPressed:
                        isSectionOperationInProgress
                            ? null
                            : () => _showSectionDialog(),
                    icon: Icon(Icons.add),
                  ),
                ],
              ),
            ),
            const Divider(),
            if (isLoadingSections)
              const Center(child: CircularProgressIndicator())
            else
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: FilterChip(
                        label: const Text('All'),
                        selected: selectedSectionId == null,
                        onSelected: (selected) {
                          setState(() {
                            selectedSectionId = null;
                          });
                        },
                      ),
                    ),
                    ...sections.map(
                      (section) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0),
                        child: GestureDetector(
                          onLongPress: () => _showSectionOptions(section),
                          child: FilterChip(
                            label: Text(section.name),
                            selected:
                                selectedSectionId == section.id.toString(),
                            onSelected: (selected) {
                              setState(() {
                                selectedSectionId =
                                    selected ? section.id.toString() : null;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(height: 2.h),
            Padding(
              padding: const EdgeInsets.only(top: 12.0, left: 6),
              child: Text(
                "TASKS",
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16.sp),
              ),
            ),
            const Divider(),
            if (isSectionOperationInProgress)
              const Center(child: CircularProgressIndicator())
            else if (filteredTasks.isEmpty)
              Align(
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 48.sp),
                    Icon(MdiIcons.listBox, color: Colors.grey, size: 44),
                    Text(
                      selectedSectionId == null
                          ? "This project contains no tasks."
                          : "This section contains no tasks.",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...filteredTasks.map((task) {
                return ListTile(
                  title: Text(
                    task.content,
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 16.sp,
                    ),
                  ),
                  leading: const Icon(Icons.task_alt, size: 18),
                  onTap: () => Get.to(TaskDetailScreen(task: task)),
                );
              }),
          ],
        ),
      ),
    );
  }
}
