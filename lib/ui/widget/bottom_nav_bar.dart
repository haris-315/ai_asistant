import 'dart:ui';

import 'package:ai_asistant/Controller/bar_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:simple_animations/simple_animations.dart';

class CustomNavBar extends StatelessWidget {
  final List<NavBarItemData> items = [
    NavBarItemData(
      icon: Icons.task_alt_outlined,
      label: "Tasks",
      activeIcon: Icons.task_alt_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF00B4D8), Color(0xFF7B2CBF)],
      ),
    ),
    NavBarItemData(
      icon: MdiIcons.briefcaseAccountOutline,
      label: "Projects",
      activeIcon: MdiIcons.briefcaseAccount,
      gradient: const LinearGradient(
        colors: [Color(0xFF00B4D8), Color(0xFF7B2CBF)],
      ),
    ),
    NavBarItemData(
      icon: Icons.delete_outline,
      label: "Trash",
      activeIcon: Icons.delete_rounded,
      gradient: const LinearGradient(
        colors: [Color(0xFF00B4D8), Color(0xFF7B2CBF)],
      ),
    ),
  ];

  final TaskController controller = Get.find<TaskController>();

  CustomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDark = theme.brightness == Brightness.dark;

    return Obx(() {
      return Container(
        height: 70,
        width: size.width * 0.90,
        margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors:
                isDark
                    ? [
                      Colors.black.withValues(alpha: 0.9),
                      Colors.grey[900]!.withValues(alpha: 0.8),
                    ]
                    : [
                      Colors.white.withValues(alpha: 0.95),
                      Colors.grey[100]!.withValues(alpha: 0.9),
                    ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color:
                  isDark ? Colors.black54 : Colors.grey.withValues(alpha: 0.3),
              blurRadius: 12,
              spreadRadius: 1,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: const Color(
                0xFF7B2CBF,
              ).withValues(alpha: isDark ? 0.2 : 0.1),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border.all(
            color:
                isDark
                    ? const Color(0xFF00B4D8).withValues(alpha: 0.3)
                    : const Color(0xFF7B2CBF).withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              PlayAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(seconds: 5),
                builder: (context, value, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors:
                            isDark
                                ? [
                                  Colors.black.withValues(alpha: 0.85),
                                  const Color(
                                    0xFF1A1A40,
                                  ).withValues(alpha: 0.9),
                                  Colors.black.withValues(alpha: 0.85),
                                ]
                                : [
                                  Colors.white.withValues(alpha: 0.9),
                                  const Color(
                                    0xFFE6E6FA,
                                  ).withValues(alpha: 0.95),
                                  Colors.white.withValues(alpha: 0.9),
                                ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        stops: [0.0, value, 1.0],
                      ),
                    ),
                  );
                },
              ),

              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(
                          0xFF00B4D8,
                        ).withValues(alpha: isDark ? 0.2 : 0.3),
                        const Color(
                          0xFF7B2CBF,
                        ).withValues(alpha: isDark ? 0.15 : 0.25),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),

              AnimatedPositioned(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOutQuad,
                left:
                    (size.width * 0.90 / items.length) *
                    controller.selectedIndex.value,
                child: PlayAnimationBuilder<double>(
                  tween: Tween(begin: 0.95, end: 1.0),
                  duration: const Duration(milliseconds: 600),
                  builder: (context, value, child) {
                    return Transform.scale(
                      scale: value,
                      child: Container(
                        width: size.width * 0.90 / items.length,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              items[controller.selectedIndex.value]
                                  .gradient
                                  .colors[0]
                                  .withValues(alpha: 0.3),
                              Colors.transparent,
                            ],
                            begin: Alignment.center,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(items.length, (index) {
                  final isSelected = controller.selectedIndex.value == index;
                  final item = items[index];

                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        controller.selectedIndex.value = index;
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        color: Colors.transparent,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                              padding: EdgeInsets.all(isSelected ? 8 : 6),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: isSelected ? item.gradient : null,
                                color: Colors.transparent,
                                boxShadow:
                                    isSelected
                                        ? [
                                          BoxShadow(
                                            color: item.gradient.colors[0]
                                                .withValues(alpha: 0.4),
                                            blurRadius: 10,
                                            spreadRadius: 3,
                                          ),
                                        ]
                                        : [],
                              ),
                              child: Icon(
                                isSelected ? item.activeIcon : item.icon,
                                size: isSelected ? 26 : 24,
                                color:
                                    isSelected
                                        ? Colors.white
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 4),

                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: theme.textTheme.labelSmall!.copyWith(
                                color:
                                    isSelected
                                        ? const Color(0xFF00B4D8)
                                        : theme.colorScheme.onSurface
                                            .withValues(alpha: 0.6),
                                fontWeight:
                                    isSelected
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                letterSpacing: isSelected ? 0.5 : 0,
                              ),
                              child: Text(
                                item.label,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class NavBarItemData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final LinearGradient gradient;

  NavBarItemData({
    required this.icon,
    required this.label,
    required this.activeIcon,
    required this.gradient,
  });
}
