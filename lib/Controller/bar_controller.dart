import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:get/get.dart';

class TaskController extends GetxController {
  final NotchBottomBarController taskNavbarController =
  NotchBottomBarController(index: 0);
  var selectedIndex = 0.obs;
}
