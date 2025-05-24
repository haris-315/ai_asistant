import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showNotificationIcon;
  final VoidCallback? onNotificationPressed;
  final VoidCallback? onProfilePressed;

  const CustomAppBar({
    super.key,
    required this.title,
    this.showNotificationIcon = true,
    this.onNotificationPressed,
    this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,

      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8),
          Image.asset('assets/launchericon.png', height: 80),

          // Row(
          //   children: [
          //     if (showNotificationIcon)
          //       IconButton(
          //         icon: Icon(Icons.email, color: Colors.blue),
          //         onPressed: onNotificationPressed ?? () {},
          //       ),
          //   ],
          // ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
