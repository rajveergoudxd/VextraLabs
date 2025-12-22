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

  Future<void> likePost(int postId) async {
    // Optimistic update
    final index = _posts.indexWhere((p) => p['id'] == postId);
    if (index != -1) {
      // In a real app we'd check if already liked and toggle
      // Here we just increment as per the simplistic API
      _posts[index]['likes_count'] += 1;
      // _posts[index]['is_liked'] = true; // If API supported it
      notifyListeners();
    }

    try {
      await _postService.likePost(postId);
    } catch (e) {
      // Revert if failed
      if (index != -1) {
        _posts[index]['likes_count'] -= 1;
        notifyListeners();
      }
    }
  }
}
