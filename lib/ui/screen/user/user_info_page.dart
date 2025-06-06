import 'package:ai_asistant/core/services/settings_service.dart';
import 'package:ai_asistant/ui/screen/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:page_transition/page_transition.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _headerHeightAnimation;
  late Animation<Color?> _headerColorAnimation;

  final Map<String, String> user = {
    'name': 'Alex Johnson',
    'email': 'alex.johnson@example.com',
    'joinDate': 'Member since June 2022',
    'bio': 'Mobile developer & design enthusiast',
    'location': 'San Francisco, CA',
    'website': 'alexjohnson.dev',
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuint));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _headerHeightAnimation = Tween<double>(
      begin: 200,
      end: 150,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _headerColorAnimation = ColorTween(
      begin: Colors.blue[800],
      end: Colors.blue[600],
    ).animate(_controller);

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[50],
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: _headerHeightAnimation.value,
                floating: false,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    color: _headerColorAnimation.value,
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        Center(
                          child: FadeTransition(
                            opacity: _fadeAnimation,
                            child: const CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(
                                'https://randomuser.me/api/portraits/men/42.jpg',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 19),
                      ],
                    ),
                  ),
                  titlePadding: EdgeInsets.all(16),
                  expandedTitleScale: 1.5,
                  title: Text(
                    user['name'] ?? "Jhon Doe",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  centerTitle: true,
                ),
                backgroundColor: Colors.blue,
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        children: [
                          _ProfileSection(
                            title: 'About',
                            children: [
                              _ProfileItem(
                                icon: Icons.email,
                                value: user['email'] ?? "jhondoe@example.com",
                              ),
                              _ProfileItem(
                                icon: Icons.calendar_today,
                                value: user['joinDate'] ?? "12/12/2024",
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),
                          _StatsSection(),
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _ProfileSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800],
              ),
            ),
            const Divider(color: Colors.blue, height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String value;

  const _ProfileItem({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final List<Map<String, dynamic>> stats = [
    {'label': 'Projects', 'value': '24', 'icon': Icons.work},
    {'label': 'Tasks', 'value': '156', 'icon': Icons.task_alt_outlined},
    {'label': 'Lables', 'value': '89', 'icon': Icons.label},
  ];

  _StatsSection();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children:
                  stats.map((stat) {
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue[100],
                            shape: BoxShape.circle,
                          ),
                          child: Icon(stat['icon'], color: Colors.blue[800]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          stat['value'],
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                        Text(
                          stat['label'],
                          style: TextStyle(color: Colors.blue[800]),
                        ),
                      ],
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  SettingsService.removeSetting("access_key");
                  Navigator.pushAndRemoveUntil(
                    context,
                    PageTransition(
                      type: PageTransitionType.bottomToTop,
                      child: LoginScreen(),
                    ),
                    (l) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Sign Out',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
