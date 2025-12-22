import 'package:dio/dio.dart';
import 'package:acms_app/services/api_client.dart';

class PostService {
  final ApiClient _client = ApiClient();

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
}
