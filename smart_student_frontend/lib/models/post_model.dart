class Post {
  final String id;
  final String authorName;
  final String authorMajor;
  final String authorId;
  final String timeAgo;
  final String content;
  final String? imageUrl;
  int upvotes;
  int commentsCount;
  List<String> upvotedBy;
  List<String> downvotedBy;

  Post({
    required this.id,
    required this.authorName,
    required this.authorId,
    required this.authorMajor,
    required this.timeAgo,
    required this.content,
    this.imageUrl,
    this.upvotes = 0,
    this.commentsCount = 0,
    this.upvotedBy = const [],
    this.downvotedBy = const [],
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id']?.toString() ?? '',
      authorId: json['author']?.toString() ?? '',
      authorName: json['author_name'] ?? 'مستخدم مجهول',
      authorMajor: json['author_major'] ?? 'عام',
      timeAgo: _formatDateString(json['timestamp']),
      content: json['content'] ?? '',
      imageUrl: json['image_url'],
      upvotes: json['upvotes'] ?? 0,
      commentsCount: json['comments_count'] ?? 0,
      upvotedBy: List<String>.from((json['upvoted_by'] ?? []).map((x) => x.toString())),
      downvotedBy: List<String>.from((json['downvoted_by'] ?? []).map((x) => x.toString())),
    );
  }

  static String _formatDateString(String? dateStr) {
    if (dateStr == null) return 'الآن';
    try {
      final date = DateTime.parse(dateStr).toLocal();
      final now = DateTime.now();
      final difference = now.difference(date);
      if (difference.inDays > 0) return 'منذ ${difference.inDays} أيام';
      if (difference.inHours > 0) return 'منذ ${difference.inHours} ساعات';
      if (difference.inMinutes > 0) return 'منذ ${difference.inMinutes} دقائق';
      return 'الآن';
    } catch (e) {
      return 'الآن';
    }
  }
}

class PostComment {
  final String authorId;
  final String id;
  final String authorName;
  final String content;
  final String timeAgo;
  final int upvotes;
  final List<String> upvotedBy;
  final List<String> downvotedBy;

  PostComment({
    required this.id,
    required this.authorName,
    required this.authorId,
    required this.content,
    required this.timeAgo,
    this.upvotes = 0,
    this.upvotedBy = const [],
    this.downvotedBy = const [],
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id']?.toString() ?? '',
      authorId: json['author']?.toString() ?? '',
      authorName: json['author_name'] ?? 'مستخدم مجهول',
      content: json['content'] ?? '',
      timeAgo: Post._formatDateString(json['timestamp']),
      upvotes: json['upvotes'] ?? 0,
      upvotedBy: List<String>.from((json['upvoted_by'] ?? []).map((x) => x.toString())),
      downvotedBy: List<String>.from((json['downvoted_by'] ?? []).map((x) => x.toString())),
    );
  }
}
