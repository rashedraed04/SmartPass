import 'package:smart_student_frontend/services/post_service.dart';
import 'package:flutter/material.dart';
import 'package:smart_student_frontend/services/auth_service.dart';

import '../models/post_model.dart';
import '../widgets/post_card_widget.dart';

class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = authService.currentUserId;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            'منشوراتي',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_forward_rounded,
                color: isDark ? Colors.white : const Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: uid == null
            ? const Center(child: Text('يرجى تسجيل الدخول'))
            : FutureBuilder<List<Post>>(
                future: PostService().fetchMyPosts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: Theme.of(context).primaryColor,
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'حدث خطأ في جلب المنشورات',
                        style: TextStyle(
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    );
                  }
                  final posts = snapshot.data ?? [];
                  if (posts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.article_outlined,
                            size: 64,
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFCBD5E1),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لم تقم بنشر أي شيء بعد',
                            style: TextStyle(
                              fontSize: 16,
                              color: isDark
                                  ? const Color(0xFF64748B)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
                    itemCount: posts.length,
                    itemBuilder: (_, i) => PostCard(post: posts[i]),
                  );
                },
              ),
      ),
    );
  }
}
