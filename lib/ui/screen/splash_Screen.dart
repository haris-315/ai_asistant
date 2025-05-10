import 'package:ai_asistant/ui/screen/home/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:page_transition/page_transition.dart';

import '../../core/services/session_store_service.dart';
import 'auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final Animation<double> _logoAnimation;
  late final AnimationController _progressController;
  late final Animation<double> _progressAnimation;
  bool _showProgressIndicator = false;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _progressController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeInOut,
    );

    _progressAnimation = CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeOut,
    );

    _startAnimations();

    _checkAuthStatus();
  }

  Future<void> _startAnimations() async {
    await _logoController.forward();
    setState(() => _showProgressIndicator = true);
    await _progressController.forward();
  }

  Future<void> _checkAuthStatus() async {
    // Add slight delay to ensure animations complete
    await Future.delayed(const Duration(milliseconds: 2500));

    final token = await SecureStorage.getToken();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageTransition(
        type: PageTransitionType.fade,
        duration: const Duration(milliseconds: 500),
        child: token == null ? const LoginScreen() : const HomeScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.primaryColor.withOpacity(0.2),
              theme.scaffoldBackgroundColor.withOpacity(0.3),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FadeTransition(
                opacity: _logoAnimation,
                child: Image.asset(
                  'assets/Illustration.png',
                  width: size.width * 0.8, 
                  height: size.height * 0.4,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),
              if (_showProgressIndicator)
                FadeTransition(
                  opacity: _progressAnimation,
                  child: SpinKitCircle(color: theme.primaryColor, size: 40.0),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
