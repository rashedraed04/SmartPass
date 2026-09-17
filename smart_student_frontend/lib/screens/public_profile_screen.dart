import 'package:flutter/material.dart';
import 'package:smart_student_frontend/services/api_service.dart';
import 'dart:convert';

class PublicProfileScreen extends StatelessWidget {
  Future<Map<String, dynamic>?> _fetchPublicUser(String id) async {
    try {
      final response = await apiService.get('users/$id/');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Error fetching public user data: $e');
    }
    return null;
  }

  final String uid;

  const PublicProfileScreen({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          foregroundColor: theme.appBarTheme.iconTheme?.color,
          title: Text(
            'الملف الشخصي',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF003B00),
            ),
          ),
          centerTitle: true,
        ),
        body: FutureBuilder<Map<String, dynamic>?>(
          future: _fetchPublicUser(uid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: theme.primaryColor),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text('حدث خطأ أثناء تحميل البيانات', style: TextStyle(color: Colors.red)),
              );
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Text('المستخدم غير موجود', style: theme.textTheme.bodyMedium),
              );
            }

            final userData = snapshot.data!;

            final name = userData['name'] ?? 'غير متوفر';
            final major = userData['major'] ?? 'غير متوفر';
            final year = userData['year'] ?? 'غير متوفر';

            return SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: isDark ? const Color(0xFF003300) : const Color(0xFFE8F0FE),
                    child: Icon(
                      Icons.person,
                      size: 60,
                      color: theme.primaryColor,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Card(
                    elevation: 0,
                    color: isDark ? const Color(0xFF003300) : Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: isDark ? const Color(0xFF003B00) : const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      children: [
                        ListTile(
                          leading: Icon(Icons.person_outline, color: theme.primaryColor),
                          title: Text('الاسم', style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.grey[400] : Colors.grey[600])),
                          subtitle: Text(name, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        Divider(height: 1, color: isDark ? const Color(0xFF003B00) : const Color(0xFFE2E8F0)),
                        ListTile(
                          leading: Icon(Icons.school_outlined, color: theme.primaryColor),
                          title: Text('التخصص', style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.grey[400] : Colors.grey[600])),
                          subtitle: Text(major, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                        Divider(height: 1, color: isDark ? const Color(0xFF003B00) : const Color(0xFFE2E8F0)),
                        ListTile(
                          leading: Icon(Icons.calendar_today_outlined, color: theme.primaryColor),
                          title: Text('السنة الدراسية', style: theme.textTheme.bodySmall?.copyWith(color: isDark ? Colors.grey[400] : Colors.grey[600])),
                          subtitle: Text(year, style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
