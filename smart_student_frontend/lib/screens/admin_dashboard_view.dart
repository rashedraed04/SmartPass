import 'package:flutter/material.dart';
import 'package:smart_student_frontend/services/api_service.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'admin_students_list_screen.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  late Future<int> _studentsCountFuture;
  late Future<int> _postsCountFuture;
  late Future<int> _reportsCountFuture;

  @override
  void initState() {
    super.initState();
    _refreshData();
  }

  void _refreshData() {
    final statsFuture = _fetchStats();
    setState(() {
      _studentsCountFuture = statsFuture.then((m) => m['users'] ?? 0);
      _postsCountFuture = statsFuture.then((m) => m['posts'] ?? 0);
      _reportsCountFuture = statsFuture.then((m) => m['reports'] ?? 0);
    });
  }

  Future<Map<String, int>> _fetchStats() async {
    try {
      final response = await apiService.get('users/stats/');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'users': (data['users'] as num?)?.toInt() ?? 0,
          'posts': (data['posts'] as num?)?.toInt() ?? 0,
          'reports': (data['reports'] as num?)?.toInt() ?? 0,
        };
      }
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    }
    return {'users': 0, 'posts': 0, 'reports': 0};
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _refreshData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Theme.of(context).cardColor,
                  child: Icon(Icons.person, color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.white),
                ),
                Text(
                  'لوحة تحكم الإدارة',
                  style: TextStyle(
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 40), // balances the avatar on the other side
              ],
            ),
            const SizedBox(height: 30),

            // Welcome Section
            Text(
              'مرحباً بك، مدير النظام',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'نظرة عامة على الأداء الأكاديمي والعمليات\nاليومية',
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey.shade400,
                fontSize: 16,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 30),

            // Stats Cards
            _buildFutureStatCardWithNav(
              future: _studentsCountFuture,
              title: 'إجمالي الطلاب',
              badgeText: 'محدث للتو',
              badgeColor: Theme.of(context).colorScheme.primary,
              iconData: Icons.people_alt_rounded,
              iconColor: Theme.of(context).colorScheme.primary,
              iconBgColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              progressColor: Theme.of(context).colorScheme.primary,
              progressValue: 0.7,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const AdminStudentsListScreen(),
                ),
              ),
            ),
            const SizedBox(height: 15),

            _buildFutureStatCard(
              future: _postsCountFuture,
              title: 'المنشورات النشطة',
              badgeText: 'محدث للتو',
              badgeColor: Theme.of(context).colorScheme.primary,
              iconData: Icons.description_rounded,
              iconColor: Theme.of(context).colorScheme.primary,
              iconBgColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              progressColor: Theme.of(context).colorScheme.primary,
              progressValue: 0.5,
            ),
            const SizedBox(height: 15),

            _buildFutureStatCardWithAction(
              future: _reportsCountFuture,
              title: 'البلاغات المرفوعة',
              badgeText: 'مراقبة حية',
              badgeColor: Theme.of(context).colorScheme.secondary,
              iconData: Icons.error_outline_rounded,
              iconColor: Theme.of(context).colorScheme.secondary,
              iconBgColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.15),
              actionText: 'يتطلب إجراء',
              actionColor: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.2),
              actionTextColor: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 30),

            // Recent Reports Section
            _buildRecentReportsStreamCard(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildFutureStatCard({
    required Future<int> future,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required IconData iconData,
    required Color iconColor,
    required Color iconBgColor,
    required Color progressColor,
    required double progressValue,
  }) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        String value = '...';
        if (snapshot.hasData) {
          value = NumberFormat('#,###').format(snapshot.data);
        }

        return _buildStatCard(
          title: title,
          value: value,
          badgeText: badgeText,
          badgeColor: badgeColor,
          iconData: iconData,
          iconColor: iconColor,
          iconBgColor: iconBgColor,
          progressColor: progressColor,
          progressValue: progressValue,
        );
      },
    );
  }

  Widget _buildFutureStatCardWithNav({
    required Future<int> future,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required IconData iconData,
    required Color iconColor,
    required Color iconBgColor,
    required Color progressColor,
    required double progressValue,
    required VoidCallback onTap,
  }) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        String value = '...';
        if (snapshot.hasData) {
          value = NumberFormat('#,###').format(snapshot.data);
        }
        return _buildStatCardWithNav(
          title: title,
          value: value,
          badgeText: badgeText,
          badgeColor: badgeColor,
          iconData: iconData,
          iconColor: iconColor,
          iconBgColor: iconBgColor,
          progressColor: progressColor,
          progressValue: progressValue,
          onTap: onTap,
        );
      },
    );
  }

  Widget _buildStatCardWithNav({
    required String title,
    required String value,
    required String badgeText,
    required Color badgeColor,
    required IconData iconData,
    required Color iconColor,
    required Color iconBgColor,
    required Color progressColor,
    required double progressValue,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(iconData, color: iconColor, size: 28),
                ),
                Row(
                  children: [
                    Text(
                      badgeText,
                      style: TextStyle(
                        color: badgeColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.chevron_left,
                      color: badgeColor,
                      size: 18,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              value,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFutureStatCardWithAction({
    required Future<int> future,
    required String title,
    required String badgeText,
    required Color badgeColor,
    required IconData iconData,
    required Color iconColor,
    required Color iconBgColor,
    required String actionText,
    required Color actionColor,
    required Color actionTextColor,
  }) {
    return FutureBuilder<int>(
      future: future,
      builder: (context, snapshot) {
        String value = '...';
        if (snapshot.hasData) {
          value = NumberFormat('#,###').format(snapshot.data);
        }

        return _buildStatCardWithAction(
          title: title,
          value: value,
          badgeText: badgeText,
          badgeColor: badgeColor,
          iconData: iconData,
          iconColor: iconColor,
          iconBgColor: iconBgColor,
          actionText: actionText,
          actionColor: actionColor,
          actionTextColor: actionTextColor,
        );
      },
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required String badgeText,
    required Color badgeColor,
    required IconData iconData,
    required Color iconColor,
    required Color iconBgColor,
    required Color progressColor,
    required double progressValue,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 28),
              ),
              Text(
                badgeText,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressValue,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCardWithAction({
    required String title,
    required String value,
    required String badgeText,
    required Color badgeColor,
    required IconData iconData,
    required Color iconColor,
    required Color iconBgColor,
    required String actionText,
    required Color actionColor,
    required Color actionTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: iconColor, size: 28),
              ),
              Text(
                badgeText,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey, fontSize: 14),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: actionColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  actionText,
                  style: TextStyle(
                    color: actionTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentReportsStreamCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'آخر البلاغات',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          FutureBuilder(
            future: apiService.get('reports/'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              List<dynamic> docs = [];
              if (snapshot.hasData && snapshot.data != null) {
                try {
                  final decoded = jsonDecode((snapshot.data as dynamic).body);
                  if (decoded is List) {
                    docs = decoded.take(3).toList();
                  }
                } catch (_) {}
              }
              if (docs.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: Text(
                      'لا توجد بلاغات معلقة حالياً',
                      style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey.shade500),
                    ),
                  ),
                );
              }

              return Column(
                children: List.generate(docs.length, (index) {
                  final data = docs[index] as Map<String, dynamic>;
                  final title = data['reason'] ?? 'بلاغ';
                  final reporterName = data['reporter_name'] ?? data['reporter_email'] ?? 'مستخدم';

                  // Calculate time ago
                  String timeAgo = 'الآن';
                  if (data['timestamp'] != null) {
                    final dt = DateTime.tryParse(data['timestamp'].toString()) ?? DateTime.now();
                    final difference = DateTime.now().difference(dt);
                    if (difference.inDays > 0) {
                      timeAgo = 'قبل ${difference.inDays} يوم';
                    } else if (difference.inHours > 0) {
                      timeAgo = 'قبل ${difference.inHours} ساعة';
                    } else if (difference.inMinutes > 0) {
                      timeAgo = 'قبل ${difference.inMinutes} دقيقة';
                    }
                  }

                  final isRed = index == 0;

                  return Column(
                    children: [
                      _buildReportItem(
                        title: title,
                        subtitle: '$timeAgo • بواسطة: $reporterName',
                        isRedIndicator: isRed,
                        context: context,
                      ),
                      if (index < docs.length - 1)
                        Divider(color: Theme.of(context).dividerColor, height: 30),
                    ],
                  );
                }),
              );
            },
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                'عرض جميع البلاغات',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportItem({
    required String title,
    required String subtitle,
    required bool isRedIndicator,
    required BuildContext context,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 6, left: 12),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: isRedIndicator
                ? Theme.of(context).colorScheme.secondary
                : Theme.of(context).colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: Theme.of(context).textTheme.bodyMedium?.color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey.shade500, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
