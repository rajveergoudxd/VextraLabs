import 'package:flutter/foundation.dart';
import 'package:acms_app/services/social_service.dart';

/// Model for a user in search results or followers/following lists
class UserSearchResult {
  final int id;
  final String? username;
  final String? fullName;
  final String? bio;
  final String? profilePicture;
  final int followersCount;
  final bool isFollowing;

  UserSearchResult({
    required this.id,
    this.username,
    this.fullName,
    this.bio,
    this.profilePicture,
    this.followersCount = 0,
    this.isFollowing = false,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> json) {
    return UserSearchResult(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'],
      bio: json['bio'],
      profilePicture: json['profile_picture'],
      followersCount: json['followers_count'] ?? 0,
      isFollowing: json['is_following'] ?? false,
    );
  }

  UserSearchResult copyWith({bool? isFollowing}) {
    return UserSearchResult(
      id: id,
      username: username,
      fullName: fullName,
      bio: bio,
      profilePicture: profilePicture,
      followersCount: followersCount,
      isFollowing: isFollowing ?? this.isFollowing,
    );
  }
}

/// Model for a public user profile
class PublicProfile {
  final int id;
  final String? username;
  final String? fullName;
  final String? bio;
  final String? profilePicture;
  final int postsCount;
  final int followersCount;
  final int followingCount;
  final bool isFollowing;
  final bool isFollowedBy;

  PublicProfile({
    required this.id,
    this.username,
    this.fullName,
    this.bio,
    this.profilePicture,
    this.postsCount = 0,
    this.followersCount = 0,
    this.followingCount = 0,
    this.isFollowing = false,
    this.isFollowedBy = false,
  });

  factory PublicProfile.fromJson(Map<String, dynamic> json) {
    return PublicProfile(
      id: json['id'],
      username: json['username'],
      fullName: json['full_name'],
      bio: json['bio'],
      profilePicture: json['profile_picture'],
      postsCount: json['posts_count'] ?? 0,
      followersCount: json['followers_count'] ?? 0,
      followingCount: json['following_count'] ?? 0,
      isFollowing: json['is_following'] ?? false,
      isFollowedBy: json['is_followed_by'] ?? false,
    );
  }

  PublicProfile copyWith({bool? isFollowing, int? followersCount}) {
    return PublicProfile(
      id: id,
      username: username,
      fullName: fullName,
      bio: bio,
      profilePicture: profilePicture,
      postsCount: postsCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollowedBy: isFollowedBy,
    );
  }
}

/// Provider for social features: user search and follow system
class SocialProvider extends ChangeNotifier {
  final SocialService _socialService = SocialService();

  // Search state
  List<UserSearchResult> _searchResults = [];
  bool _isSearching = false;
  String _searchQuery = '';
  String? _searchError;

  // Profile state
  PublicProfile? _currentProfile;
  bool _isLoadingProfile = false;
  String? _profileError;

  // Action state
  bool _isFollowActionLoading = false;

  // Followers/Following list state
  List<UserSearchResult> _followers = [];
  List<UserSearchResult> _following = [];
  bool _isLoadingFollowList = false;
  String? _followListError;
  int _followersTotal = 0;
  int _followingTotal = 0;

  // Getters
  List<UserSearchResult> get searchResults => _searchResults;
  bool get isSearching => _isSearching;
  String get searchQuery => _searchQuery;
  String? get searchError => _searchError;

  PublicProfile? get currentProfile => _currentProfile;
  bool get isLoadingProfile => _isLoadingProfile;
  String? get profileError => _profileError;

  bool get isFollowActionLoading => _isFollowActionLoading;

  // Followers/Following list getters
  List<UserSearchResult> get followers => _followers;
  List<UserSearchResult> get following => _following;
  bool get isLoadingFollowList => _isLoadingFollowList;
  String? get followListError => _followListError;
  int get followersTotal => _followersTotal;
  int get followingTotal => _followingTotal;

  /// Search users by username or full name
  Future<void> searchUsers(String query) async {
    if (query.length < 2) {
      _searchResults = [];
      _searchQuery = query;
      notifyListeners();
      return;
    }

    _isSearching = true;
    _searchQuery = query;
    _searchError = null;
    notifyListeners();

    try {
      final response = await _socialService.searchUsers(query);
      final results = (response['results'] as List)
          .map((json) => UserSearchResult.fromJson(json))
          .toList();
      _searchResults = results;
    } catch (e) {
      _searchError = 'Failed to search users';
      debugPrint('Search error: $e');
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  /// Clear search results
  void clearSearch() {
    _searchResults = [];
    _searchQuery = '';
    _searchError = null;
    notifyListeners();
  }

  /// Load public profile by username
  Future<void> loadProfile(String username) async {
    _isLoadingProfile = true;
    _profileError = null;
    _currentProfile = null;
    notifyListeners();

    try {
      final response = await _socialService.getPublicProfile(username);
      _currentProfile = PublicProfile.fromJson(response);
    } catch (e) {
      _profileError = 'Failed to load profile';
      debugPrint('Profile load error: $e');
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  /// Load public profile by user ID
  Future<void> loadProfileById(int userId) async {
    debugPrint('=== loadProfileById called with userId: $userId ===');
    _isLoadingProfile = true;
    _profileError = null;
    _currentProfile = null;
    notifyListeners();

    try {
      debugPrint('Calling API: /social/profile-by-id/$userId');
      final response = await _socialService.getPublicProfileById(userId);
      debugPrint('API Response received: $response');
      _currentProfile = PublicProfile.fromJson(response);
      debugPrint('Profile parsed successfully: ${_currentProfile?.username}');
    } catch (e, stackTrace) {
      _profileError = 'Failed to load profile';
      debugPrint('=== Profile load error ===');
      debugPrint('Error type: ${e.runtimeType}');
      debugPrint('Error: $e');
      debugPrint('Stack trace: $stackTrace');
      // Try to extract more details if it's a DioException
      if (e.toString().contains('DioException')) {
        debugPrint('DioException detected - check network/API response');
      }
    } finally {
      _isLoadingProfile = false;
      notifyListeners();
    }
  }

  /// Follow a user
  Future<bool> followUser(int userId) async {
    _isFollowActionLoading = true;
    notifyListeners();

    try {
      await _socialService.followUser(userId);

      // Update search results if user is in there
      _searchResults = _searchResults.map((user) {
        if (user.id == userId) {
          return user.copyWith(isFollowing: true);
        }
        return user;
      }).toList();

      // Update current profile if viewing this user
      if (_currentProfile?.id == userId) {
        _currentProfile = _currentProfile!.copyWith(
          isFollowing: true,
          followersCount: _currentProfile!.followersCount + 1,
        );
      }

      // Update followers/following lists
      _updateFollowStatusInLists(userId, true);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Follow error: $e');
      return false;
    } finally {
      _isFollowActionLoading = false;
      notifyListeners();
    }
  }

  /// Unfollow a user
  Future<bool> unfollowUser(int userId) async {
    _isFollowActionLoading = true;
    notifyListeners();

    try {
      await _socialService.unfollowUser(userId);

      // Update search results
      _searchResults = _searchResults.map((user) {
        if (user.id == userId) {
          return user.copyWith(isFollowing: false);
        }
        return user;
      }).toList();

      // Update current profile
      if (_currentProfile?.id == userId) {
        _currentProfile = _currentProfile!.copyWith(
          isFollowing: false,
          followersCount: (_currentProfile!.followersCount - 1).clamp(
            0,
            999999,
          ),
        );
      }

      // Update followers/following lists
      _updateFollowStatusInLists(userId, false);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Unfollow error: $e');
      return false;
    } finally {
      _isFollowActionLoading = false;
      notifyListeners();
    }
  }

  /// Toggle follow status
  Future<bool> toggleFollow(int userId, bool currentlyFollowing) async {
    if (currentlyFollowing) {
      return unfollowUser(userId);
    } else {
      return followUser(userId);
    }
  }

  /// Load followers list for a user
  Future<void> loadFollowers(int userId) async {
    _isLoadingFollowList = true;
    _followListError = null;
    notifyListeners();

    try {
      final response = await _socialService.getFollowers(userId);
      final list = (response['followers'] as List)
          .map(
            (json) => UserSearchResult(
              id: json['id'],
              username: json['username'],
              fullName: json['full_name'],
              profilePicture: json['profile_picture'],
              isFollowing: json['is_following'] ?? false,
            ),
          )
          .toList();
      _followers = list;
      _followersTotal = response['total'] ?? list.length;
    } catch (e) {
      _followListError = 'Failed to load followers';
      debugPrint('Load followers error: $e');
    } finally {
      _isLoadingFollowList = false;
      notifyListeners();
    }
  }

  /// Load following list for a user
  Future<void> loadFollowing(int userId) async {
    _isLoadingFollowList = true;
    _followListError = null;
    notifyListeners();

    try {
      final response = await _socialService.getFollowing(userId);
      final list = (response['following'] as List)
          .map(
            (json) => UserSearchResult(
              id: json['id'],
              username: json['username'],
              fullName: json['full_name'],
              profilePicture: json['profile_picture'],
              isFollowing: true, // Users in following list are always followed
            ),
          )
          .toList();
      _following = list;
      _followingTotal = response['total'] ?? list.length;
    } catch (e) {
      _followListError = 'Failed to load following';
      debugPrint('Load following error: $e');
    } finally {
      _isLoadingFollowList = false;
      notifyListeners();
    }
  }

  /// Clear followers/following lists
  void clearFollowLists() {
    _followers = [];
    _following = [];
    _followListError = null;
    notifyListeners();
  }

  /// Update follow status in followers/following lists
  void _updateFollowStatusInLists(int userId, bool isFollowing) {
    _followers = _followers.map((user) {
      if (user.id == userId) {
        return user.copyWith(isFollowing: isFollowing);
      }
      return user;
    }).toList();

    // For following list, if user unfollows, remove from list
    if (!isFollowing) {
      _following = _following.where((user) => user.id != userId).toList();
    }
  }

  /// Clear current profile
  void clearProfile() {
    _currentProfile = null;
    _profileError = null;
    notifyListeners();
  }

  /// Clear current profile silently (for use in dispose, doesn't notify listeners)
  void clearProfileSilently() {
    _currentProfile = null;
    _profileError = null;
  }
}
