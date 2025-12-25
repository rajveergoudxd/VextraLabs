import 'package:dio/dio.dart';
import 'package:acms_app/services/api_client.dart';
import 'dart:io';

class PostService {
  final ApiClient _client = ApiClient();

  /// Upload a media file to cloud storage and return the URL
  Future<String> uploadMedia(String localPath) async {
    try {
      final file = File(localPath.replaceFirst('file://', ''));
      if (!await file.exists()) {
        throw 'File not found: $localPath';
      }

      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _client.dio.post('/upload/', data: formData);
      return response.data['url'];
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to upload media';
    } catch (e) {
      throw 'Failed to upload media: $e';
    }
  }

  /// Upload multiple media files and return their URLs
  Future<List<String>> uploadMultipleMedia(List<String> localPaths) async {
    final urls = <String>[];
    for (final path in localPaths) {
      // Skip if already a URL
      if (path.startsWith('http://') || path.startsWith('https://')) {
        urls.add(path);
      } else {
        // Upload local file
        final url = await uploadMedia(path);
        urls.add(url);
      }
    }
    return urls;
  }

  Future<Map<String, dynamic>> publishPost({
    required String content,
    List<String>? mediaUrls,
    required List<String> platforms,
  }) async {
    try {
      final response = await _client.dio.post(
        '/publish/',
        data: {
          'content': content,
          'media_urls': mediaUrls ?? [],
          'platforms': platforms,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to publish post';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  Future<Map<String, dynamic>> getFeed({int page = 1, int size = 20}) async {
    try {
      final response = await _client.dio.get(
        '/posts/feed',
        queryParameters: {'page': page, 'size': size},
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to fetch feed';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  /// Get posts for a specific user
  Future<Map<String, dynamic>> getUserPosts(
    int userId, {
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _client.dio.get(
        '/posts/user/$userId',
        queryParameters: {'page': page, 'size': size},
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to fetch user posts';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  /// Get current user's published posts
  Future<Map<String, dynamic>> getMyPosts({int page = 1, int size = 20}) async {
    try {
      final response = await _client.dio.get(
        '/posts/my',
        queryParameters: {'page': page, 'size': size},
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to fetch my posts';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  /// Toggle like on a post. Returns { is_liked, likes_count, message }
  Future<Map<String, dynamic>> toggleLike(int postId) async {
    try {
      final response = await _client.dio.post('/posts/$postId/like');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to toggle like';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  /// Get users who liked a post
  Future<Map<String, dynamic>> getPostLikes(
    int postId, {
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final response = await _client.dio.get(
        '/posts/$postId/likes',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to fetch likes';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  // ============== Comment Methods ==============

  /// Get comments for a post
  Future<Map<String, dynamic>> getComments(
    int postId, {
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final response = await _client.dio.get(
        '/posts/$postId/comments',
        queryParameters: {'skip': skip, 'limit': limit},
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to fetch comments';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  /// Add a comment to a post
  Future<Map<String, dynamic>> addComment(int postId, String content) async {
    try {
      final response = await _client.dio.post(
        '/posts/$postId/comments',
        data: {'content': content},
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to add comment';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  /// Delete a comment
  Future<void> deleteComment(int commentId) async {
    try {
      await _client.dio.delete('/posts/comments/$commentId');
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to delete comment';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  // ============== Share Methods ==============

  /// Get shareable link for a post
  Future<Map<String, dynamic>> getShareLink(int postId) async {
    try {
      final response = await _client.dio.get('/posts/$postId/share-link');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to get share link';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  /// Get post by share token (for deep links)
  Future<Map<String, dynamic>> getPostByShareToken(String shareToken) async {
    try {
      final response = await _client.dio.get('/posts/shared/$shareToken');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to fetch shared post';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  // ============== Saved Posts Methods ==============

  /// Save a post to user's collection
  Future<Map<String, dynamic>> savePost(int postId) async {
    try {
      final response = await _client.dio.post('/posts/saved/$postId');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to save post';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  /// Remove a post from user's saved collection
  Future<Map<String, dynamic>> unsavePost(int postId) async {
    try {
      final response = await _client.dio.delete('/posts/saved/$postId');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to unsave post';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  /// Get all saved posts with pagination
  Future<Map<String, dynamic>> getSavedPosts({
    int page = 1,
    int size = 20,
  }) async {
    try {
      final response = await _client.dio.get(
        '/posts/saved',
        queryParameters: {'page': page, 'size': size},
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to fetch saved posts';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  // ============== Draft Methods ==============

  /// Save media and content as a draft
  Future<Map<String, dynamic>> saveDraft({
    String? content,
    List<String>? mediaUrls,
    List<String>? platforms,
    String? title,
  }) async {
    try {
      final response = await _client.dio.post(
        '/posts/drafts',
        data: {
          'content': content,
          'media_urls': mediaUrls ?? [],
          'platforms': platforms ?? ['inspire'],
          'title': title ?? 'Untitled Draft',
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to save draft';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  /// Get all user's drafts
  Future<Map<String, dynamic>> getDrafts() async {
    try {
      final response = await _client.dio.get('/posts/drafts');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to fetch drafts';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  /// Get a specific draft by ID
  Future<Map<String, dynamic>> getDraft(int draftId) async {
    try {
      final response = await _client.dio.get('/posts/drafts/$draftId');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to fetch draft';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  /// Update an existing draft
  Future<Map<String, dynamic>> updateDraft(
    int draftId, {
    String? content,
    List<String>? mediaUrls,
    List<String>? platforms,
    String? title,
  }) async {
    try {
      final response = await _client.dio.put(
        '/posts/drafts/$draftId',
        data: {
          if (content != null) 'content': content,
          if (mediaUrls != null) 'media_urls': mediaUrls,
          if (platforms != null) 'platforms': platforms,
          if (title != null) 'title': title,
        },
      );
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to update draft';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  /// Delete a draft
  Future<void> deleteDraft(int draftId) async {
    try {
      await _client.dio.delete('/posts/drafts/$draftId');
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to delete draft';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }

  /// Publish a draft (convert to published post)
  Future<Map<String, dynamic>> publishDraft(int draftId) async {
    try {
      final response = await _client.dio.post('/posts/drafts/$draftId/publish');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to publish draft';
    } catch (e) {
      throw 'An unexpected error occurred';
    }
  }
}
