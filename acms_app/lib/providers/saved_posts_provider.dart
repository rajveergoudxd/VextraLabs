import 'package:flutter/material.dart';
import 'package:acms_app/services/post_service.dart';

class SavedPostsProvider extends ChangeNotifier {
  final PostService _postService = PostService();

  List<dynamic> _savedPosts = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;

  List<dynamic> get savedPosts => _savedPosts;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;

  /// Load saved posts with pagination
  Future<void> loadSavedPosts({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      _hasMore = true;
      _savedPosts = [];
      _error = null;
    }

    if (!_hasMore || (_isLoading && !refresh)) return;

    _isLoading = true;
    notifyListeners();

    try {
      final data = await _postService.getSavedPosts(page: _currentPage);
      final newPosts = data['items'] as List;
      final total = data['total'] as int;

      if (refresh) {
        _savedPosts = newPosts;
      } else {
        _savedPosts.addAll(newPosts);
      }

      _hasMore = _savedPosts.length < total;
      if (_hasMore) _currentPage++;
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if a post is saved (by looking through local cache)
  bool isPostSaved(int postId) {
    return _savedPosts.any((post) => post['id'] == postId);
  }

  /// Add a post to local cached saved posts
  void addToSavedPosts(Map<String, dynamic> post) {
    if (!isPostSaved(post['id'])) {
      _savedPosts.insert(0, post);
      notifyListeners();
    }
  }

  /// Remove a post from local cached saved posts
  void removeFromSavedPosts(int postId) {
    _savedPosts.removeWhere((post) => post['id'] == postId);
    notifyListeners();
  }

  /// Clear all saved posts (for logout)
  void clear() {
    _savedPosts = [];
    _currentPage = 1;
    _hasMore = true;
    _error = null;
    notifyListeners();
  }
}
