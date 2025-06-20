// ignore_for_file: unused_local_variable

import 'package:ai_asistant/Controller/auth_controller.dart';
import 'package:ai_asistant/api_keys.dart';
import 'package:ai_asistant/core/services/native_bridge.dart';
import 'package:ai_asistant/core/services/settings_service.dart';
import 'package:ai_asistant/core/services/snackbar_service.dart';
import 'package:ai_asistant/core/shared/constants.dart';
import 'package:ai_asistant/core/themes/theme.dart';
import 'package:ai_asistant/data/models/emails/email_message_adapter.dart';
import 'package:ai_asistant/data/models/emails/email_task_adapter.dart';
import 'package:ai_asistant/state_mgmt/chats/cubit/chat_cubit.dart';
import 'package:ai_asistant/state_mgmt/email/cubit/email_cubit.dart';
import 'package:ai_asistant/state_mgmt/sessions/cubit/sessions_cubit.dart';
import 'package:ai_asistant/ui/screen/frontline/quick_guide.dart';
import 'package:ai_asistant/ui/screen/frontline/splash_screen.dart';
import 'package:ai_asistant/ui/screen/home/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import 'Controller/bar_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AuthController ac = Get.put(AuthController());
  await Hive.initFlutter();
  Hive.registerAdapter(EmailTaskAdapter());
  Hive.registerAdapter(HiveEmailAdapter());

  Get.put(TaskController());

  await SettingsService.storeSetting(
    AppConstants.appStateKey,
    AppConstants.appStateInitializing,
  );

  // for future development, create a file named api_keys.dart.
  // define the key constants and remember to add it to .gitignore
  await NativeBridge.setKeys(oAIKey: OPEN_AI_API, aAIkey: ASSEMBLY_KEY);
  // await SettingsService.customSetting(
  //   (fn) => fn.remove(AppConstants.firstCheckKey),
  // );
  bool frstStart = await SettingsService.customSetting<bool>(
    (prefs) => prefs.getBool(AppConstants.firstCheckKey) ?? true,
  );
  await SettingsService.storeSetting(
    "access_token",
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJoazMxNS5pbkBvdXRsb29rLmNvbSJ9.J5UFE8c37RjqtVdrHyBURAjTEKZOIcoJJjrs8xjZvxk",
  );
  // await SettingsService.removeSetting("access_token");

  // if (res) {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SessionsCubit()),
        BlocProvider(create: (_) => ChatCubit()),
        BlocProvider(create: (_) => EmailCubit()),
      ],
      child: AIA(isFirstStart: frstStart),
    ),
  );
  // } else {
  //   runApp(
  //     MaterialApp(
  //       home: Container(
  //         color: Colors.white70,
  //         width: double.infinity,
  //         child: Center(
  //           child: Column(
  //             children: [
  //               Icon(Icons.not_interested_sharp, size: 36, color: Colors.red),
  //               Text("Not Allowed To Proceed!"),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}

class AIA extends StatelessWidget {
  final bool isFirstStart;
  const AIA({super.key, required this.isFirstStart});
  @override
  Widget build(BuildContext context) {
    precacheImage(AssetImage("assets/splash_loading.webp"), context);
    context.read<EmailCubit>().backLoadEmails();
    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return GetMaterialApp(
          scaffoldMessengerKey: SnackbarService.messengerKey,
          title: 'AI Assistant',
          debugShowCheckedModeBanner: false,
          theme: appTheme(),
          home: isFirstStart ? QuickGuide() : SplashScreen(),
          routes: {"/home": (context) => HomeScreen()},
        );
      },
    );
  }
}
