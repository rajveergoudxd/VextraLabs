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

  Future<Map<String, dynamic>> likePost(int postId) async {
    try {
      final response = await _client.dio.post('/posts/$postId/like');
      return response.data;
    } on DioException catch (e) {
      throw e.response?.data['detail'] ?? 'Failed to like post';
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
