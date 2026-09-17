import 'package:flutter/material.dart';
import 'home_dashboard_screen.dart';

class MainScreen extends StatefulWidget {
  final String email;
  final String token;

  const MainScreen({
    super.key,
    this.email = 'user@test.com',
    this.token = '',
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: HomeDashboardScreen(),
      ),
    );
  }
}
