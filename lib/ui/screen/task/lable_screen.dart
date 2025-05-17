import 'package:ai_asistant/Controller/auth_controller.dart';
import 'package:ai_asistant/data/models/projects/label_model.dart';
import 'package:ai_asistant/ui/screen/task/lable/edit_LabelSCreen.dart';
import 'package:ai_asistant/ui/screen/task/lable/label_DetailsScreen.dart';
import 'package:ai_asistant/ui/widget/appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

class LableScreen extends StatefulWidget {
  const LableScreen({super.key});

  @override
  State<LableScreen> createState() => _LableScreenState();
}

class _LableScreenState extends State<LableScreen> {
  final AuthController controller = Get.find<AuthController>();
  bool isLoading = true;
  final TextEditingController _searchController = TextEditingController();
  String _currentFilter = 'all';

  @override
  void initState() {
    super.initState();
    fetch();
  }

  void fetch() async {
    await controller.fetchLabels();
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: CustomAppBar(
        title: "Labels",
      ),
      backgroundColor: colorScheme.surface,
      floatingActionButton: FloatingActionButton(
        backgroundColor: colorScheme.primary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Icon(Icons.add, color: colorScheme.onPrimary, size: 24),
        onPressed: () {
          Get.to(
            () => EditLabelscreen(title: 'Create New Label'),
            transition: Transition.rightToLeftWithFade,
          );
        },
      ),
      body: Column(
        children: [
          // Header Section
          Padding(
            padding: EdgeInsets.fromLTRB(5.w, 2.h, 5.w, 1.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "My Labels",
                  style: textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 1.h),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search labels...',
                    prefixIcon: Icon(
                      Icons.search,
                      color: colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.5,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 1.5.h,
                      horizontal: 4.w,
                    ),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                SizedBox(height: 2.h),
                _buildFilterChips(colorScheme),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child:
                isLoading
                    ? Center(
                      child: SpinKitFadingCircle(
                        color: colorScheme.primary,
                        size: 30.0,
                      ),
                    )
                    : RefreshIndicator(
                      onRefresh: () async => fetch(),
                      color: colorScheme.primary,
                      child: _buildLabelList(colorScheme),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(ColorScheme colorScheme) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildFilterChip('All', 'all', colorScheme),
          SizedBox(width: 3.w),
          _buildFilterChip('Favorites', 'favorites', colorScheme),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value, ColorScheme colorScheme) {
    final isSelected = _currentFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected:
          (selected) =>
              setState(() => _currentFilter = selected ? value : 'all'),
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

  Widget _buildLabelList(ColorScheme colorScheme) {
    final filteredLabels = _getFilteredLabels();

    if (filteredLabels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.label_off_outlined,
              size: 60,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            SizedBox(height: 2.h),
            Text(
              "No labels found",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              "Create your first label",
              style: TextStyle(
                fontSize: 14.sp,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.fromLTRB(5.w, 0, 5.w, 2.h),
      itemCount: filteredLabels.length,
      separatorBuilder: (context, index) => SizedBox(height: 1.5.h),
      itemBuilder: (context, index) {
        final LabelModel label = filteredLabels[index];
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
                          title: Text("Delete Label"),
                          leading: Icon(Icons.delete, color: Colors.red),
                          onTap: () async {
                            Navigator.pop(context);
                            await controller.deleteLabel(label);
                            setState(() {});
                          },
                        ),
                        ListTile(
                          title: Text("Edit Label"),
                          leading: Icon(Icons.edit, color: Colors.blue),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditLabelscreen(label: label),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
            );
          },
          child: _buildLabelCard(label, colorScheme),
        );
      },
    );
  }

  Widget _buildLabelCard(LabelModel label, ColorScheme colorScheme) {
    final isFavorite = label.is_favorite == true;
    final primaryColor = colorScheme.primary;

    return Material(
      borderRadius: BorderRadius.circular(16),
      elevation: 2,
      color: colorScheme.surface,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Get.to(
            () => LabelDetailsscreen(label: label),
            transition: Transition.rightToLeftWithFade,
          );
        },
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              Container(
                width: 12.w,
                height: 12.w,
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.label_important_outlined,
                  color: primaryColor,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label.name,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        if (isFavorite)
                          Row(
                            children: [
                              Icon(
                                Icons.star_rounded,
                                size: 16.sp,
                                color: Colors.amber,
                              ),
                              SizedBox(width: 2.w),
                            ],
                          ),
                        Text(
                          "ID: ${label.id}",
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.sp,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: colorScheme.onSurface.withValues(alpha: 0.5),
                size: 20.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<dynamic> _getFilteredLabels() {
    var labels = List<dynamic>.from(controller.labels);

    if (_searchController.text.isNotEmpty) {
      labels =
          labels.where((label) {
            final name = label.name.toString().toLowerCase();
            final searchTerm = _searchController.text.toLowerCase();
            return name.contains(searchTerm);
          }).toList();
    }

    switch (_currentFilter) {
      case 'favorites':
        labels = labels.where((label) => label.is_favorite == true).toList();
        break;
    }

    labels.sort((a, b) => b.id.compareTo(a.id));

    return labels;
  }
}
