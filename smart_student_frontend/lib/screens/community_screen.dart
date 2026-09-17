import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import '../models/post_model.dart';
import '../services/post_service.dart';
import '../services/notification_service.dart';
import '../widgets/post_card_widget.dart';

class CommunityScreen extends StatefulWidget {
  final bool isAdmin;
  const CommunityScreen({super.key, this.isAdmin = false});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final _searchController = TextEditingController();
  final _createPostController = TextEditingController();
  
  final List<String> _majors = ['الكل', 'CS', 'CYBER', 'CIS', 'BIT', 'DS', 'AI'];
  String _selectedMajor = 'الكل';
  
  final PostService _postService = PostService();
  final NotificationService _notificationService = NotificationService();
  late Future<List<Post>> _postsFuture;
  late Future<List<AppNotification>> _notificationsFuture;

  @override
  void initState() {
    super.initState();
    _fetchPosts();
    _notificationsFuture = _notificationService.fetchNotifications();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _createPostController.dispose();
    super.dispose();
  }

  Future<void> _fetchPosts() async {
    setState(() {
      _postsFuture = _postService.fetchPosts(majorFilter: _selectedMajor);
    });
  }

  Future<void> _submitPost(String content) async {
    try {
      final success = await _postService.createPost(content);
      if (success) {
        if (!mounted) return;
        // On success, refresh the feed
        _fetchPosts();
    _notificationsFuture = _notificationService.fetchNotifications();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم نشر المشاركة بنجاح!')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء النشر: \n $e')),
      );
    }
  }

  void _onSendPost() {
    final text = _createPostController.text.trim();
    if (text.isEmpty) return;

    // Unfocus and clear keyboard
    FocusScope.of(context).unfocus();
    _createPostController.clear();

    _submitPost(text);
  }

  void _showNotificationsSheet(BuildContext ctx, bool isDark) {
    // Mark all unread as read via REST
    _notificationService.markAllAsRead();
    // Refresh notifications
    setState(() {
      _notificationsFuture = _notificationService.fetchNotifications();
    });

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        minChildSize: 0.3,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF131724) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF2C3246) : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.notifications_rounded,
                          color: Color(0xFF006B00), size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'الإشعارات',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF003B00),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                    color: isDark
                        ? const Color(0xFF2C3246)
                        : const Color(0xFFE2E8F0)),
                // List streamed live
                Expanded(
                  child: FutureBuilder<List<AppNotification>>(
                    future: _notificationsFuture,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final notifications = snap.data ?? [];
                      if (notifications.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.notifications_off_rounded,
                                  size: 48,
                                  color: isDark
                                      ? const Color(0xFF475569)
                                      : const Color(0xFFCBD5E1)),
                              const SizedBox(height: 12),
                              Text(
                                'لا توجد إشعارات',
                                style: TextStyle(
                                  color: isDark
                                      ? const Color(0xFF64748B)
                                      : const Color(0xFF94A3B8),
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      return ListView.separated(
                        controller: controller,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        itemCount: notifications.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: isDark
                              ? const Color(0xFF003B00)
                              : const Color(0xFFF1F5F9),
                        ),
                        itemBuilder: (_, i) {
                          final notif = notifications[i];
                          final msg = notif.message;
                          final timeStr = notif.timeAgo;
                          final postContent = notif.postContent ?? '';
                          final hasContent = postContent.isNotEmpty;

                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 6),
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color:
                                    const Color(0xFF006B00).withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.info_rounded,
                                  color: Color(0xFF006B00), size: 20),
                            ),
                            title: Text(
                              msg,
                              style: TextStyle(
                                fontSize: 14,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF003B00),
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (timeStr.isNotEmpty)
                                  Text(timeStr,
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? const Color(0xFF64748B)
                                            : const Color(0xFF94A3B8),
                                      )),
                                if (hasContent)
                                  Text(
                                    'اضغط لعرض المنشور',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: const Color(0xFF006B00)
                                          .withValues(alpha: 0.8),
                                    ),
                                  ),
                              ],
                            ),
                            trailing: hasContent
                                ? Icon(Icons.chevron_left_rounded,
                                    color: isDark
                                        ? const Color(0xFF475569)
                                        : const Color(0xFFCBD5E1))
                                : null,
                            onTap: hasContent
                                ? () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => Directionality(
                                        textDirection: TextDirection.rtl,
                                        child: AlertDialog(
                                          backgroundColor: isDark
                                              ? const Color(0xFF1F2536)
                                              : Colors.white,
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(16)),
                                          title: Row(
                                            children: [
                                              const Icon(
                                                  Icons.delete_forever_rounded,
                                                  color: Color(0xFFEF4444),
                                                  size: 22),
                                              const SizedBox(width: 8),
                                              Text(
                                                'المنشور المحذوف',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: isDark
                                                      ? Colors.white
                                                      : const Color(
                                                          0xFF003B00),
                                                ),
                                              ),
                                            ],
                                          ),
                                          content: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Container(
                                                width: double.infinity,
                                                padding:
                                                    const EdgeInsets.all(12),
                                                decoration: BoxDecoration(
                                                  color: isDark
                                                      ? const Color(0xFF131724)
                                                      : const Color(
                                                          0xFFF8FAFC),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: isDark
                                                        ? const Color(
                                                            0xFF003B00)
                                                        : const Color(
                                                            0xFFE2E8F0),
                                                  ),
                                                ),
                                                child: Text(
                                                  postContent,
                                                  textAlign: TextAlign.right,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    height: 1.5,
                                                    color: isDark
                                                        ? const Color(
                                                            0xFFE2E8F0)
                                                        : const Color(
                                                            0xFF004D00),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 10),
                                              Text(
                                                msg,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: isDark
                                                      ? const Color(0xFF94A3B8)
                                                      : const Color(0xFF64748B),
                                                ),
                                              ),
                                            ],
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context),
                                              child: const Text('حسناً',
                                                  style: TextStyle(
                                                      color:
                                                          Color(0xFF006B00))),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                          );

                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(List<Post> currentPosts) {
    showSearch(
      context: context,
      delegate: _PostSearchDelegate(posts: currentPosts, isAdmin: widget.isAdmin),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
            'community_title'.tr(),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: isDark ? Colors.white : const Color(0xFF003B00),
            ),
          ),
          actions: [
            // ── Notification Bell ────────────────────────────────────────
            Builder(builder: (ctx) {
              return FutureBuilder<List<AppNotification>>(
                future: _notificationsFuture,
                builder: (context, snap) {
                  final notifications = snap.data ?? [];
                  final hasUnread = notifications.any((n) => !n.isRead);
                  return Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          tooltip: 'الإشعارات',
                          icon: Icon(
                            hasUnread
                                ? Icons.notifications_rounded
                                : Icons.notifications_none_rounded,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF003B00),
                          ),
                          onPressed: () =>
                              _showNotificationsSheet(ctx, isDark),
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
                },
              );
            }),
            // ── Search ───────────────────────────────────────────────────
            FutureBuilder<List<Post>>(
              future: _postsFuture,
              builder: (context, snapshot) {
                return IconButton(
                  icon: Icon(Icons.search,
                      color: isDark ? Colors.white : const Color(0xFF003B00)),
                  onPressed: () {
                    if (snapshot.hasData) {
                      _showSearchDialog(snapshot.data!);
                    }
                  },
                );
              },
            ),
          ],
          leading: IconButton(
            icon: Icon(Icons.arrow_forward_rounded,
                color: isDark ? Colors.white : const Color(0xFF003B00)),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
        body: RefreshIndicator(
          color: Theme.of(context).primaryColor,
          onRefresh: () async {
            _fetchPosts();
            setState(() {
              _notificationsFuture = _notificationService.fetchNotifications();
            });
          },
          child: Column(
            children: [
              // ── Create Post Row ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.all(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF002200) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? const Color(0xFF003B00) : const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      // Post text field (RTL so on the right)
                      Expanded(
                        child: TextField(
                          controller: _createPostController,
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          onSubmitted: (_) => _onSendPost(),
                          decoration: InputDecoration(
                            hintText: 'community_post_hint'.tr(),
                            hintTextDirection: TextDirection.rtl,
                            hintStyle: TextStyle(
                              fontSize: 14,
                              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                            ),
                            border: InputBorder.none,
                            filled: false,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            suffixIcon: IconButton(
                              icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                              onPressed: _onSendPost,
                            ),
                          ),
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF003B00),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Avatar (left in RTL)
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: isDark ? const Color(0xFF003B00) : const Color(0xFFE8F0FE),
                        child: Text(
                          'م',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // ── Filter Bar ─────────────────────────────────────────────
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _majors.length,
                  itemBuilder: (context, index) {
                    final major = _majors[index];
                    final isSelected = _selectedMajor == major;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(
                          major,
                          style: TextStyle(
                            color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF003B00)),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: Theme.of(context).colorScheme.primary,
                        backgroundColor: isDark ? const Color(0xFF002200) : Colors.grey[200],
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _selectedMajor = major;
                            });
                            _fetchPosts();
    _notificationsFuture = _notificationService.fetchNotifications();
                          }
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              
              // ── Posts List ─────────────────────────────────────────────
              Expanded(
                child: FutureBuilder<List<Post>>(
                  future: _postsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                          strokeWidth: 2,
                        ),
                      );
                    } else if (snapshot.hasError) {
                      return ListView( // Wrap in ListView so RefreshIndicator still works
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Text(
                                'عذراً، حدث خطأ في تحميل المنشورات.\n ${snapshot.error}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Color(0xFFEF4444)),
                              ),
                            ),
                          ),
                        ],
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.5,
                            child: Center(
                              child: Text(
                                'community_no_posts'.tr(),
                                style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ],
                      );
                    }

                    final posts = snapshot.data!;
                    return ListView.builder(
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        return PostCard(post: posts[index], isAdmin: widget.isAdmin);
                      },
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

// Simple search delegate for posts
class _PostSearchDelegate extends SearchDelegate<String> {
  final List<Post> posts;
  final bool isAdmin;
  _PostSearchDelegate({required this.posts, required this.isAdmin});

  @override
  String? get searchFieldLabel => 'ابحث في المنشورات...';

  @override
  Widget buildLeading(BuildContext context) {
    // Determine the theme dynamically to set colors
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return IconButton(
      icon: Icon(Icons.arrow_forward, color: isDark ? Colors.white : const Color(0xFF003B00)),
      onPressed: () => close(context, ''),
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return [
      IconButton(
        icon: Icon(Icons.clear, color: isDark ? Colors.white : const Color(0xFF003B00)),
        onPressed: () => query = '',
      ),
    ];
  }

  @override
  ThemeData appBarTheme(BuildContext context) {
    // Inherit the theme and modify app bar theme colors for the search page
    final ThemeData theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return theme.copyWith(
      appBarTheme: theme.appBarTheme.copyWith(
        backgroundColor: theme.appBarTheme.backgroundColor,
        iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF003B00)),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
      ),
    );
  }

  @override
  Widget buildResults(BuildContext context) => _buildList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _buildList(context);

  Widget _buildList(BuildContext context) {
    final filtered = posts
        .where((p) => p.content.contains(query) || p.authorName.contains(query))
        .toList();
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: filtered.length,
          itemBuilder: (_, i) => PostCard(post: filtered[i], isAdmin: isAdmin),
        ),
      ),
    );
  }
}




