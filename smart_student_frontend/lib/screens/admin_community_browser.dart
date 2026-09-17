import 'package:flutter/material.dart';
import 'package:smart_student_frontend/services/post_service.dart';
import 'package:smart_student_frontend/models/post_model.dart';

class AdminCommunityBrowser extends StatefulWidget {
  const AdminCommunityBrowser({super.key});

  @override
  State<AdminCommunityBrowser> createState() => _AdminCommunityBrowserState();
}

class _AdminCommunityBrowserState extends State<AdminCommunityBrowser> {
  // Sets "Community" (المجتمع) as the active tab in the BottomNavigationBar.
  int _selectedIndex = 1;

  // Service function to handle post deletion.
  Future<void> _deletePost(String postId) async {
    // Show a confirmation dialog before deleting to avoid accidental actions.
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
          'هل أنت متأكد من أنك تريد حذف هذا المنشور؟ لا يمكن التراجع عن هذا الإجراء.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('حذف', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await PostService().deletePost(postId);
        setState(() {}); // refresh

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف المحتوى بنجاح.')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('حدث خطأ أثناء الحذف: $e')));
        }
      }
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // TODO: Add your navigation routing logic here based on the selected index
  }

  @override
  Widget build(BuildContext context) {
    // Dark theme aesthetic applies automatically if the app theme is set to dark.
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'مجتمع كلية التقنية (إشراف)',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Post>>(
        future: PostService().fetchPosts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          }

          final posts = snapshot.data ?? [];
          if (posts.isEmpty) {
            return const Center(
              child: Text('لا توجد منشورات في المجتمع حالياً.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final post = posts[index];
              final postId = post.id;
              final authorName = post.authorName;
              final content = post.content;
              final timeString = post.timeAgo;

              return Card(
                margin: const EdgeInsets.only(bottom: 16.0),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Post Header
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.2),
                            child: const Icon(Icons.person),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  authorName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                if (timeString.isNotEmpty)
                                  Text(
                                    timeString,
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Post Content
                      Text(
                        content,
                        style: const TextStyle(fontSize: 15, height: 1.4),
                      ),
                      const SizedBox(height: 20),

                      // Core Requirement: Prominent Delete Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _deletePost(postId),
                          icon: const Icon(
                            Icons.delete_forever,
                            color: Colors.white,
                            size: 24,
                          ),
                          label: const Text(
                            'حذف المحتوى',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red[700],
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      // Master Scaffold Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'المجتمع'),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'البلاغات'),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'الإعدادات',
          ),
        ],
      ),
    );
  }

}
