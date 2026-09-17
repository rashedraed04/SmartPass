import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'admin_dashboard_view.dart';
import 'moderation_queue_view.dart';
import 'academic_assistant_screen.dart';
import 'community_screen.dart';

import 'settings_screen.dart';
import 'login_screen.dart';
import 'admin_profile_edit.dart';
import 'package:smart_student_frontend/services/auth_service.dart';
import 'package:smart_student_frontend/services/api_service.dart';
import 'dart:convert';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _views = [
    const AdminDashboardView(),
    const ModerationQueueView(),
    const CommunityScreen(isAdmin: true),
  ];

  Future<void> _showExitConfirmationDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF131724) : Colors.white,
          title: Text(
            'exit_app_title'.tr(),
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'exit_app_confirm'.tr(),
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'cancel'.tr(),
                style: TextStyle(
                  color: isDark ? Colors.white60 : const Color(0xFF94A3B8),
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                SystemNavigator.pop();
              },
              child: Text(
                'exit'.tr(),
                style: const TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _showExitConfirmationDialog(context);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          title: Text(
            _currentIndex == 0
                ? 'لوحة الإدارة'
                : _currentIndex == 1
                    ? 'إدارة البلاغات'
                    : 'مجتمع الكلية (وضع المدير)',
          ),
          leading: Builder(
            builder: (context) {
              return IconButton(
                icon: Icon(Icons.menu, color: Theme.of(context).appBarTheme.iconTheme?.color ?? Theme.of(context).textTheme.bodyMedium?.color),
                onPressed: () => Scaffold.of(context).openDrawer(),
              );
            },
          ),
          actions: [
            // ── Notification Bell: checks reports endpoint ──────────
            FutureBuilder(
              future: apiService.get('reports/'),
              builder: (context, snapshot) {
                bool hasReports = false;
                if (snapshot.hasData && snapshot.data != null) {
                  try {
                    final data = jsonDecode((snapshot.data as dynamic).body);
                    if (data is List && data.isNotEmpty) hasReports = true;
                  } catch (_) {}
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 8, right: 4),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      IconButton(
                        tooltip: 'البلاغات',
                        icon: Icon(
                          Icons.notifications_rounded,
                          color: Theme.of(context).appBarTheme.iconTheme?.color ?? Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        onPressed: () {
                          setState(() => _currentIndex = 1); // reports tab
                        },
                      ),
                      if (hasReports)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Color(0xFFEF4444),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        drawer: Drawer(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: BoxDecoration(color: Theme.of(context).cardColor),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const CircleAvatar(
                      radius: 30,
                      backgroundColor: Color(0xFF2C3246),
                      child: Icon(
                        Icons.admin_panel_settings,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'مدير النظام',
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      authService.currentUserEmail ?? 'admin@university.edu',
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              _buildDrawerSection('قسم الإدارة'),
              _buildDrawerItem(Icons.dashboard_rounded, 'لوحة التحكم', () {
                setState(() => _currentIndex = 0);
                Navigator.pop(context);
              }),
              _buildDrawerItem(
                Icons.report_problem_rounded,
                'إدارة البلاغات',
                () {
                  setState(() => _currentIndex = 1);
                  Navigator.pop(context);
                },
              ),
              const Divider(color: Color(0xFF2C3246)),
              _buildDrawerSection('ميزات الطلاب'),
              _buildDrawerItem(
                Icons.smart_toy_rounded,
                'المساعد الأكاديمي',
                () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AcademicAssistantScreen(),
                    ),
                  );
                },
              ),
              _buildDrawerItem(Icons.forum_rounded, 'مجتمع الكلية', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CommunityScreen()),
                );
              }),

              const Divider(color: Color(0xFF2C3246)),
              _buildDrawerItem(Icons.manage_accounts_rounded, 'تعديل الملف الشخصي', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminProfileEditScreen(),
                  ),
                );
              }),
              _buildDrawerItem(Icons.settings_rounded, 'الإعدادات', () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              }),
              _buildDrawerItem(Icons.logout_rounded, 'تسجيل الخروج', () async {
                final nav = Navigator.of(context);
                await authService.logout();
                nav.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }, isDestructive: true),
            ],
          ),
        ),
        body: IndexedStack(index: _currentIndex, children: _views),
        bottomNavigationBar: Theme(
          data: ThemeData(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            selectedItemColor: Theme.of(context).colorScheme.primary,
            unselectedItemColor: Colors.grey,
            showUnselectedLabels: true,
            type: BottomNavigationBarType.fixed,
            elevation: 0,
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.home_rounded),
                ),
                label: 'الرئيسية',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.description_rounded),
                ),
                label: 'البلاغات',
              ),
              BottomNavigationBarItem(
                icon: Padding(
                  padding: EdgeInsets.only(bottom: 4.0),
                  child: Icon(Icons.school_rounded),
                ),
                label: 'الطلاب',
              ),
            ],
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
    IconData icon,
    String title,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    final color = isDestructive ? Theme.of(context).colorScheme.secondary : (Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white);
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title, style: TextStyle(color: color, fontSize: 14)),
      onTap: onTap,
    );
  }
}
