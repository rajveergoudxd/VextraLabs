import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:acms_app/providers/creation_provider.dart';
import 'package:acms_app/theme/app_theme.dart';
import 'dart:io';

class UploadMediaScreen extends StatefulWidget {
  const UploadMediaScreen({super.key});

  @override
  State<UploadMediaScreen> createState() => _UploadMediaScreenState();
}

class _UploadMediaScreenState extends State<UploadMediaScreen> {
  final ImagePicker _picker = ImagePicker();
  List<XFile> _selectedImages = [];

  @override
  void initState() {
    super.initState();
    // Removed auto-trigger - let user click Gallery/Camera buttons
  }

  Future<void> _pickImages() async {
    // Capture provider before async gap
    final provider = context.read<CreationProvider>();

    // Check permission first
    final hasPermission = await _requestPhotosPermission();
    if (!hasPermission) return;
    if (!mounted) return;

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = images;
        });
        // Add to provider
        provider.reset();
        provider.setMode('manual');
        provider.setMediaType('gallery');
        for (final image in images) {
          provider.toggleMediaSelection(image.path);
        }
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  Future<void> _takePhoto({bool addToExisting = false}) async {
    // Capture provider before async gap
    final provider = context.read<CreationProvider>();

    // Check permission first
    final hasPermission = await _requestCameraPermission();
    if (!hasPermission) return;
    if (!mounted) return;

    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (photo != null) {
        setState(() {
          if (addToExisting) {
            // Add to existing selection
            _selectedImages = [..._selectedImages, photo];
          } else {
            // Replace with new photo
            _selectedImages = [photo];
          }
        });
        if (!addToExisting) {
          provider.reset();
          provider.setMode('manual');
          provider.setMediaType('gallery');
        }
        provider.toggleMediaSelection(photo.path);
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
    }
  }

  /// Show bottom sheet to select media source (Gallery or Camera)
  void _showMediaSourceSheet({bool addToExisting = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Text(
              addToExisting ? 'Add more media' : 'Select media source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textMain,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    if (addToExisting) {
                      _addMoreFromGallery();
                    } else {
                      _pickImages();
                    }
                  },
                  isDark: isDark,
                ),
                _buildSourceOption(
                  icon: Icons.camera_alt_rounded,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _takePhoto(addToExisting: addToExisting);
                  },
                  isDark: isDark,
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.grey[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Add more images from gallery to existing selection
  Future<void> _addMoreFromGallery() async {
    // Capture provider before async gap
    final provider = context.read<CreationProvider>();

    final hasPermission = await _requestPhotosPermission();
    if (!hasPermission) return;
    if (!mounted) return;

    try {
      final List<XFile> images = await _picker.pickMultiImage(
        imageQuality: 85,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = [..._selectedImages, ...images];
        });
        for (final image in images) {
          provider.toggleMediaSelection(image.path);
        }
      }
    } catch (e) {
      debugPrint('Error picking images: $e');
    }
  }

  /// Request photos/gallery permission
  Future<bool> _requestPhotosPermission() async {
    PermissionStatus status;

    // On Android 13+, use photos permission; on older versions use storage
    if (Platform.isAndroid) {
      status = await Permission.photos.request();
      if (status.isDenied) {
        // Fallback to storage for older Android
        status = await Permission.storage.request();
      }
    } else {
      status = await Permission.photos.request();
    }

    if (status.isGranted || status.isLimited) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog(
        'Photo Library Access Required',
        'Please enable photo library access in app settings to select images.',
      );
      return false;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Photo library permission is required to select images',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }

  /// Request camera permission
  Future<bool> _requestCameraPermission() async {
    final status = await Permission.camera.request();

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      _showPermissionDeniedDialog(
        'Camera Access Required',
        'Please enable camera access in app settings to take photos.',
      );
      return false;
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Camera permission is required to take photos'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }

  /// Show dialog for permanently denied permissions
  void _showPermissionDeniedDialog(String title, String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  /// Save current media as draft
  Future<void> _saveDraft(BuildContext context) async {
    final provider = context.read<CreationProvider>();

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 20),
            Expanded(child: Text('Saving draft...')),
          ],
        ),
      ),
    );

    try {
      // Save draft (media URLs are already local paths, backend will handle storage)
      final success = await provider.saveDraft(
        title: 'Draft ${DateTime.now().toString().substring(0, 16)}',
      );

      if (!mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(); // Close loading dialog

      if (success) {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Draft saved! Find it in Recent Activity.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.green,
          ),
        );
        provider.reset();
        // ignore: use_build_context_synchronously
        context.pop(); // Go back to home
      } else {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(provider.draftError ?? 'Failed to save draft'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      Navigator.of(context).pop(); // Close loading dialog
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark
        ? AppColors.backgroundDark
        : AppColors.backgroundLight;
    final surfaceColor = isDark ? AppColors.surfaceDark : Colors.white;
    final textColor = isDark ? Colors.white : AppColors.textMain;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: textColor),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Upload Media',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          if (_selectedImages.isNotEmpty)
            IconButton(
              icon: Icon(Icons.add_photo_alternate_outlined, color: textColor),
              onPressed: () => _showMediaSourceSheet(addToExisting: true),
            ),
        ],
      ),
      body: _selectedImages.isEmpty
          ? _buildEmptyState(isDark, surfaceColor, textColor)
          : _buildMediaPreview(isDark, surfaceColor, textColor),
    );
  }

  Widget _buildEmptyState(bool isDark, Color surfaceColor, Color textColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'Select media to upload',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choose from gallery or take a photo',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPickerButton(
                icon: Icons.photo_library_rounded,
                label: 'Gallery',
                onTap: _pickImages,
                isDark: isDark,
              ),
              const SizedBox(width: 24),
              _buildPickerButton(
                icon: Icons.camera_alt_rounded,
                label: 'Camera',
                onTap: _takePhoto,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPickerButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.textMain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPreview(bool isDark, Color surfaceColor, Color textColor) {
    return Column(
      children: [
        // Media preview area
        Expanded(
          child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: surfaceColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: _selectedImages.length == 1
                  ? Image.file(
                      File(_selectedImages.first.path),
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.all(8),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                      itemCount: _selectedImages.length,
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(_selectedImages[index].path),
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedImages.removeAt(index);
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.6,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),

        // Quick action buttons
        Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'What would you like to do?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.edit_rounded,
                      title: 'Edit',
                      subtitle: 'Crop, filter, adjust',
                      onTap: () => context.push('/create/edit-media'),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.auto_awesome,
                      title: 'AI Caption',
                      subtitle: 'Generate text',
                      onTap: () {
                        // Future: AI caption generation
                        context.push('/create/craft-post');
                      },
                      isDark: isDark,
                      isPrimary: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.edit_note_rounded,
                      title: 'Write Caption',
                      subtitle: 'Manual entry',
                      onTap: () => context.push('/create/craft-post'),
                      isDark: isDark,
                    ),
                  ),
                  Expanded(
                    child: _buildActionCard(
                      icon: Icons.bookmark_add_outlined,
                      title: 'Save Draft',
                      subtitle: 'Continue later',
                      onTap: () => _saveDraft(context),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    bool isPrimary = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.primary
              : (isDark ? Colors.grey[850] : Colors.grey[50]),
          borderRadius: BorderRadius.circular(16),
          border: isPrimary
              ? null
              : Border.all(
                  color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isPrimary
                    ? Colors.white.withValues(alpha: 0.2)
                    : (isDark
                          ? Colors.grey[800]
                          : AppColors.primary.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isPrimary ? Colors.white : AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isPrimary
                          ? Colors.white
                          : (isDark ? Colors.white : AppColors.textMain),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isPrimary
                          ? Colors.white.withValues(alpha: 0.8)
                          : Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
