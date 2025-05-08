import 'package:ai_asistant/core/services/settings_service.dart';
import 'package:ai_asistant/core/shared/constants.dart';
import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../Controller/auth_Controller.dart';
import '../../widget/appbar.dart';
import '../../widget/drawer.dart';
import 'navigationScreen/home_screen_content.dart';

class HomeController extends GetxController {
  var selectedIndex = 0.obs;
  final notchBottomBarController = NotchBottomBarController(index: 0);
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final HomeController controller = Get.put(HomeController());
  final AuthController authcontroller = AuthController();

  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    fetch();
    if (authcontroller.projects.isEmpty) {
      authcontroller.fetchProject(isInitialFetch: true);
    }
  }

  void fetch() async {
    if (await SettingsService.getSetting(AppConstants.appStateKey) ==
        AppConstants.appStateInitialized) {
      return;
    }
    await authcontroller.syncMailboxbulk();
    SettingsService.storeSetting(
      AppConstants.appStateKey,
      AppConstants.appStateInitialized,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: scaffoldKey,
      appBar: CustomAppBar(
        title: "AI Assistant",
        onNotificationPressed: () {
       
        },
        onProfilePressed: () {
        },
      ),
      drawer: SideMenu(),
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                // Builder(
                //   builder: (context) {
                //     return Container(
                //       height: 6.5.h,
                //       width: 13.w,
                //       decoration: BoxDecoration(
                //         borderRadius: BorderRadius.circular(8),
                //         border: Border.all(color: Colors.grey, width: 1),
                //         color: Colors.white,
                //       ),
                //       child: IconButton(
                //         icon: Icon(Icons.menu, color: Colors.black),
                //         onPressed: () {
                //           Scaffold.of(context).openDrawer();
                //         },
                //       ),
                //     );
                //   },
                // ),
                // SizedBox(width: 4.w),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: "Search",
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide(color: Colors.blue, width: 2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child:
                1 != 9
                    ? HomeContent()
                    : Obx(
                      () => IndexedStack(
                        index: controller.selectedIndex.value,
                        children: [
                          // SearchScreen(),
                          // NotificationScreen(),
                          // ProfileScreen(),
                        ],
                      ),
                    ),
          ),
        ],
      ),
      // bottomNavigationBar: CustomNotchBottomBar(controller: controller),
    );
  }
}
