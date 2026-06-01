import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'feed_screen.dart';
import 'search_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFAD1457),
      appBar: AppBar(
        backgroundColor: const Color(0xFFAD1457),
        elevation: 0,
        title: ShaderMask(
          shaderCallback: (bounds) =>
              RikiaTheme.mainGradient.createShader(bounds),
          child: const Text(
            'RIKIA',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: const Color(0xFFAD1457),
              letterSpacing: 4,
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: RikiaTheme.purple,
          indicatorWeight: 3,
          labelColor: RikiaTheme.purple,
          unselectedLabelColor: const Color(0xFF1976D2),
          tabs: const [
            Tab(icon: Icon(Icons.home_outlined), text: 'Home'),
            Tab(icon: Icon(Icons.search), text: 'Search'),
            Tab(icon: Icon(Icons.notifications_outlined), text: 'Alerts'),
            Tab(icon: Icon(Icons.person_outline), text: 'Profile'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          FeedScreen(),
          SearchScreen(),
          NotificationsScreen(),
          ProfileScreen(),
        ],
      ),
    );
  }
}
