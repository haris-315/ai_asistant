import 'package:ai_asistant/Controller/auth_controller.dart';
import 'package:ai_asistant/core/services/settings_service.dart';
import 'package:ai_asistant/core/services/snackbar_service.dart';
import 'package:ai_asistant/core/shared/constants.dart';
import 'package:ai_asistant/core/themes/theme.dart';
import 'package:ai_asistant/state_mgmt/chats/cubit/chat_cubit.dart';
import 'package:ai_asistant/state_mgmt/email/cubit/email_cubit.dart';
import 'package:ai_asistant/state_mgmt/sessions/cubit/sessions_cubit.dart';
import 'package:ai_asistant/ui/screen/home/dashboard.dart';
import 'package:ai_asistant/ui/screen/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import 'Controller/bar_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // ignore: unused_local_variable
  AuthController ac = Get.put(AuthController());
  Get.put(TaskController());
  await SettingsService.storeSetting(
    AppConstants.appStateKey,
    AppConstants.appStateInitializing,
  );

  // await SecureStorage.storeToken(
  //   "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJoazMxNS5pbkBvdXRsb29rLmNvbSJ9.J5UFE8c37RjqtVdrHyBURAjTEKZOIcoJJjrs8xjZvxk",
  //   // "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJpLmFyc2xhbmtoYWxpZEBvdXRsb29rLmNvbSJ9.6CHm10Iqv9h5FOqY2dsJdRhFP0abcyUstljKbPlUR4A",
  // );

  // final res = await ac.hasAccess("ai_assistant");
  // if (res) {
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => SessionsCubit()),
        BlocProvider(create: (_) => ChatCubit()),
        BlocProvider(create: (_) => EmailCubit()),
      ],
      child: MyApp(),
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

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return GetMaterialApp(
          scaffoldMessengerKey: SnackbarService.messengerKey,
          title: 'AI Assistant',
          debugShowCheckedModeBanner: true,
          theme: appTheme(),

          home: SplashScreen(),
          routes: {"/home": (context) => HomeScreen()},
        );
      },
    );
  }
}
