import 'package:ai_asistant/data/models/projects/project_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../../../Controller/auth_Controller.dart';
import '../../widget/appbar.dart';
import 'lable_screen.dart';
import 'project/create_edit_ProjectScreen.dart';
import 'project/projectDetail_Screen.dart';

class ProjectScreen extends StatefulWidget {
  const ProjectScreen({super.key});

  @override
  State<ProjectScreen> createState() => _ProjectScreenState();
}

class _ProjectScreenState extends State<ProjectScreen> {
  final AuthController _controller = Get.find<AuthController>();
  final double _cardElevation = 6.0;
  final double _cardBorderRadius = 16.0;
  String _currentFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProjects(initialLoad: true);
  }

  Future<void> _loadProjects({required bool initialLoad}) async {
    await _controller.fetchProject(isInitialFetch: initialLoad);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: "AI Assistant",
        onNotificationPressed: _handleNotificationPress,
        onProfilePressed: _handleProfilePress,
      ),
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.blue,
        heroTag: "project_screen_fab_tag",
        elevation: 6,
        shape: StarBorder.polygon(sides: 8),

        onPressed: _handleAddProject,
        child: Icon(Icons.add, color: Colors.white, size: 24),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickAccessSection(context),
          _buildSearchAndFilterSection(colorScheme),
          _buildProjectListSection(textTheme, colorScheme),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  label: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('Inbox'),
                  ),
                  icon: Icon(Icons.inbox, color: Colors.blue),
                  onPressed:
                      _controller.projects.isEmpty ? null : _handleInboxPress,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _handleLabelsPress,
                  label: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("Labels"),
                  ),
                  icon: Icon(Icons.label, color: Colors.blue),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          Text(
            "MY PROJECTS",
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.8),
              letterSpacing: 0.5,
            ),
          ),
          SizedBox(height: 1.h),
          Divider(
            color: Theme.of(context).dividerColor,
            thickness: 1,
            height: 1,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterSection(ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search projects...',
              prefixIcon: Icon(
                Icons.search,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.3,
              ),
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
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'all', colorScheme),
                SizedBox(width: 2.w),
                _buildFilterChip('Favorites', 'favorites', colorScheme),
                SizedBox(width: 2.w),
              ],
            ),
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
      backgroundColor: colorScheme.surfaceContainerHighest.withValues(
        alpha: 0.3,
      ),
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

  Widget _buildProjectListSection(
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return Expanded(
      child: RefreshIndicator(
        onRefresh: () => _loadProjects(initialLoad: false),
        color: colorScheme.primary,
        child: Obx(() {
          if (_controller.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            );
          }

          final filteredProjects = _getFilteredProjects();

          if (filteredProjects.isEmpty) {
            return _buildEmptyState(colorScheme);
          }

          return ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: filteredProjects.length,
            separatorBuilder: (context, index) => SizedBox(height: 1.h),
            itemBuilder: (context, index) {
              return GestureDetector(
                onLongPress: () {
                  showModalBottomSheet(
                    context: context,
                    builder:
                        (_) => Container(
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
                              ListTile(
                                title: Text("Delete Project"),
                                leading: Icon(Icons.delete, color: Colors.red),
                                onTap: () async {
                                  await _controller.deleteProject(
                                    filteredProjects[index].id.toString(),
                                  );
                                },
                              ),
                              ListTile(
                                title: Text("Edit Project"),
                                leading: Icon(Icons.edit, color: Colors.blue),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => EditProjectScreen(
                                            project: filteredProjects[index],
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                  );
                },
                child: _buildProjectCard(filteredProjects[index], colorScheme),
              );
            },
          );
        }),
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.folder_open_rounded,
            size: 60,
            color: colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          SizedBox(height: 2.h),
          Text(
            _currentFilter == 'all'
                ? "No Projects Found"
                : "No ${_currentFilter.capitalizeFirst} Projects",
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            "Tap the + button to create a new project",
            style: TextStyle(
              fontSize: 14.sp,
              color: colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }

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

  Widget _buildProjectCard(Project project, ColorScheme colorScheme) {
    final bool isFavorite = project.isFavorite == true;
    final Color primaryColor = colorScheme.primary;

    return Card(
      elevation: _cardElevation,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_cardBorderRadius),
      ),
      shadowColor: primaryColor.withValues(alpha: 0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(_cardBorderRadius),
        onTap: () => _handleProjectTap(project),
        splashColor: primaryColor.withValues(alpha: 0.05),
        highlightColor: primaryColor.withValues(alpha: 0.03),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            children: [
              Row(
                children: [
                  _buildProjectIcon(
                    colorOptions[project.color] ?? primaryColor,
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.name,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w800,
                            color: colorScheme.onSurface,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 0.5.h),
                        Wrap(
                          spacing: 2.w,
                          runSpacing: 1.h,
                          children: [
                            if (isFavorite) _buildFavoriteTag(),
                            _buildProjectIdTag(
                              project.id.toString(),
                              colorScheme,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectIcon(Color primaryColor) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: primaryColor.withValues(alpha: 0.2),
      ),
      child: Icon(Icons.task_alt_rounded, color: primaryColor, size: 20.sp),
    );
  }

  Widget _buildFavoriteTag() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.amber.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14.sp, color: Colors.amber[700]),
          SizedBox(width: 1.w),
          Text(
            "Favorite",
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.amber[800],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectIdTag(String id, ColorScheme colorScheme) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        "ID: $id",
        style: TextStyle(
          fontSize: 12.sp,
          color: colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  List<Project> _getFilteredProjects() {
    var projects = List<Project>.from(_controller.projects);

    if (_searchController.text.isNotEmpty) {
      projects =
          projects.where((project) {
            final name = project.name.toString().toLowerCase();

            final searchTerm = _searchController.text.toLowerCase();
            return name.contains(searchTerm);
          }).toList();
    }

    // Apply category filter
    switch (_currentFilter) {
      case 'favorites':
        projects =
            projects.where((project) => project.isFavorite == true).toList();
        break;
      case 'shared':
        projects =
            projects.where((project) => project.isShared == true).toList();
        break;
      case 'team':
        projects =
            projects.where((project) => project.isTeamInbox == true).toList();
        break;
    }

    // Sort by ID (newest first)
    projects.sort((a, b) {
      try {
        int idA = a.id;
        int idB = b.id;
        return idB.compareTo(idA);
      } catch (e) {
        return 0;
      }
    });

    return projects;
  }

  void _handleProjectTap(Project project) {
    Get.to(
      () => ProjectDetailScreen(project: project),
      transition: Transition.rightToLeftWithFade,
    );
  }

  void _handleAddProject() {
    Get.to(
      () => EditProjectScreen(title: 'Add New Project'),
      transition: Transition.rightToLeftWithFade,
    );
  }

  void _handleInboxPress() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => ProjectDetailScreen(
              project: _controller.projects.firstWhere((t) => t.isInboxProject),
            ),
      ),
    );
  }

  void _handleLabelsPress() {
    Get.to(
      () => const LableScreen(),
      transition: Transition.rightToLeftWithFade,
      duration: const Duration(milliseconds: 300),
    );
  }

  void _handleNotificationPress() {
    print("Notification Clicked!");
  }

  void _handleProfilePress() {
    print("Profile Clicked!");
  }
}
