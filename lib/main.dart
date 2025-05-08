import 'package:ai_asistant/Controller/auth_Controller.dart';
import 'package:ai_asistant/core/services/session_store_service.dart';
import 'package:ai_asistant/core/services/settings_service.dart';
import 'package:ai_asistant/core/services/snackbar_service.dart';
import 'package:ai_asistant/core/shared/constants.dart';
import 'package:ai_asistant/state_mgmt/chats/cubit/chat_cubit.dart';
import 'package:ai_asistant/state_mgmt/email/cubit/email_cubit.dart';
import 'package:ai_asistant/state_mgmt/sessions/cubit/sessions_cubit.dart';
import 'package:ai_asistant/ui/screen/home/dashboard.dart';
import 'package:ai_asistant/ui/screen/splash_Screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:responsive_sizer/responsive_sizer.dart';

import 'Controller/bar_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Get.put(AuthController());
  Get.put(TaskController());
  await SettingsService.storeSetting(
    AppConstants.appStateKey,
    AppConstants.appStateInitializing,
  );
  // SpeechRecognitionService speechService = SpeechRecognitionService();
  // await speechService.initialize();
  // speechService.recognizedTextStream.listen((text) {
  // print(text);
  // });
  await SecureStorage.storeToken(
    // "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJoazMxNS5pbkBvdXRsb29rLmNvbSJ9.J5UFE8c37RjqtVdrHyBURAjTEKZOIcoJJjrs8xjZvxk",
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJpLmFyc2xhbmtoYWxpZEBvdXRsb29rLmNvbSJ9.6CHm10Iqv9h5FOqY2dsJdRhFP0abcyUstljKbPlUR4A"
  );


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
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ResponsiveSizer(
      builder: (context, orientation, screenType) {
        return GetMaterialApp(
          scaffoldMessengerKey: SnackbarService.messengerKey,
          title: 'Flutter Demo',
          debugShowCheckedModeBanner: true,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
            textTheme: TextTheme(
              bodyLarge: GoogleFonts.nunito(
                fontSize: 16.sp,
                fontWeight: FontWeight.w300,
                color: Colors.black,
              ),
              bodyMedium: GoogleFonts.lato(
                fontSize: 14.sp,
                fontWeight: FontWeight.w200,
                color: Colors.black,
              ),
              titleLarge: GoogleFonts.montserrat(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
          home: SplashScreen(),
          routes: {"/home": (context) => HomeScreen()},
        );
      },
    );
  }
}
