import 'package:ai_asistant/core/services/settings_service.dart';
import 'package:ai_asistant/core/shared/constants.dart';
import 'package:ai_asistant/ui/screen/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class QuickGuide extends StatefulWidget {
  const QuickGuide({super.key});

  @override
  State<QuickGuide> createState() => _QuickGuideState();
}

class _QuickGuideState extends State<QuickGuide> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  bool _isLastPage = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Welcome to AI Assistant",
      description:
          "Your intelligent companion for productivity and organization",
      image: "assets/intro1.jpg",
      icon: Icons.assistant_outlined,
    ),
    OnboardingPage(
      title: "Organize Effortlessly",
      description:
          "Manage tasks, projects and reminders with natural voice commands",
      image: "assets/intro2.jpg",
      icon: Icons.task_alt_outlined,
    ),
    OnboardingPage(
      title: "Conversational AI",
      description:
          "Just speak naturally - our assistant understands context and intent",
      image: "assets/intro3.jpg",
      icon: Icons.mic_outlined,
    ),
    OnboardingPage(
      title: "Ready to Begin?",
      description: "Let's set up your account and personalize your experience",
      image: "assets/intro4.jpg",
      icon: Icons.rocket_launch_outlined,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _setNotFirstTime();
    _pageController.addListener(() {
      setState(() {
        _currentIndex = _pageController.page?.round() ?? 0;
        _isLastPage = _currentIndex == _pages.length - 1;
      });
    });
  }

  void _setNotFirstTime() async {
    await SettingsService.customSetting(
      (fn) => fn.setBool(AppConstants.firstCheckKey, false),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated PageView
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),

          // Skip button (top right)
          Positioned(
            top: 60,
            right: 30,
            child: AnimatedOpacity(
              opacity: _isLastPage ? 0 : 1,
              duration: Duration(milliseconds: 300),
              child: TextButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    PageTransition(
                      type: PageTransitionType.fade,
                      child: const LoginScreen(),
                    ),
                  );
                },
                child: const Text(
                  "Skip",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  // Animated page indicator
                  SmoothPageIndicator(
                    controller: _pageController,
                    count: _pages.length,
                    effect: ExpandingDotsEffect(
                      dotWidth: 8,
                      dotHeight: 8,
                      activeDotColor: Colors.white,
                      dotColor: Colors.white.withValues(alpha: 0.5),
                      spacing: 8,
                      expansionFactor: 3,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Next/Get Started button
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 300),
                    child:
                        _isLastPage
                            ? _buildGetStartedButton()
                            : _buildNextButton(),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background image with parallax effect
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 1.0, end: 1.2),
          duration: Duration(milliseconds: 500),
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Image.asset(
                "assets/splash_loading.webp",
                fit: BoxFit.cover,
              ),
            );
          },
        ),

        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.black.withValues(alpha: 0.7),
              ],
            ),
          ),
        ),

        // Content
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated icon
              AnimatedContainer(
                duration: Duration(milliseconds: 500),
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(page.icon, size: 50, color: Colors.white),
              ),

              const SizedBox(height: 40),

              // Title with fade animation
              AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                child: Text(
                  page.title,
                  key: ValueKey(page.title),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Description with slide animation
              AnimatedSwitcher(
                duration: Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(0, 0.2),
                      end: Offset.zero,
                    ).animate(animation),
                    child: FadeTransition(opacity: animation, child: child),
                  );
                },
                child: Text(
                  page.description,
                  key: ValueKey(page.description),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white.withValues(alpha: 0.9),
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.blueAccent,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 4,
      ),
      onPressed: () {
        _pageController.nextPage(
          duration: Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Next",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          SizedBox(width: 8),
          Icon(Icons.arrow_forward_rounded, size: 20),
        ],
      ),
    );
  }

  Widget _buildGetStartedButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 4,
      ),
      onPressed: () {
        Navigator.pushReplacement(
          context,
          PageTransition(
            type: PageTransitionType.fade,
            child: const LoginScreen(),
          ),
        );
      },
      child: Text(
        "Get Started",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final String image;
  final IconData icon;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.icon,
  });
}
