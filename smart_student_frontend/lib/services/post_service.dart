import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/post_model.dart';
import 'api_service.dart';


class PostService {
  Future<List<Post>> fetchPosts({String? majorFilter}) async {
    try {
      final response = await apiService.get('posts/');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<Post> posts = data.map((json) => Post.fromJson(json)).toList();
        
        if (majorFilter != null && majorFilter != 'الكل') {
          posts = posts.where((p) => p.authorMajor == majorFilter).toList();
        }
        return posts;
      } else {
        throw Exception('Failed to load posts');
      }
    } catch (e) {
      debugPrint('Error fetching posts: $e');
      throw Exception('فشل في جلب المنشورات: $e');
    }
  }

  Future<List<Post>> fetchMyPosts() async {
    try {
      final response = await apiService.get('posts/me/');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Post.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load my posts');
      }
    } catch (e) {
      debugPrint('Error fetching my posts: $e');
      throw Exception('فشل في جلب منشوراتي: $e');
    }
  }

  Future<bool> createPost(String content) async {
    try {
      final response = await apiService.post('posts/', {
        'content': content,
      });
      return response.statusCode == 201;
    } catch (e) {
      debugPrint('Error creating post: $e');
      throw Exception('فشل في إنشاء المنشور');
    }
  }

  Future<void> addComment(String postId, String content) async {
    try {
      await apiService.post('posts/$postId/comments/', {'content': content});
    } catch (e) {
      debugPrint('Error adding comment: $e');
      throw Exception('فشل في إضافة التعليق');
    }
  }

  Future<List<PostComment>> getComments(String postId) async {
    try {
      final response = await apiService.get('posts/$postId/comments/');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => PostComment.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load comments');
      }
    } catch (e) {
      debugPrint('Error fetching comments: $e');
      throw Exception('فشل في جلب التعليقات: $e');
    }
  }

  Future<void> toggleUpvote(String postId) async {
    await apiService.post('posts/$postId/upvote/', {});
  }

  Future<void> toggleDownvote(String postId) async {
    await apiService.post('posts/$postId/downvote/', {});
  }

  Future<void> toggleCommentUpvote(String commentId) async {
    await apiService.post('comments/$commentId/upvote/', {});
  }

  Future<void> toggleCommentDownvote(String commentId) async {
    await apiService.post('comments/$commentId/downvote/', {});
  }

  Future<void> deleteComment(String commentId) async {
    try {
      await apiService.delete('comments/$commentId/');
    } catch (e) {
      debugPrint('Error deleting comment: $e');
      throw Exception('فشل في حذف التعليق');
    }
  }

  Future<void> deletePost(String postId) async {
    try {
      await apiService.delete('posts/$postId/');
    } catch (e) {
      debugPrint('Error deleting post: $e');
      throw Exception('فشل في حذف المنشور');
    }
  }
}
