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

  String? get mode => _mode;
  String? get mediaType => _mediaType;
  List<String> get selectedMedia => _selectedMedia;
  Map<String, String> get captions => _captions;

  List<String> get platforms => _platforms;
  bool get isPublishing => _isPublishing;
  String? get publishError => _publishError;
  bool get publishSuccess => _publishSuccess;

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
      reset(); // Reset state on success? Or maybe keep it until user navigates away?
      // Actually, don't reset here, let the UI handle navigation and then reset.
    } catch (e) {
      _publishError = e.toString();
    } finally {
      _isPublishing = false;
      notifyListeners();
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
    notifyListeners();
  }
}
