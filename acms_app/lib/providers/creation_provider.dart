import 'package:flutter/material.dart';
import 'package:acms_app/services/post_service.dart';

class EditState {
  String filterName;
  Map<String, double> adjustments;
  double cropRatio; // 0.0 for original, 1.0 for square, etc.

  EditState({
    this.filterName = 'Original',
    Map<String, double>? adjustments,
    this.cropRatio = 0.0,
  }) : adjustments =
           adjustments ??
           {
             'brightness': 0.0,
             'contrast': 0.0,
             'saturation': 0.0,
             'warmth': 0.0,
             'vignette': 0.0, // Added
             'sharpen': 0.0, // Added
           };
}

/// Model for a draft
class Draft {
  final int id;
  final String? title;
  final String? content;
  final List<String> mediaUrls;
  final List<String> platforms;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Draft({
    required this.id,
    this.title,
    this.content,
    this.mediaUrls = const [],
    this.platforms = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory Draft.fromJson(Map<String, dynamic> json) {
    return Draft(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      mediaUrls: List<String>.from(json['media_urls'] ?? []),
      platforms: List<String>.from(json['platforms'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }
}

class CreationProvider extends ChangeNotifier {
  String? _mode; // 'manual', 'auto', 'review'
  String? _mediaType; // 'gallery', 'auto'

  // Manual Flow State
  final List<String> _selectedMedia = []; // URLs of selected images
  final Map<String, String> _captions = {}; // Platform -> Caption
  final Map<String, EditState> _editStates = {}; // URL -> EditState

  // Platform Selection
  final List<String> _platforms = ['Inspire']; // Default always selected

  // Service
  final PostService _postService = PostService();

  // Loading State
  bool _isPublishing = false;
  String? _publishError;
  bool _publishSuccess = false;

  // Draft State
  List<Draft> _drafts = [];
  bool _isLoadingDrafts = false;
  bool _isSavingDraft = false;
  String? _draftError;
  int? _currentDraftId; // If editing an existing draft

  String? get mode => _mode;
  String? get mediaType => _mediaType;
  List<String> get selectedMedia => _selectedMedia;
  Map<String, String> get captions => _captions;

  List<String> get platforms => _platforms;
  bool get isPublishing => _isPublishing;
  String? get publishError => _publishError;
  bool get publishSuccess => _publishSuccess;

  // Draft getters
  List<Draft> get drafts => _drafts;
  bool get isLoadingDrafts => _isLoadingDrafts;
  bool get isSavingDraft => _isSavingDraft;
  String? get draftError => _draftError;
  int? get currentDraftId => _currentDraftId;

  void setMode(String mode) {
    _mode = mode;
    notifyListeners();
  }

  void setMediaType(String type) {
    _mediaType = type;
    notifyListeners();
  }

  void toggleMediaSelection(String url) {
    if (_selectedMedia.contains(url)) {
      _selectedMedia.remove(url);
      _editStates.remove(url);
    } else {
      _selectedMedia.add(url);
      // Initialize edit state for new media
      if (!_editStates.containsKey(url)) {
        _editStates[url] = EditState();
      }
    }
    notifyListeners();
  }

  void setCaption(String platform, String caption) {
    _captions[platform] = caption;
    notifyListeners();
  }

  void togglePlatform(String platform) {
    if (platform == 'Inspire') return; // Cannot toggle off default

    if (_platforms.contains(platform)) {
      _platforms.remove(platform);
    } else {
      _platforms.add(platform);
    }
    notifyListeners();
  }

  Future<void> publishPost() async {
    _isPublishing = true;
    _publishError = null;
    _publishSuccess = false;
    notifyListeners();

    try {
      // For now, we take the caption from 'Inspire' or the first available caption
      // In a real app we might send per-platform captions if the API supported it
      // The current API takes one 'content' string.
      String content = _captions['Inspire'] ?? '';
      if (content.isEmpty && _captions.isNotEmpty) {
        content = _captions.values.first;
      }

      // Map display names to API keys
      // UI: "X (Twitter)" -> API: "twitter"
      final apiPlatforms = _platforms.map((p) {
        if (p == 'X (Twitter)' || p == 'Twitter') return 'twitter';
        return p.toLowerCase();
      }).toList();

      await _postService.publishPost(
        content: content,
        mediaUrls: _selectedMedia,
        platforms: apiPlatforms,
      );

      _publishSuccess = true;
    } catch (e) {
      _publishError = e.toString();
    } finally {
      _isPublishing = false;
      notifyListeners();
    }
  }

  // --- Draft Methods ---

  /// Save current state as draft
  Future<bool> saveDraft({String? title}) async {
    _isSavingDraft = true;
    _draftError = null;
    notifyListeners();

    try {
      String content = _captions['Inspire'] ?? '';
      if (content.isEmpty && _captions.isNotEmpty) {
        content = _captions.values.first;
      }

      final apiPlatforms = _platforms.map((p) {
        if (p == 'X (Twitter)' || p == 'Twitter') return 'twitter';
        return p.toLowerCase();
      }).toList();

      if (_currentDraftId != null) {
        // Update existing draft
        await _postService.updateDraft(
          _currentDraftId!,
          content: content,
          mediaUrls: _selectedMedia,
          platforms: apiPlatforms,
          title: title,
        );
      } else {
        // Create new draft
        await _postService.saveDraft(
          content: content,
          mediaUrls: _selectedMedia,
          platforms: apiPlatforms,
          title: title ?? 'Untitled Draft',
        );
      }

      _isSavingDraft = false;
      notifyListeners();
      return true;
    } catch (e) {
      _draftError = e.toString();
      _isSavingDraft = false;
      notifyListeners();
      return false;
    }
  }

  /// Load all user's drafts
  Future<void> loadDrafts() async {
    _isLoadingDrafts = true;
    _draftError = null;
    notifyListeners();

    try {
      final response = await _postService.getDrafts();
      final items = response['items'] as List;
      _drafts = items.map((json) => Draft.fromJson(json)).toList();
    } catch (e) {
      _draftError = e.toString();
    } finally {
      _isLoadingDrafts = false;
      notifyListeners();
    }
  }

  /// Load a specific draft for editing
  Future<bool> loadDraft(int draftId) async {
    try {
      final response = await _postService.getDraft(draftId);

      // Reset current state
      reset();

      // Populate with draft data
      _currentDraftId = response['id'];
      _mode = 'manual';

      final mediaUrls = List<String>.from(response['media_urls'] ?? []);
      for (final url in mediaUrls) {
        _selectedMedia.add(url);
        _editStates[url] = EditState();
      }

      final content = response['content'] as String?;
      if (content != null && content.isNotEmpty) {
        _captions['Inspire'] = content;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _draftError = e.toString();
      return false;
    }
  }

  /// Delete a draft
  Future<bool> deleteDraft(int draftId) async {
    try {
      await _postService.deleteDraft(draftId);
      _drafts.removeWhere((d) => d.id == draftId);
      notifyListeners();
      return true;
    } catch (e) {
      _draftError = e.toString();
      return false;
    }
  }

  /// Publish a draft
  Future<bool> publishDraft(int draftId) async {
    _isPublishing = true;
    notifyListeners();

    try {
      await _postService.publishDraft(draftId);
      _drafts.removeWhere((d) => d.id == draftId);
      _isPublishing = false;
      notifyListeners();
      return true;
    } catch (e) {
      _publishError = e.toString();
      _isPublishing = false;
      notifyListeners();
      return false;
    }
  }

  // --- Advanced Editing Methods ---

  EditState getEditState(String url) {
    if (!_editStates.containsKey(url)) {
      _editStates[url] = EditState();
    }
    return _editStates[url]!;
  }

  void setFilter(String url, String filterName) {
    getEditState(url).filterName = filterName;
    notifyListeners();
  }

  void setAdjustment(String url, String key, double value) {
    getEditState(url).adjustments[key] = value;
    notifyListeners();
  }

  void setCropRatio(String url, double ratio) {
    getEditState(url).cropRatio = ratio;
    notifyListeners();
  }

  // Backward compatibility helper
  String getFilter(String url) => getEditState(url).filterName;

  void reset() {
    _mode = null;
    _mediaType = null;
    _selectedMedia.clear();
    _captions.clear();
    _editStates.clear();
    _currentDraftId = null;
    _publishError = null;
    _publishSuccess = false;
    notifyListeners();
  }
}
