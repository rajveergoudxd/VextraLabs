import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:acms_app/providers/creation_provider.dart';
import 'package:acms_app/theme/app_theme.dart';

class EditMediaScreen extends StatefulWidget {
  const EditMediaScreen({super.key});

  @override
  State<EditMediaScreen> createState() => _EditMediaScreenState();
}

class _EditMediaScreenState extends State<EditMediaScreen> {
  int _currentIndex = 0;
  String _activeTab = 'Filter'; // 'Filter', 'Adjust', 'Crop'
  String _activeAdjustment = 'brightness'; // Default adjustment tool

  // Configuration for Filters
  final List<Map<String, dynamic>> _filters = [
    {'name': 'Original', 'matrix': null},
    {
      'name': 'Vivid',
      'matrix': [
        1.2,
        0,
        0,
        0,
        0,
        0,
        1.2,
        0,
        0,
        0,
        0,
        0,
        1.2,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ],
    },
    {
      'name': 'Warm',
      'matrix': [
        1.1,
        0,
        0,
        0,
        0,
        0,
        1.0,
        0,
        0,
        0,
        0,
        0,
        0.9,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ],
    },
    {
      'name': 'Cool',
      'matrix': [
        0.9,
        0,
        0,
        0,
        0,
        0,
        1.0,
        0,
        0,
        0,
        0,
        0,
        1.1,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ],
    },
    {
      'name': 'B&W',
      'matrix': [
        0.33,
        0.33,
        0.33,
        0,
        0,
        0.33,
        0.33,
        0.33,
        0,
        0,
        0.33,
        0.33,
        0.33,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ],
    },
    {
      'name': 'Vintage',
      'matrix': [
        0.9,
        0.5,
        0.1,
        0,
        0,
        0.3,
        0.8,
        0.1,
        0,
        0,
        0.2,
        0.3,
        0.5,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ],
    },
  ];

  // Configuration for Adjustments
  final List<Map<String, dynamic>> _adjustmentTools = [
    {
      'id': 'brightness',
      'icon': Icons.brightness_6,
      'label': 'Brightness',
      'min': -0.5,
      'max': 0.5,
    },
    {
      'id': 'contrast',
      'icon': Icons.contrast,
      'label': 'Contrast',
      'min': -0.5,
      'max': 0.5,
    },
    {
      'id': 'saturation',
      'icon': Icons.gradient,
      'label': 'Saturation',
      'min': -1.0,
      'max': 1.0,
    },
    {
      'id': 'warmth',
      'icon': Icons.thermostat,
      'label': 'Warmth',
      'min': -0.2,
      'max': 0.2,
    },
    {
      'id': 'vignette',
      'icon': Icons.vignette,
      'label': 'Vignette',
      'min': 0.0,
      'max': 1.0,
    },
    {
      'id': 'sharpen',
      'icon': Icons.change_history,
      'label': 'Sharpen',
      'min': 0.0,
      'max': 1.0,
    },
  ];

  // Configuration for Crop Ratios
  final List<Map<String, dynamic>> _cropRatios = [
    {'label': 'Original', 'value': 0.0}, // Special case
    {'label': '1:1', 'value': 1.0},
    {'label': '4:5', 'value': 0.8},
    {'label': '16:9', 'value': 16 / 9},
  ];

  @override
  Widget build(BuildContext context) {
    // isDark variable removed as it was unused
    final creationProvider = Provider.of<CreationProvider>(context);
    final selectedMedia = creationProvider.selectedMedia;

    if (selectedMedia.isEmpty) {
      return const Scaffold(body: Center(child: Text('No media selected')));
    }

    final currentUrl = selectedMedia[_currentIndex];
    final editState = creationProvider.getEditState(currentUrl);

    return Scaffold(
      backgroundColor:
          Colors.black, // Always black background for editing focus
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Edit',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push('/create/craft-post'),
            child: const Text(
              'Next',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Main Image Preview Area
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Hero(
                  tag: currentUrl,
                  child: _buildFilteredImage(currentUrl, editState),
                ),

                // Overlay Controls (Carousel indicators)
                if (selectedMedia.length > 1)
                  Positioned(
                    top: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${_currentIndex + 1}/${selectedMedia.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),

                // Thumbnails preview floating at bottom of image area
                Positioned(
                  bottom: 10,
                  child: SizedBox(
                    height: 50,
                    width: MediaQuery.of(context).size.width,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: selectedMedia.length,
                      itemBuilder: (context, index) {
                        final isSelected = index == _currentIndex;
                        return GestureDetector(
                          onTap: () => setState(() => _currentIndex = index),
                          child: Container(
                            width: 40,
                            height: 40,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              border: isSelected
                                  ? Border.all(color: Colors.white, width: 2)
                                  : null,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: _buildMediaImage(selectedMedia[index]),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom Toolbar Area
          Container(
            color: const Color(0xFF121212),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Level 3: Sliders (Only for Adjust)
                if (_activeTab == 'Adjust')
                  SizedBox(
                    height: 50,
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: SizedBox(
                            width: 30,
                            child: Text(
                              (editState.adjustments[_activeAdjustment]! * 100)
                                  .toInt()
                                  .toString(),
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppColors.primary,
                              inactiveTrackColor: Colors.grey[800],
                              thumbColor: Colors.white,
                              overlayColor: AppColors.primary.withValues(
                                alpha: 0.2,
                              ),
                              trackHeight: 2,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 6,
                              ),
                            ),
                            child: Slider(
                              value: editState.adjustments[_activeAdjustment]!,
                              min: _getMinMax(_activeAdjustment).min,
                              max: _getMinMax(_activeAdjustment).max,
                              onChanged: (val) {
                                creationProvider.setAdjustment(
                                  currentUrl,
                                  _activeAdjustment,
                                  val,
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Level 2: Specific Tools
                SizedBox(
                  height: 100,
                  child: _buildSubToolBar(
                    context,
                    creationProvider,
                    currentUrl,
                    editState,
                  ),
                ),

                const Divider(height: 1, color: Colors.white10),

                // Level 1: Main Tabs
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMainTab('Filter', 'Filter'),
                    _buildMainTab('Adjust', 'Edit'),
                    _buildMainTab('Crop', 'Crop'),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }

  ({double min, double max}) _getMinMax(String key) {
    final tool = _adjustmentTools.firstWhere(
      (t) => t['id'] == key,
      orElse: () => _adjustmentTools[0],
    );
    return (
      min: (tool['min'] as num).toDouble(),
      max: (tool['max'] as num).toDouble(),
    );
  }

  Widget _buildMainTab(String id, String label) {
    final isSelected = _activeTab == id;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = id),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildSubToolBar(
    BuildContext context,
    CreationProvider provider,
    String url,
    EditState state,
  ) {
    if (_activeTab == 'Filter') {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final name = filter['name'] as String;
          final isSelected = state.filterName == name;

          return GestureDetector(
            onTap: () => provider.setFilter(url, name),
            child: Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      border: isSelected
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: ColorFiltered(
                      colorFilter: ColorFilter.matrix(
                        filter['matrix'] != null
                            ? (filter['matrix'] as List)
                                  .map((e) => (e as num).toDouble())
                                  .toList()
                            : [
                                1,
                                0,
                                0,
                                0,
                                0,
                                0,
                                1,
                                0,
                                0,
                                0,
                                0,
                                0,
                                1,
                                0,
                                0,
                                0,
                                0,
                                0,
                                1,
                                0,
                              ].map((e) => e.toDouble()).toList(),
                      ),
                      child: _buildMediaImage(url, fit: BoxFit.cover),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    } else if (_activeTab == 'Adjust') {
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _adjustmentTools.length,
        itemBuilder: (context, index) {
          final tool = _adjustmentTools[index];
          final id = tool['id'] as String;
          final isSelected = _activeAdjustment == id;
          // Check if edited (not 0)
          final val = state.adjustments[id] ?? 0.0;
          final isEdited = val.abs() > 0.01;

          return GestureDetector(
            onTap: () => setState(() => _activeAdjustment = id),
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                    child: Icon(
                      tool['icon'] as IconData,
                      color: isSelected
                          ? Colors.white
                          : (isEdited ? AppColors.primary : Colors.grey),
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tool['label'] as String,
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white
                          : (isEdited ? AppColors.primary : Colors.grey),
                      fontSize: 10,
                    ),
                  ),
                  if (isEdited)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    } else {
      // Crop
      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _cropRatios.length,
        itemBuilder: (context, index) {
          final ratio = _cropRatios[index];
          final val = (ratio['value'] as num).toDouble();
          final isSelected = (state.cropRatio - val).abs() < 0.01;

          return GestureDetector(
            onTap: () => provider.setCropRatio(url, val),
            child: Container(
              margin: const EdgeInsets.only(right: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.crop_free,
                    color: isSelected ? Colors.white : Colors.grey,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    ratio['label'] as String,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }
  }

  Widget _buildFilteredImage(String url, EditState state) {
    // 1. Get Filter Matrix
    final filterData = _filters.firstWhere(
      (f) => f['name'] == state.filterName,
      orElse: () => _filters[0],
    );
    List<double> filterMatrix = filterData['matrix'] != null
        ? (filterData['matrix'] as List)
              .map((e) => (e as num).toDouble())
              .toList()
        : [
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
            0,
            0,
            0,
            0,
            1,
            0,
          ].map((e) => e.toDouble()).toList();

    // 2. Apply Manual Adjustments (Brightness, Contrast, Saturation)
    // Note: Creating a truly combined matrix is complex math.
    // We will approximate by chaining ColorFilters or using a simplified matrix approach if possible.
    // For Flutter, chaining ColorFiltered widgets is cleaner but can be improved for performance later.
    // Or we modify the matrix itself.

    // Brightness: Add offset to R, G, B rows
    // stored as -0.5 to 0.5. 0.5 ~ +128 in 0-255 scale approx?
    // In normalized 0-1 matrix, just adding the value to the offset column (index 4, 9, 14) works.
    double b = state.adjustments['brightness'] ?? 0.0;

    // Contrast:
    // New = (Old - 0.5) * contrast + 0.5
    // Matrix scale diagonal elements, and adjust offset.
    double c =
        (state.adjustments['contrast'] ?? 0.0) +
        1.0; // 0.5 to 1.5 range typically

    // Saturation:
    // Standard saturation matrix math
    double s = (state.adjustments['saturation'] ?? 0.0) + 1.0; // 0.0 to 2.0

    // Apply combined logic?
    // Let's use ColorFilter.matrix with a computed matrix for Adjustments, and another for Filters.

    final adjMatrix = _calcAdjustmentMatrix(b, c, s);

    Widget image = _buildMediaImage(url, fit: BoxFit.cover);

    // Apply Filter first (mimicking filters usually being base LUTs)
    image = ColorFiltered(
      colorFilter: ColorFilter.matrix(filterMatrix),
      child: image,
    );

    // Apply Adjustments on top
    image = ColorFiltered(
      colorFilter: ColorFilter.matrix(adjMatrix),
      child: image,
    );

    // Apply Crop (Aspect Ratio)
    Widget processedImage = image;
    if (state.cropRatio > 0.01) {
      processedImage = AspectRatio(aspectRatio: state.cropRatio, child: image);
    }

    // Apply Vignette (Overlay)
    if ((state.adjustments['vignette'] ?? 0) > 0) {
      return Stack(
        fit: StackFit.passthrough,
        children: [
          processedImage,
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(
                      alpha: (state.adjustments['vignette'] ?? 0) * 0.8,
                    ),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Note: Sharpening would require custom shaders which is out of scope for this simple editor.
    // We keep the slider for UI completeness but it currently acts as a placeholder or could subtly boost contrast.

    return processedImage;
  }

  List<double> _calcAdjustmentMatrix(
    double brightness,
    double contrast,
    double saturation,
  ) {
    // 1. Saturation
    // Weights for standard luminance (Rec 709)
    const lumR = 0.2126;
    const lumG = 0.7152;
    const lumB = 0.0722;

    double oneMinusSat = 1.0 - saturation;

    double r1 = oneMinusSat * lumR + saturation;
    double r2 = oneMinusSat * lumG;
    double r3 = oneMinusSat * lumB;

    double g1 = oneMinusSat * lumR;
    double g2 = oneMinusSat * lumG + saturation;
    double g3 = oneMinusSat * lumB;

    double b1 = oneMinusSat * lumR;
    double b2 = oneMinusSat * lumG;
    double b3 = oneMinusSat * lumB + saturation;

    // 2. Contrast & Brightness
    // C * (S) + B
    // Scale the saturation matrix by contrast, then add brightness offset corrected for contrast center (0.5)

    double t = (1.0 - contrast) / 2.0; // offset for contrast
    t += brightness; // add brightness

    return [
      r1 * contrast,
      r2 * contrast,
      r3 * contrast,
      0,
      t * 255,
      g1 * contrast,
      g2 * contrast,
      g3 * contrast,
      0,
      t * 255,
      b1 * contrast,
      b2 * contrast,
      b3 * contrast,
      0,
      t * 255,
      0,
      0,
      0,
      1,
      0,
    ];
  }

  /// Helper to display media from either local file path or network URL
  Widget _buildMediaImage(String path, {BoxFit fit = BoxFit.contain}) {
    // Check if it's a local file path
    if (path.startsWith('/') || path.startsWith('file://')) {
      return Image.file(
        File(path.replaceFirst('file://', '')),
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[800],
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
            ),
          );
        },
      );
    } else {
      // Network URL
      return Image.network(
        path,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: Colors.grey[900],
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                color: AppColors.primary,
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Colors.grey[800],
            child: const Center(
              child: Icon(Icons.broken_image, color: Colors.grey, size: 48),
            ),
          );
        },
      );
    }
  }
}
