import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final Widget? action;
  const CustomAppBar({super.key, this.action, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      actions: action != null ? [action!] : null,
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color.fromRGBO(0, 0, 0, 1),
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(width: 8),
          Image.asset('assets/launchericon.png', height: 80),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
