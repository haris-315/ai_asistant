// ignore_for_file: library_private_types_in_public_api

import 'package:ai_asistant/Controller/auth_controller.dart';
import 'package:ai_asistant/core/services/settings_service.dart';
import 'package:ai_asistant/core/shared/functions/show_snackbar.dart';
import 'package:ai_asistant/state_mgmt/chats/cubit/chat_cubit.dart';
import 'package:ai_asistant/state_mgmt/sessions/cubit/sessions_cubit.dart';
import 'package:ai_asistant/ui/screen/assistant/assistant_control_page.dart';
import 'package:ai_asistant/ui/screen/assistant/reports.dart';
import 'package:ai_asistant/ui/screen/home/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:page_transition/page_transition.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import '../screen/auth/login_screen.dart';

class SideMenu extends StatefulWidget {
  const SideMenu({super.key});

  @override
  _SideMenuState createState() => _SideMenuState();
}

class _SideMenuState extends State<SideMenu> {
  String selectedMenu = "";
  bool email = false;
  bool task = false;
  bool meeting = false;
  bool aichat = true;
  AuthController authController = Get.find<AuthController>();
  @override
  void initState() {
    super.initState();
    context.read<SessionsCubit>().loadSessions(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SessionsCubit, SessionsState>(
      listener: (context, state) {
        if (state is SessionsError) {
          showSnackBar(context: context, message: state.message, isError: true);
        }
        if (state is SessionsLoaded) {
          if (state.hasMessage) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Navigator.pop(context);
              showSnackBar(
                context: context,
                message: state.message ?? "Action Successful!",
              );
            });
          }
          if (state.shouldGoToChatScreen) {
            // context.read<ChatCubit>().setChatSession(state.sessions.first);
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(),
                settings: RouteSettings(arguments: state.sessions.first),
              ),
            );
          }
        }
      },
      builder: (context, state) {
        return Drawer(
          backgroundColor: Colors.white,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 10),
            color: Colors.transparent,
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                  height: 20.h,
                  child: Obx(
                    () => DrawerHeader(
                      decoration: BoxDecoration(color: Colors.white),
                      margin: EdgeInsets.zero,
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors
                                .primaries[(authController
                                        .userInfo
                                        .value
                                        .name
                                        .hashCode) %
                                    Colors.primaries.length]
                                .withValues(alpha: 0.7),
                            radius: 28,
                            child: Text(
                              authController.userInfo.value.name[0]
                                  .toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 24,
                              ),
                            ),
                          ),
                          SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authController.userInfo.value.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  authController.userInfo.value.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                menuItem(
                  title: "Reports",
                  icon: Icons.report_sharp,
                  isSelected: false,
                  onTap: () {
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.topToBottom,
                        child: EmailReportsPage(),
                      ),
                    );
                  },
                ),
                menuItem(
                  title: "Assistant",
                  icon: Icons.video_camera_front_outlined,

                  isSelected: selectedMenu == "Assistant",
                  onTap: () {
                    setState(() {
                      selectedMenu = "Assistant";
                      meeting = !meeting;
                    });
                    Navigator.push(
                      context,
                      PageTransition(
                        type: PageTransitionType.fade,
                        child: AssistantControlPage(),
                      ),
                    );
                  },
                ),
                // if (meeting) ...[
                //   menuItem(
                //     title: "Voice To Text",
                //     icon: Icons.record_voice_over_outlined,
                //     isSelected: selectedMenu == "Voice To Text",

                //     onTap: () {
                //       setState(() {
                //         selectedMenu = "Voice To Text";
                //         meeting = !meeting;
                //         Navigator.of(context).pop();

                //         Get.to(() => VoiceToTextScreen());
                //       });
                //     },
                //   ),
                //   menuItem(
                //     title: "Participants",
                //     icon: Icons.person_outline_outlined,

                //     isSelected: selectedMenu == "Participants",
                //     onTap: () {
                //       setState(() {
                //         selectedMenu = "Participants";
                //         meeting = !meeting;
                //         Get.to(() => ParticipantsScreen());
                //       });
                //     },
                //   ),
                // ],
                menuItem(
                  title: "AI Chat",
                  icon: Icons.person,
                  iconf: aichat ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  isSelected: selectedMenu == "AI Chat",
                  onTap: () {
                    setState(() {
                      selectedMenu = "AI Chat";
                      aichat = !aichat;
                    });
                  },
                ),

                //   menuItem(
                //   title: "Last conversation",
                //   icon: Icons.chat,
                //
                //   isSelected: selectedMenu == "Last conversation",
                //
                //   onTap: () => setState(() => selectedMenu = "Last conversation"),
                // ),
                if (state is SessionsLoading)
                  Center(child: SpinKitChasingDots(color: Colors.blue))
                else if (state is SessionsLoaded) ...[
                  if (aichat) ...[
                    menuItem(
                      title: "New Session",
                      icon: Icons.add,

                      isSelected: selectedMenu == "New Session",
                      onTap: () {
                        setState(() {
                          selectedMenu = "New Session";
                          aichat = !aichat;
                        });
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => ChatScreen()),
                        );
                      },
                    ),
                    ...state.sessions.map(
                      (session) => Align(
                        alignment: Alignment.centerRight,
                        child: menuItem(
                          title: session.title,

                          sessionId: session.id,
                          icon: Icons.chat,
                          forSession: true,
                          isSelected: selectedMenu == session.id,

                          onTap: () {
                            setState(() => selectedMenu = session.id);
                            context.read<ChatCubit>().setChatSession(
                              session.id,
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ChatScreen(session: session),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ] else if (state is SessionsError)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error, color: Colors.redAccent),
                        SizedBox(width: 4),
                        Text(
                          state.message ?? "There was an Error!",
                          style: TextStyle(color: Colors.redAccent),
                        ),
                      ],
                    ),
                ],

                menuItem(
                  title: "Logout",
                  icon: Icons.logout,
                  isSelected: false,
                  logout: true,
                  textColor: Colors.red,
                  iconColor: Colors.red,
                  onTap: () async {
                    await SettingsService.removeSetting("access_token");
                    Get.offAll(() => LoginScreen());
                  },
                ),
                SizedBox(
                  child: Center(child: Image.asset("assets/launchericon.png")),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget menuItem({
    required String title,
    required IconData icon,
    IconData? iconf,
    bool forSession = false,
    String? sessionId,
    required bool isSelected,
    bool logout = false,
    Color textColor = Colors.black,
    Color iconColor = Colors.blue,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color:
            logout
                ? Colors.red.shade50
                : isSelected
                ? Colors.blue
                : Colors.blueGrey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                // maxLines: 1,
                style: TextStyle(
                  overflow: TextOverflow.ellipsis,

                  fontSize: 14,
                  color: isSelected ? Colors.white : textColor,
                ),
              ),
            ),
            if (!forSession)
              Icon(iconf, color: isSelected ? Colors.white : iconColor),
          ],
        ),
        leading: Icon(icon, color: isSelected ? Colors.white : iconColor),
        onTap: onTap,
        trailing:
            !forSession
                ? null
                : GestureDetector(
                  onTap: () {
                    context.read<SessionsCubit>().deleteSession(sessionId!);
                    try {
                      if ((context.read<ChatCubit>().state as ChatLoaded)
                              .currentActiveSession
                              .id ==
                          sessionId) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => ChatScreen()),
                        );
                      }
                    } catch (_) {}
                  },
                  child: Icon(Icons.delete, color: Colors.red.shade700),
                ),
      ),
    );
  }

  Widget expansionMenu({
    required String title,
    required IconData icon,
    required bool isSelected,
    required List<String> children,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color:
            isSelected
                ? Colors.blue.withValues(alpha: 0.2)
                : Colors.grey.shade200,
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          title: Text(
            title,
            style: TextStyle(
              fontSize: 16,
              color: isSelected ? Colors.blue : Colors.black,
            ),
          ),
          leading: Icon(icon, color: isSelected ? Colors.blue : Colors.blue),
          children:
              children.map((child) {
                return ListTile(
                  title: Text(
                    child,
                    style: TextStyle(fontSize: 14, color: Colors.black),
                  ),
                  onTap: () => setState(() => selectedMenu = title),
                );
              }).toList(),
        ),
      ),
    );
  }
}
