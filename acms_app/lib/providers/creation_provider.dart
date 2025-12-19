import 'package:flutter/material.dart';

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
           };
}

class CreationProvider extends ChangeNotifier {
  String? _mode; // 'manual', 'auto', 'review'
  String? _mediaType; // 'gallery', 'auto'

  // Manual Flow State
  final List<String> _selectedMedia = []; // URLs of selected images
  final Map<String, String> _captions = {}; // Platform -> Caption
  final Map<String, EditState> _editStates = {}; // URL -> EditState

  String? get mode => _mode;
  String? get mediaType => _mediaType;
  List<String> get selectedMedia => _selectedMedia;
  Map<String, String> get captions => _captions;

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
