import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smart_student_frontend/services/api_service.dart';
import 'dart:convert';
import 'public_profile_screen.dart';

class AdminStudentsListScreen extends StatefulWidget {
  const AdminStudentsListScreen({super.key});

  @override
  State<AdminStudentsListScreen> createState() =>
      _AdminStudentsListScreenState();
}

class _AdminStudentsListScreenState extends State<AdminStudentsListScreen> {
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'قائمة الطلاب',
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_rounded,
            color: theme.textTheme.bodyMedium?.color,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // ── Search Bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              onChanged: (value) => setState(() => searchQuery = value.trim()),
              style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              decoration: InputDecoration(
                hintText: 'ابحث برقم الطالب أو الاسم...',
                hintStyle: TextStyle(
                  color: theme.textTheme.bodySmall?.color ?? Colors.grey,
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: theme.textTheme.bodySmall?.color ?? Colors.grey,
                ),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          color:
                              theme.textTheme.bodySmall?.color ?? Colors.grey,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: theme.cardColor,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.primary.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // ── Students List ────────────────────────────────────────────────
          Expanded(
            child: FutureBuilder(
              future: apiService.get('users/'),
              builder: (context, snapshot) {
                // Loading
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: colorScheme.primary,
                    ),
                  );
                }

                // Error
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'حدث خطأ أثناء تحميل البيانات',
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                      ),
                    ),
                  );
                }

                List<dynamic> users = [];
                if (snapshot.hasData && snapshot.data != null) {
                  try {
                    final decoded = jsonDecode((snapshot.data as dynamic).body);
                    if (decoded is List) users = decoded;
                  } catch (_) {}
                }

                // Empty collection
                if (users.isEmpty) {
                  return _buildEmptyState(theme);
                }

                // Filter locally
                final query = searchQuery.toLowerCase();
                final filtered = users.where((u) {
                  if (query.isEmpty) return true;
                  final data = u as Map<String, dynamic>;
                  final name =
                      (data['name'] ?? data['username'] ?? '').toString().toLowerCase();
                  final email =
                      (data['email'] ?? '').toString().toLowerCase();
                  final uid = (data['id'] ?? '').toString().toLowerCase();
                  final studentId =
                      (data['studentId'] ?? data['universityId'] ?? '')
                          .toString()
                          .toLowerCase();
                  return name.contains(query) ||
                      email.contains(query) ||
                      uid.contains(query) ||
                      studentId.contains(query);
                }).toList();

                if (filtered.isEmpty) {
                  return _buildEmptyState(theme, isSearch: true);
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final userData = filtered[index] as Map<String, dynamic>;

                    final displayName = userData['name'] ??
                        userData['username'] ??
                        userData['email'] ??
                        'مستخدم غير معروف';
                    final email = userData['email'] ?? '';
                    final uid = userData['id']?.toString() ?? '';
                    final role = userData['role'] ?? 'student';

                    // Resolve the best student-ID to show
                    final studentId = () {
                      if (userData['studentId'] != null &&
                          (userData['studentId'] as String).isNotEmpty) {
                        return userData['studentId'] as String;
                      }
                      if (userData['universityId'] != null &&
                          (userData['universityId'] as String).isNotEmpty) {
                        return userData['universityId'] as String;
                      }
                      return '#${uid.substring(0, uid.length < 8 ? uid.length : 8)}';
                    }();

                    // ── Role Badge ──────────────────────────────────────
                    Widget? roleBadge;
                    if (role == 'admin') {
                      roleBadge = Chip(
                        label: const Text(
                          'مدير',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        backgroundColor:
                            colorScheme.primary.withValues(alpha: 0.18),
                        labelStyle:
                            TextStyle(color: colorScheme.primary),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    } else {
                      roleBadge = Chip(
                        label: const Text(
                          'طالب',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: Colors.grey.withValues(alpha: 0.12),
                        labelStyle: TextStyle(
                            color: theme.textTheme.bodySmall?.color),
                        side: BorderSide.none,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize:
                            MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      );
                    }

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          // ── Avatar ──────────────────────────────────
                          leading: CircleAvatar(
                            radius: 22,
                            backgroundColor:
                                colorScheme.primary.withValues(alpha: 0.15),
                            child: Icon(
                              Icons.person_rounded,
                              color: colorScheme.primary,
                              size: 22,
                            ),
                          ),
                          // ── Requirement 1: Name + Role Badge ────────
                          title: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  displayName.toString(),
                                  style: TextStyle(
                                    color:
                                        theme.textTheme.bodyMedium?.color,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 6),
                              roleBadge,
                            ],
                          ),
                          // ── Requirement 2: Subtitle with Department ──
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (email.isNotEmpty)
                                Text(
                                  email.toString(),
                                  style: TextStyle(
                                    color:
                                        theme.textTheme.bodySmall?.color ??
                                            Colors.grey,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              const SizedBox(height: 2),
                              Text(
                                'معرف الطالب: $studentId',
                                style: TextStyle(
                                  color: colorScheme.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (userData['department'] != null &&
                                  (userData['department'] as String)
                                      .isNotEmpty) ...
                              [
                                const SizedBox(height: 2),
                                Text(
                                  'التخصص: ${userData['department']}',
                                  style:
                                      theme.textTheme.bodySmall,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                          isThreeLine: true,
                          // ── Requirement 3: Quick Actions Menu ────────
                          trailing: PopupMenuButton<String>(
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: theme.textTheme.bodySmall?.color,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (value) {
                              switch (value) {
                                case 'copy_id':
                                  Clipboard.setData(
                                    ClipboardData(text: studentId),
                                  );
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(
                                    const SnackBar(
                                      content: Text('تم نسخ المعرف'),
                                      duration: Duration(seconds: 2),
                                      behavior:
                                          SnackBarBehavior.floating,
                                    ),
                                  );
                                  break;
                                case 'view_profile':
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PublicProfileScreen(uid: uid),
                                    ),
                                  );
                                  break;
                                case 'change_role':
                                  bool isAdmin = userData['role'] == 'admin';
                                  showDialog(
                                    context: context,
                                    builder: (context) {
                                      return AlertDialog(
                                        title: const Text('تغيير الصلاحيات'),
                                        content: Text(
                                          isAdmin
                                              ? 'هل أنت متأكد من سحب صلاحيات الإدارة من هذا المستخدم؟'
                                              : 'هل أنت متأكد من منح صلاحيات الإدارة لهذا المستخدم؟',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(context);
                                            },
                                            child: const Text('إلغاء'),
                                          ),
                                          TextButton(
                                            onPressed: () async {
                                              try {
                                                String newRole = isAdmin ? 'user' : 'admin';
                                                await apiService.put(
                                                  'users/${userData['id'] ?? uid}/',
                                                  {'role': newRole},
                                                );
                                                if (context.mounted) {
                                                  Navigator.pop(context);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('تم تحديث الصلاحيات بنجاح'),
                                                    ),
                                                  );
                                                }
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('حدث خطأ أثناء تحديث الصلاحيات'),
                                                    ),
                                                  );
                                                }
                                              }
                                            },
                                            child: const Text('تأكيد'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                  break;
                              }
                            },
                            itemBuilder: (ctx) => [
                              PopupMenuItem(
                                value: 'copy_id',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.copy_rounded,
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text('نسخ المعرف'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'view_profile',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person_outline_rounded,
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text('عرض الملف الشخصي'),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'change_role',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.admin_panel_settings_rounded,
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                                    const SizedBox(width: 10),
                                    const Text('تغيير الصلاحيات'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, {bool isSearch = false}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearch ? Icons.search_off_rounded : Icons.people_outline_rounded,
              size: 64,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              isSearch ? 'لا توجد نتائج مطابقة' : 'لا يوجد طلاب مسجلون بعد',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
