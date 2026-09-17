import 'package:flutter/material.dart';
import 'package:smart_student_frontend/services/api_service.dart';
import 'dart:convert';

class ModerationQueueView extends StatelessWidget {
  const ModerationQueueView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Color(0xFF2C3246),
                child: Icon(Icons.person, color: Colors.white),
              ),
              const Text(
                'إدارة البلاغات',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_none, color: Colors.white),
                    onPressed: () {},
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 30),

          // Title Section
          const Text(
            'قائمة المراجعة',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'مراجعة المحتوى الذي تم الإبلاغ عنه من قبل الطلاب\nوالمشرفين.',
            style: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 16,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 30),

          // Report Cards Future List
          FutureBuilder(
            future: apiService.get('reports/'),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40.0),
                    child: CircularProgressIndicator(color: Colors.redAccent),
                  ),
                );
              }

              List<dynamic> reports = [];
              if (snapshot.hasData && snapshot.data != null) {
                try {
                  final decoded = jsonDecode((snapshot.data as dynamic).body);
                  if (decoded is List) reports = decoded;
                } catch (_) {}
              }

              if (reports.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60),
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline, size: 60, color: Colors.grey.shade600),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد بلاغات معلقة حالياً',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: reports.map((doc) {
                  final data = doc as Map<String, dynamic>;
                  final reportId = data['id']?.toString() ?? '';
                  final postId = data['reported_post']?.toString();
                  final reporterName = data['reporter_name'] ?? data['reporter_email'] ?? 'مستخدم غير معروف';
                  final reporterId = '#${data['reporter'] ?? '0000'}';
                  final content = data['reason'] ?? data['post_content'] ?? 'محتوى غير متوفر';
                  
                  // Construct time ago string
                  String timeAgo = 'الآن';
                  if (data['timestamp'] != null) {
                    final dt = DateTime.tryParse(data['timestamp'].toString()) ?? DateTime.now();
                    final diff = DateTime.now().difference(dt);
                    if (diff.inDays > 0) {
                      timeAgo = 'منذ ${diff.inDays} أيام';
                    } else if (diff.inHours > 0) {
                      timeAgo = 'منذ ${diff.inHours} ساعات';
                    } else if (diff.inMinutes > 0) {
                      timeAgo = 'منذ ${diff.inMinutes} دقائق';
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20.0),
                    child: _buildReportCard(
                      context: context,
                      reportId: reportId,
                      postId: postId,
                      reporterName: reporterName,
                      reporterId: reporterId,
                      timeAgo: timeAgo,
                      reportContent: content,
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildReportCard({
    required BuildContext context,
    required String reportId,
    required String? postId,
    required String reporterName,
    required String reporterId,
    required String timeAgo,
    required String reportContent,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1F2536),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.red.shade300,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'مُبلغ عنه بواسطة: $reporterName',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'معرف الطالب: $reporterId',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    color: Colors.grey.shade500,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    timeAgo,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Content Box
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF0F1524),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'طالب مخالف',
                    style: TextStyle(
                      color: Color(0xFF900B09),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  reportContent,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textDirection: TextDirection.ltr, // Safest for varied content
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  onPressed: () => _handleDelete(context, reportId, postId),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA61A1D),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  icon: const Icon(Icons.delete_outline, color: Colors.white, size: 20),
                  label: const Text(
                    'حذف المحتوى',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                flex: 2,
                child: TextButton.icon(
                  onPressed: () => _handleDismiss(context, reportId),
                  style: TextButton.styleFrom(
                    backgroundColor: const Color(0xFF2B3349),
                    padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.visibility_off_outlined, color: Colors.white, size: 20),
                  label: const Text(
                    'تجاهل',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleDelete(BuildContext context, String reportId, String? postId) async {
    try {
      if (postId != null && postId.isNotEmpty) {
        await apiService.delete('posts/$postId/');
      }
      await apiService.post('reports/$reportId/resolve/', {});

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف المحتوى والبلاغ بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ أثناء الحذف: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDismiss(BuildContext context, String reportId) async {
    try {
      await apiService.post('reports/$reportId/dismiss/', {});
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تجاهل البلاغ'),
            backgroundColor: Colors.grey,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ اثناء تجاهل البلاغ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
