import 'package:flutter/material.dart';
import '../models/post_model.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

import '../services/post_service.dart';
import '../screens/profile_screen.dart';

class PostCard extends StatefulWidget {
  final Post post;
  final bool isAdmin;
  /// Callback to notify parent of votes, or we can just handle the mock logic here
  const PostCard({super.key, required this.post, this.isAdmin = false});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  late int _upvotes;
  late bool _upvoted;
  late bool _downvoted;

  @override
  void initState() {
    super.initState();
    _upvotes = widget.post.upvotes;
    final currentUserId = authService.currentUserId ?? '';
    _upvoted = widget.post.upvotedBy.contains(currentUserId);
    _downvoted = widget.post.downvotedBy.contains(currentUserId);
  }

  void _onUpvote() async {
    setState(() {
      if (_upvoted) {
        _upvotes--;
        _upvoted = false;
      } else {
        if (_downvoted) {
          _upvotes++;
          _downvoted = false;
        }
        _upvotes++;
        _upvoted = true;
      }
    });
    await PostService().toggleUpvote(widget.post.id);
  }

  void _onDownvote() async {
    setState(() {
      if (_downvoted) {
        _upvotes++;
        _downvoted = false;
      } else {
        if (_upvoted) {
          _upvotes--;
          _upvoted = false;
        }
        _upvotes--;
        _downvoted = true;
      }
    });
    await PostService().toggleDownvote(widget.post.id);
  }

  void _onComment() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.4,
          maxChildSize: 0.9,
          builder: (_, controller) {
            return Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF161E31) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: _CommentsSheet(postId: widget.post.id, scrollController: controller, isDark: isDark, isAdmin: widget.isAdmin),
              ),
            );
          },
        );
      },
    );
  }

  void _onShare() {
    SharePlus.instance.share(ShareParams(text: widget.post.content));
  }

  void _onProfileTap() {
    if (widget.post.authorId.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileScreen(userId: widget.post.authorId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Generate simple initials from authorName
    String initials = "؟";
    if (post.authorName.isNotEmpty) {
      final parts = post.authorName.trim().split(" ");
      if (parts.length > 1) {
        initials = '${parts[0][0]}${parts[1][0]}';
      } else {
        initials = parts[0][0];
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161E31) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
            child: Row(
              children: [
                // Avatar wrapped in GestureDetector
                GestureDetector(
                  onTap: _onProfileTap,
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F0FE),
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                // Name & role
                Expanded(
                  child: GestureDetector(
                    onTap: _onProfileTap,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          post.authorName,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          '${post.timeAgo} • ${post.authorMajor}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          textAlign: TextAlign.right,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_horiz, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  onSelected: (value) async {
                    if (value == 'copy') {
                      Clipboard.setData(ClipboardData(text: post.content));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('تم نسخ النص بنجاح')),
                      );
                    } else if (value == 'delete') {
                      try {
                        await PostService().deletePost(widget.post.id);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم حذف المنشور')),
                          );
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('فشل في الحذف: $e')),
                          );
                        }
                      }
                    } else if (value == 'report') {
                      showDialog(
                        context: context,
                        builder: (ctx) => Directionality(
                          textDirection: TextDirection.rtl,
                          child: AlertDialog(
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                            title: const Text('إبلاغ', textAlign: TextAlign.right),
                            content: const Text('هل أنت متأكد من الإبلاغ عن هذا المنشور؟', textAlign: TextAlign.right),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: const Text('إلغاء'),
                              ),
                              TextButton(
                                onPressed: () async {
                                  Navigator.pop(ctx);
                                  try {
                                    final postIdInt = int.tryParse(post.id);
                                    await apiService.post('reports/', {
                                      if (postIdInt != null) 'reported_post': postIdInt,
                                      'reason': post.content,
                                    });

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('تم إرسال البلاغ للإدارة بنجاح')),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('حدث خطأ: $e')),
                                      );
                                    }
                                  }
                                },
                                child: const Text('تأكيد'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                  itemBuilder: (context) {
                    final isDarkInner = Theme.of(context).brightness == Brightness.dark;
                    final currentUserId = authService.currentUserId;
                    final isOwnerOrAdmin = widget.isAdmin || (currentUserId != null && widget.post.authorId == currentUserId);
                    return [
                      PopupMenuItem(
                        value: 'copy',
                        child: Text('نسخ النص', style: TextStyle(color: isDarkInner ? Colors.white : const Color(0xFF1E293B))),
                      ),
                      if (isOwnerOrAdmin)
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('حذف', style: TextStyle(color: Colors.red)),
                        )
                      else
                        PopupMenuItem(
                          value: 'report',
                          child: Text('إبلاغ', style: TextStyle(color: isDarkInner ? Colors.white : const Color(0xFF1E293B))),
                        ),
                    ];
                  },
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                ),
              ],
            ),
          ),

          // ── Post Text ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  post.content,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // ── Image ────────────────────────────────────────────────────────
          if (post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.zero),
                child: Image.network(
                  post.imageUrl!,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 140,
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F0FE),
                    child: Center(
                        child:
                            Icon(Icons.image, color: Theme.of(context).primaryColor, size: 40)),
                  ),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Container(
                      height: 140,
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F0FE),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // ── Footer ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
            child: Row(
              children: [
                // Share
                _FooterBtn(
                  icon: Icons.share_outlined,
                  label: 'مشاركة',
                  onTap: _onShare,
                  isDark: isDark,
                ),
                const Spacer(),
                // Comments
                _FooterBtn(
                  icon: Icons.chat_bubble_outline,
                  label: '${post.commentsCount}',
                  onTap: _onComment,
                  isDark: isDark,
                ),
                const SizedBox(width: 16),
                // Downvote
                GestureDetector(
                  onTap: _onDownvote,
                  child: Icon(
                    Icons.arrow_downward_rounded,
                    color:
                        _downvoted ? const Color(0xFFEF4444) : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  _upvotes.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(width: 6),
                // Upvote
                GestureDetector(
                  onTap: _onUpvote,
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color:
                        _upvoted ? const Color(0xFF10B981) : (isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDark;

  const _FooterBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final String postId;
  final ScrollController scrollController;
  final bool isDark;
  final bool isAdmin;

  const _CommentsSheet({
    required this.postId,
    required this.scrollController,
    required this.isDark,
    this.isAdmin = false,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _commentController = TextEditingController();
  final PostService _postService = PostService();

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    FocusScope.of(context).unfocus();
    _commentController.clear();

    try {
      await _postService.addComment(widget.postId, text);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ: $e')),
      );
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;

    return Column(
      children: [
        const SizedBox(height: 12),
        Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        Text('التعليقات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : const Color(0xFF1E293B))),
        Divider(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
        Expanded(
          child: FutureBuilder<List<PostComment>>(
            future: PostService().getComments(widget.postId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor));
              }
              if (snapshot.hasError) {
                return Center(child: Text('حدث خطأ في جلب التعليقات', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B))));
              }
              final docs = snapshot.data ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Text('لا توجد تعليقات، كن أول من يعلق!', style: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
                );
              }

              return ListView.builder(
                controller: widget.scrollController,
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final comment = docs[index];
                  final content = comment.content;
                  final commentUserId = comment.authorId;
                  final isOwnerOrAdmin = widget.isAdmin || commentUserId == authService.currentUserId;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE8F0FE),
                      child: Icon(Icons.person, color: Theme.of(context).primaryColor),
                    ),
                    title: Text(content, style: TextStyle(color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B))),
                    trailing: PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      onSelected: (value) async {
                        if (value == 'delete') {
                           await PostService().deleteComment(comment.id);
                           if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حذف التعليق')));
                           }
                        } else if (value == 'report') {
                           if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الإبلاغ عن التعليق')));
                           }
                        }
                      },
                      itemBuilder: (context) {
                        return [
                          if (isOwnerOrAdmin)
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('حذف', style: TextStyle(color: Colors.red)),
                            )
                          else
                            PopupMenuItem(
                              value: 'report',
                              child: Text('إبلاغ', style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B))),
                            ),
                        ];
                      },
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    ),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(color: isDark ? Colors.white : const Color(0xFF1E293B)),
                  decoration: InputDecoration(
                    hintText: 'أضف تعليقاً...',
                    hintTextDirection: TextDirection.rtl,
                    hintStyle: TextStyle(color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(20),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                    ),
                    filled: true,
                    fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  onSubmitted: (_) => _submitComment(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: Icon(Icons.send, color: Theme.of(context).primaryColor),
                onPressed: _submitComment,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
