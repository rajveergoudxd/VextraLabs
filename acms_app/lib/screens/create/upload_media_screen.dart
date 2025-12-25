import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:acms_app/providers/creation_provider.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'dart:typed_data';

class UploadMediaScreen extends StatefulWidget {
  const UploadMediaScreen({super.key});

  @override
  State<UploadMediaScreen> createState() => _UploadMediaScreenState();
}

class _UploadMediaScreenState extends State<UploadMediaScreen> {
  final ImagePicker _picker = ImagePicker();
  List<AssetEntity> _galleryAssets = [];
  final Set<String> _selectedAssetIds = {};
  bool _isLoading = true;
  bool _hasPermission = false;
  bool _hasLimitedAccess = false;

  // Platform tabs - matching SelectMediaScreen style
  final List<String> _platforms = [
    'Instagram',
    'Facebook',
    'Twitter',
    'LinkedIn',
  ];
  String _activePlatform = 'Instagram';

  @override
  void initState() {
    super.initState();
    _loadGalleryAssets();
  }

  /// Load device gallery assets using photo_manager
  Future<void> _loadGalleryAssets() async {
    final PermissionState permission =
        await PhotoManager.requestPermissionExtend();

    if (!mounted) return;

    if (permission.isAuth || permission.hasAccess) {
      setState(() {
        _hasPermission = true;
        // Check if access is limited (iOS 14+)
        _hasLimitedAccess = permission == PermissionState.limited;
      });

      // Get recent photos
      final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        type: RequestType.image,
        filterOption: FilterOptionGroup(
          imageOption: const FilterOption(
            sizeConstraint: SizeConstraint(ignoreSize: true),
          ),
        ),
      );

      if (albums.isNotEmpty && mounted) {
        // Get assets from the "Recent" album (usually first)
        final AssetPathEntity recentAlbum = albums.first;
        final List<AssetEntity> assets = await recentAlbum.getAssetListRange(
          start: 0,
          end: 100, // Load first 100 images
        );

        if (mounted) {
          setState(() {
            _galleryAssets = assets;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _hasPermission = false;
        _isLoading = false;
      });
    }
  }

  /// Toggle asset selection
  void _toggleSelection(AssetEntity asset) {
    setState(() {
      if (_selectedAssetIds.contains(asset.id)) {
        _selectedAssetIds.remove(asset.id);
      } else {
        _selectedAssetIds.add(asset.id);
      }
    });
  }

  /// Get selection index for display (1-based)
  int _getSelectionIndex(String assetId) {
    final selectedList = _galleryAssets
        .where((a) => _selectedAssetIds.contains(a.id))
        .map((a) => a.id)
        .toList();
    return selectedList.indexOf(assetId) + 1;
  }

  /// Check if platform is available
  bool _isPlatformAvailable(String platform) {
    return platform == 'Instagram' || platform == 'LinkedIn';
  }

  /// Handle platform tab tap
  void _onPlatformTap(String platform) {
    if (_isPlatformAvailable(platform)) {
      setState(() {
        _activePlatform = platform;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$platform integration coming soon!'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  /// Take photo with camera
  Future<void> _takePhoto() async {
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Camera permission is required'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (photo != null && mounted) {
        // Add to provider and navigate
        final provider = context.read<CreationProvider>();
        provider.reset();
        provider.setMode('manual');
        provider.setMediaType('gallery');
        provider.toggleMediaSelection(photo.path);
        context.push('/create/edit-media');
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  /// Proceed with selected media
  Future<void> _proceedWithSelection() async {
    if (_selectedAssetIds.isEmpty) return;

    final provider = context.read<CreationProvider>();
    provider.reset();
    provider.setMode('manual');
    provider.setMediaType('gallery');

    // Get files for selected assets
    for (final asset in _galleryAssets.where(
      (a) => _selectedAssetIds.contains(a.id),
    )) {
      final file = await asset.file;
      if (file != null) {
        provider.toggleMediaSelection(file.path);
      }
    }

    if (mounted) {
      context.push('/create/edit-media');
    }
  }

  /// Request permission again
  Future<void> _requestPermission() async {
    final PermissionState permission =
        await PhotoManager.requestPermissionExtend();
    if (permission.isAuth || permission.hasAccess) {
      _loadGalleryAssets();
    } else if (permission == PermissionState.denied) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please grant photo library access in settings'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        PhotoManager.openSetting();
      }
    }
  }

  /// Add more photos from gallery (for limited access)
  Future<void> _addMorePhotos() async {
    try {
      // Use image_picker to let user select additional photos
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );

      if (pickedFiles.isNotEmpty && mounted) {
        final provider = context.read<CreationProvider>();

        // Add currently selected gallery assets first
        for (final asset in _galleryAssets.where(
          (a) => _selectedAssetIds.contains(a.id),
        )) {
          final file = await asset.file;
          if (file != null) {
            provider.toggleMediaSelection(file.path);
          }
        }

        // Add newly picked files
        for (final file in pickedFiles) {
          provider.toggleMediaSelection(file.path);
        }

        // Reload gallery to show any newly accessible photos
        await _loadGalleryAssets();
      }
    } catch (e) {
      debugPrint('Error picking additional photos: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      body: Stack(
        children: [
          Column(
            children: [
              // Header
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        onPressed: () => context.pop(),
                        icon: const Icon(Icons.arrow_back),
                        style: IconButton.styleFrom(
                          backgroundColor: isDark
                              ? Colors.white.withValues(alpha: 0.1)
                              : Colors.black.withValues(alpha: 0.05),
                        ),
                      ),
                      Text(
                        'Select Media',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.grey[900],
                        ),
                      ),
                      TextButton(
                        onPressed: () => context.pop(),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Platform Tabs
              Container(
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.surfaceDark
                      : AppColors.surfaceLight,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                ),
                child: Row(
                  children: _platforms
                      .map((platform) => _buildPlatformTab(platform, isDark))
                      .toList(),
                ),
              ),

              // Content
              Expanded(child: _buildContent(isDark)),
            ],
          ),

          // Bottom Bar
          if (_hasPermission)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                decoration: BoxDecoration(
                  color:
                      (isDark
                              ? AppColors.backgroundDark
                              : AppColors.backgroundLight)
                          .withValues(alpha: 0.95),
                  border: Border(
                    top: BorderSide(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                ),
                child: ElevatedButton(
                  onPressed: _selectedAssetIds.isNotEmpty
                      ? _proceedWithSelection
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: isDark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    disabledForegroundColor: isDark
                        ? Colors.grey[600]
                        : Colors.grey[400],
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: _selectedAssetIds.isNotEmpty ? 4 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _selectedAssetIds.isNotEmpty
                            ? 'Next (${_selectedAssetIds.length} selected)'
                            : 'Select media to continue',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_selectedAssetIds.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 20),
                      ],
                    ],
                  ),
                ),
              ),
            ),

          // AI Assist FAB
          if (_hasPermission)
            Positioned(
              bottom: 100,
              right: 16,
              child:
                  FloatingActionButton(
                    onPressed: () {
                      // Future: AI-powered media suggestions
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('AI media suggestions coming soon!'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    backgroundColor: isDark
                        ? AppColors.surfaceDark
                        : Colors.white,
                    foregroundColor: AppColors.primary,
                    child: const Icon(Icons.auto_awesome),
                  ).animate().scale(
                    delay: 500.ms,
                    duration: 300.ms,
                    curve: Curves.easeOutBack,
                  ),
            ),
        ],
      ),
    );
  }

  Widget _buildPlatformTab(String platform, bool isDark) {
    final isActive = platform == _activePlatform;
    final isAvailable = _isPlatformAvailable(platform);

    return Expanded(
      child: GestureDetector(
        onTap: () => _onPlatformTap(platform),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isActive ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  platform,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                    color: isActive
                        ? AppColors.primary
                        : isAvailable
                        ? (isDark ? Colors.grey[400] : Colors.grey[600])
                        : (isDark ? Colors.grey[600] : Colors.grey[400]),
                  ),
                ),
              ),
              if (!isAvailable) ...[
                const SizedBox(width: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Soon',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!_hasPermission) {
      return _buildPermissionRequest(isDark);
    }

    if (_galleryAssets.isEmpty) {
      return _buildEmptyGallery(isDark);
    }

    return Column(
      children: [
        // Recents Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Recents',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const Icon(Icons.expand_more, color: Colors.grey),
                ],
              ),
              Row(
                children: [
                  // Add more photos button (shows when limited access)
                  if (_hasLimitedAccess) ...[
                    _buildCircleButton(
                      Icons.add_photo_alternate,
                      isDark,
                      onTap: _addMorePhotos,
                    ),
                    const SizedBox(width: 8),
                  ],
                  _buildCircleButton(
                    Icons.camera_alt,
                    isDark,
                    onTap: _takePhoto,
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () {
                        // Select all visible / Clear selection toggle
                        setState(() {
                          if (_selectedAssetIds.length ==
                              _galleryAssets.length) {
                            _selectedAssetIds.clear();
                          } else {
                            _selectedAssetIds.addAll(
                              _galleryAssets.map((a) => a.id),
                            );
                          }
                        });
                      },
                      icon: Icon(
                        _selectedAssetIds.length == _galleryAssets.length
                            ? Icons.deselect
                            : Icons.select_all,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Gallery Grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.only(bottom: 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 2,
              mainAxisSpacing: 2,
            ),
            // Add 1 for the "Add More" tile when in limited access mode
            itemCount: _galleryAssets.length + (_hasLimitedAccess ? 1 : 0),
            itemBuilder: (context, index) {
              // Show "Add More" tile as the first item in limited access mode
              if (_hasLimitedAccess && index == 0) {
                return _buildAddMoreTile(isDark);
              }

              // Adjust index for actual assets when in limited mode
              final assetIndex = _hasLimitedAccess ? index - 1 : index;
              final asset = _galleryAssets[assetIndex];
              final isSelected = _selectedAssetIds.contains(asset.id);
              final selectionIndex = isSelected
                  ? _getSelectionIndex(asset.id)
                  : 0;

              return GestureDetector(
                onTap: () => _toggleSelection(asset),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Thumbnail
                    FutureBuilder<Uint8List?>(
                      future: asset.thumbnailDataWithSize(
                        const ThumbnailSize(300, 300),
                        quality: 80,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data != null) {
                          return Image.memory(
                            snapshot.data!,
                            fit: BoxFit.cover,
                            color: isSelected
                                ? Colors.black.withValues(alpha: 0.4)
                                : null,
                            colorBlendMode: isSelected
                                ? BlendMode.darken
                                : null,
                          );
                        }
                        return Container(
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          child: const Center(
                            child: Icon(Icons.image, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                    // Selection border
                    if (isSelected)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.primary,
                            width: 4,
                          ),
                        ),
                      ),
                    // Selection indicator
                    Positioned(
                      top: 8,
                      right: 8,
                      child: isSelected
                          ? Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 2,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  '$selectionIndex',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            )
                          : Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  width: 1.5,
                                ),
                              ),
                            ),
                    ),
                    // Video indicator
                    if (asset.type == AssetType.video)
                      Positioned(
                        bottom: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.videocam,
                                color: Colors.white,
                                size: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                _formatDuration(asset.videoDuration),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCircleButton(IconData icon, bool isDark, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[800] : Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 20,
          color: isDark ? Colors.grey[300] : Colors.grey[600],
        ),
      ),
    );
  }

  /// Build the "Add More Photos" tile for limited access mode
  Widget _buildAddMoreTile(bool isDark) {
    return GestureDetector(
      onTap: _addMorePhotos,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[100],
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.5),
            width: 2,
            strokeAlign: BorderSide.strokeAlignInside,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.add_photo_alternate,
                size: 28,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add More',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
            Text(
              'Photos',
              style: TextStyle(
                fontSize: 10,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPermissionRequest(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.photo_library_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Access Your Photos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Allow access to your photo library to select images for your posts.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _requestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Grant Access',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyGallery(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              'No Photos Found',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.grey[900],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Take a photo with your camera to get started.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _takePhoto,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Take Photo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
