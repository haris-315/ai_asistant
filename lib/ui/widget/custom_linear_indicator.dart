import 'package:flutter/material.dart';

class CustomLinearIndicator extends StatelessWidget {
  final bool isDangrousAction;
  const CustomLinearIndicator({super.key, this.isDangrousAction = false});

  @override
  Widget build(BuildContext context) {
    return LinearProgressIndicator(
      color: isDangrousAction ? Colors.red : Colors.blue,
      backgroundColor: Colors.white,
    );
  }
}
