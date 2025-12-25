import 'package:flutter/material.dart';
import 'package:acms_app/services/post_service.dart';

class InspireProvider extends ChangeNotifier {
  final PostService _postService = PostService();

  List<dynamic> _posts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  List<dynamic> get posts => _posts;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  Future<void> loadFeed({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _posts = [];
      _error = null;
    }

    if (!_hasMore || (_isLoading && !refresh)) return;

    _isLoading = true;
    notifyListeners();

    try {
      final data = await _postService.getFeed(page: _currentPage);
      final newPosts = data['items'] as List;
      final total = data['total'] as int;

      if (refresh) {
        _posts = newPosts;
      } else {
        _posts.addAll(newPosts);
      }

      _hasMore = _posts.length < total;
      if (_hasMore) _currentPage++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle like on a post
  Future<void> likePost(int postId) async {
    final index = _posts.indexWhere((p) => p['id'] == postId);
    if (index == -1) return;

    // Get current state
    final currentLiked = _posts[index]['is_liked'] == true;
    final currentCount = _posts[index]['likes_count'] ?? 0;

    // Optimistic update: toggle the like state
    _posts[index]['is_liked'] = !currentLiked;
    _posts[index]['likes_count'] = currentLiked
        ? currentCount - 1
        : currentCount + 1;
    notifyListeners();

    try {
      final response = await _postService.toggleLike(postId);
      // Update with server response to ensure consistency
      _posts[index]['is_liked'] = response['is_liked'];
      _posts[index]['likes_count'] = response['likes_count'];
      notifyListeners();
    } catch (e) {
      // Revert on failure
      _posts[index]['is_liked'] = currentLiked;
      _posts[index]['likes_count'] = currentCount;
      notifyListeners();
      debugPrint('Failed to toggle like: $e');
    }
  }

  /// Add a comment to a post (optimistic update for count)
  Future<Map<String, dynamic>?> addComment(int postId, String content) async {
    final index = _posts.indexWhere((p) => p['id'] == postId);

    try {
      final comment = await _postService.addComment(postId, content);

      // Update comment count
      if (index != -1) {
        _posts[index]['comments_count'] =
            (_posts[index]['comments_count'] ?? 0) + 1;
        notifyListeners();
      }

      return comment;
    } catch (e) {
      debugPrint('Failed to add comment: $e');
      rethrow;
    }
  }

  /// Delete a comment
  Future<void> deleteComment(int postId, int commentId) async {
    final index = _posts.indexWhere((p) => p['id'] == postId);

    try {
      await _postService.deleteComment(commentId);

      // Update comment count
      if (index != -1) {
        _posts[index]['comments_count'] =
            ((_posts[index]['comments_count'] ?? 1) - 1)
                .clamp(0, double.infinity)
                .toInt();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to delete comment: $e');
      rethrow;
    }
  }

  /// Get comments for a post
  Future<Map<String, dynamic>> getComments(
    int postId, {
    int skip = 0,
    int limit = 50,
  }) async {
    return await _postService.getComments(postId, skip: skip, limit: limit);
  }

  /// Get share link for a post
  Future<Map<String, dynamic>> getShareLink(int postId) async {
    return await _postService.getShareLink(postId);
  }

  /// Save a post (bookmark)
  Future<void> savePost(int postId) async {
    final index = _posts.indexWhere((p) => p['id'] == postId);
    if (index == -1) return;

    // Optimistic update
    _posts[index]['is_saved'] = true;
    notifyListeners();

    try {
      await _postService.savePost(postId);
    } catch (e) {
      // Revert on failure
      _posts[index]['is_saved'] = false;
      notifyListeners();
      debugPrint('Failed to save post: $e');
    }
  }

  /// Unsave a post (remove bookmark)
  Future<void> unsavePost(int postId) async {
    final index = _posts.indexWhere((p) => p['id'] == postId);
    if (index == -1) return;

    // Optimistic update
    _posts[index]['is_saved'] = false;
    notifyListeners();

    try {
      await _postService.unsavePost(postId);
    } catch (e) {
      // Revert on failure
      _posts[index]['is_saved'] = true;
      notifyListeners();
      debugPrint('Failed to unsave post: $e');
    }
  }

  /// Toggle save/unsave on a post
  Future<void> toggleSavePost(int postId) async {
    final index = _posts.indexWhere((p) => p['id'] == postId);
    if (index == -1) return;

    final isSaved = _posts[index]['is_saved'] == true;
    if (isSaved) {
      await unsavePost(postId);
    } else {
      await savePost(postId);
    }
  }
}
