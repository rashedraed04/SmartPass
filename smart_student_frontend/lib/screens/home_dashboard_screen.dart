import 'dart:convert';
import 'package:smart_student_frontend/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:easy_localization/easy_localization.dart';
import '../services/auth_service.dart';
import '../providers/settings_provider.dart';
import 'academic_assistant_screen.dart';
import 'community_screen.dart';
import 'gpa_calculator_screen.dart';
import 'exam_tracker_screen.dart';
import 'college_navigator.dart';
import 'profile_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HomeDashboardScreen

// ─────────────────────────────────────────────────────────────────────────────
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {

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
              color: isDark ? Colors.white : const Color(0xFF003B00),
            ),
          ),
          content: Text(
            'exit_app_confirmation'.tr(),
            style: TextStyle(
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'cancel'.tr(),
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            TextButton(
              onPressed: () {
                SystemNavigator.pop();
              },
              child: Text(
                'exit'.tr(),
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isDark = settings.isDarkMode;
    final primary = Theme.of(context).colorScheme.primary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) async {
        if (didPop) return;
        await _showExitConfirmationDialog(context);
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      // ── Requirement 1: Clean AppBar — no drawer, no leading, no menu icon ──
      appBar: AppBar(
        automaticallyImplyLeading: false, // forcefully suppress burger icon
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'home'.tr(),
          style: TextStyle(
            color: primary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          // Only the notification bell — nothing else
          _NotificationBell(
            currentUid: authService.currentUserId ?? '',
          ),
        ],
      ),

      body: SafeArea(
        top: false, // AppBar already handles the top safe area
        child: Column(
          children: [
            // ── Scrollable content ──────────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 16),

                      // ── Header icon ────────────────────────────────────────
                      Center(
                        child: Image.asset(
                          isDark
                              ? 'assets/images/app_logo_dark.png'
                              : 'assets/images/app_logo_light.png',
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // ── Welcome heading ────────────────────────────────────
                      Text(
                        'welcome_academic_assistant'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // ── Subtitle ───────────────────────────────────────────
                      Text(
                        'everything_you_need'.tr(),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // ── Feature grid ── Requirement 4-4: dynamic card titles ─
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.0,
                        children: [
                          FeatureCard(
                            title: 'feature_ai_assistant'.tr(),
                            icon: Icons.auto_awesome,
                            onTap: () {
                              final String currentUid =
                                  authService.currentUserId ?? '';
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AcademicAssistantScreen(
                                    key: ValueKey(currentUid),
                                  ),
                                ),
                              );
                            },
                          ),
                          FeatureCard(
                            title: 'feature_community'.tr(),
                            icon: Icons.people_alt,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CommunityScreen(),
                              ),
                            ),
                          ),
                          FeatureCard(
                            title: 'feature_gpa_calculator'.tr(),
                            icon: Icons.calculate,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const GpaCalculatorScreen(),
                              ),
                            ),
                          ),
                          FeatureCard(
                            title: 'feature_exam_tracker'.tr(),
                            icon: Icons.calendar_month,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ExamTrackerScreen(),
                              ),
                            ),
                          ),
                          FeatureCard(
                            title: 'feature_college_guide'.tr(),
                            icon: Icons.map,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CollegeNavigatorScreen(),
                              ),
                            ),
                          ),
                          FeatureCard(
                            title: 'feature_profile'.tr(),
                            icon: Icons.person,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ),

            // ── Fixed bottom action row ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Left – Theme toggle (dark / light)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.dark_mode_outlined,
                          color: primary,
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Switch(
                          value: isDark,
                          onChanged: (_) => settings.toggleTheme(),
                          activeColor: primary,
                          activeTrackColor: primary.withValues(alpha: 0.4),
                          inactiveThumbColor: primary,
                          inactiveTrackColor: primary.withValues(alpha: 0.25),
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ),

                  // Right – Language toggle (EN / ع)
                  GestureDetector(
                    onTap: () {
                      final newLocale = context.locale.languageCode == 'en' 
                          ? const Locale('ar') 
                          : const Locale('en');
                      context.setLocale(newLocale);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'EN / ع',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.tune,
                            color: primary,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FeatureCard – uses Theme tokens, no hardcoded hex colors
// ─────────────────────────────────────────────────────────────────────────────
class FeatureCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const FeatureCard({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final cardColor = Theme.of(context).cardColor;

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: primary.withValues(alpha: 0.2),
          highlightColor: primary.withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(icon, size: 28, color: primary),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// _NotificationBell — REST API based notifications
// ════════════════════════════════════════════════════════════════════════════
class _NotificationBell extends StatefulWidget {
  final String currentUid;
  const _NotificationBell({required this.currentUid});

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell> {
  int unreadCount = 0;
  List<dynamic> notifs = [];

  @override
  void initState() {
    super.initState();
    _fetchNotifs();
  }

  Future<void> _fetchNotifs() async {
    if (widget.currentUid.isEmpty) return;
    try {
      final res = await apiService.get('notifications/');
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        int unread = data.where((n) => n['is_read'] != true).length;
        if (mounted) {
          setState(() {
            notifs = data;
            unreadCount = unread;
          });
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUid.isEmpty) return const SizedBox.shrink();
    final hasUnread = unreadCount > 0;

    return Padding(
      padding: const EdgeInsets.only(left: 4, right: 8),
      child: Stack(
        alignment: Alignment.center,
        children: [
          IconButton(
            tooltip: 'الإشعارات',
            icon: Icon(
              hasUnread ? Icons.notifications_rounded : Icons.notifications_none_rounded,
              color: Theme.of(context).appBarTheme.iconTheme?.color ??
                  Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => _showNotificationsSheet(context),
          ),
          if (hasUnread)
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
  }

  void _showNotificationsSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    for (final notif in notifs) {
      if (notif['is_read'] != true) {
        apiService.post('notifications/${notif['id']}/mark_read/', {});
      }
    }
    setState(() => unreadCount = 0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Text(
                      'الإشعارات',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF003B00),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: notifs.isEmpty
                    ? Center(
                        child: Text(
                          'لا توجد إشعارات',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollController,
                        itemCount: notifs.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: isDark ? Colors.white10 : Colors.black12,
                        ),
                        itemBuilder: (context, index) {
                          final data = notifs[index];
                          final msg = data['message'] ?? '';
                          final isRead = data['is_read'] == true;
                          String timeStr = '';
                          if (data['created_at'] != null) {
                            try {
                              final dt = DateTime.parse(data['created_at']);
                              timeStr = '${dt.year}/${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
                            } catch (_) {}
                          }

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            tileColor: isRead ? Colors.transparent : (isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE8F5E9)),
                            leading: CircleAvatar(
                              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              child: Icon(Icons.notifications, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                            ),
                            title: Text(
                              msg,
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF003B00),
                              ),
                            ),
                            subtitle: timeStr.isNotEmpty
                                ? Text(
                                    timeStr,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? const Color(0xFF64748B)
                                          : const Color(0xFF94A3B8),
                                    ),
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

}
