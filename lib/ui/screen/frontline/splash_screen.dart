// ignore_for_file: library_private_types_in_public_api

import 'package:ai_asistant/Controller/auth_controller.dart';
import 'package:ai_asistant/core/services/settings_service.dart';
import 'package:ai_asistant/ui/screen/auth/login_screen.dart';
import 'package:ai_asistant/ui/screen/frontline/no_connection_page.dart';
import 'package:ai_asistant/ui/screen/home/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:page_transition/page_transition.dart';

enum NetworkState { available, notAvailable, hasError }

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;
  bool _gifLoaded = false;
  AuthController ac = Get.find<AuthController>();
  NetworkState status = NetworkState.notAvailable;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuint),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );
    runNetworkChecks();
  }

  void runNetworkChecks() async {
    try {
      bool networkTest = await ac.isInternetAvailable();
      setState(() {
        if (networkTest) {
          status = NetworkState.available;
        }
      });
    } catch (_) {
    } finally {
      Future.delayed(const Duration(seconds: 4), _checkAuthStatus);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    precacheImage(const AssetImage('assets/splash_loading.webp'), context).then(
      (_) {
        setState(() {
          _gifLoaded = true;
        });
        _animationController.forward();
      },
    );
  }

  Future<void> _checkAuthStatus() async {
    final token = await SettingsService.getToken();
    if (token != null && token.isNotEmpty) {
      await ac.loadUserInfo();
    }
    if (!mounted) return;
    if (status == NetworkState.available) {
      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 800),
          child: token == null ? const LoginScreen() : const HomeScreen(),
        ),
      );
    } else {
      Navigator.pushReplacement(
        context,
        PageTransition(
          type: PageTransitionType.fade,
          duration: const Duration(milliseconds: 800),
          child: NoConnectionPage(),
        ),
      );
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildAnimatedBackground() {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: AnimatedBuilder(
        animation: _opacityAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Image.asset(
              'assets/splash_loading.webp',
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (frame != null && !_gifLoaded) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() {
                        _gifLoaded = true;
                      });
                    }
                  });
                }
                return child;
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.black,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 60,
                          color: Colors.white.withAlpha(128),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load animation',
                          style: TextStyle(color: Colors.white.withAlpha(180)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Positioned(
      bottom: 80,
      child: SizedBox(
        width: MediaQuery.of(context).size.width,
        child: Column(
          children: [
            SpinKitFadingFour(color: Colors.white.withAlpha(200), size: 32.0),
            const SizedBox(height: 20),
            AnimatedOpacity(
              opacity: _gifLoaded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 500),
              child: Text(
                'Initializing...',
                style: TextStyle(
                  color: Colors.white.withAlpha(200),
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          _buildAnimatedBackground(),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withAlpha(180)],
                stops: const [0.5, 1.0],
              ),
            ),
          ),
          _buildLoadingIndicator(),
        ],
      ),
    );
  }
}
