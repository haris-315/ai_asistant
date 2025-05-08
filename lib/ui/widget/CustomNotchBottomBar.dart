import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';

import '../screen/home/dashboard.dart';

class CustomNotchBottomBar extends StatelessWidget {
  final HomeController controller;
  const CustomNotchBottomBar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return
      AnimatedNotchBottomBar(
        notchBottomBarController: controller.notchBottomBarController,
        kIconSize: 20.0,
        kBottomRadius: 20.0,
        showLabel: true,
        color: Colors.blue,
        notchColor: Colors.blue,

        bottomBarItems: [
          BottomBarItem(
            inActiveItem: Icon(Icons.home_filled, color: Colors.white),
            activeItem: Icon(Icons.home_filled, color: Colors.white),
            itemLabel: "Home",
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.search, color: Colors.white),
            activeItem: Icon(Icons.search, color: Colors.white),
            itemLabel: "Search",
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.notifications, color: Colors.white),
            activeItem: Icon(Icons.notifications, color: Colors.white),
            itemLabel: "Notifications",
          ),
          BottomBarItem(
            inActiveItem: Icon(Icons.person, color: Colors.white),
            activeItem: Icon(Icons.person, color: Colors.white),
            itemLabel: "Profile",
          ),
        ],
        onTap: (index) {
          controller.selectedIndex.value = index;
          controller.notchBottomBarController.jumpTo(index);
        },
      );


    // );
  }
}
