import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;
import 'dart:ui' as ui;

/// AR Portion Viewer Screen
/// Shows visual references for food portion sizes to help diabetes patients
/// understand and estimate correct serving sizes
/// On web: Uses WebAR with camera and 3D models
/// On mobile: Uses visual reference guides
class ARPortionViewer extends StatefulWidget {
  final String foodName;
  final double portionGrams;

  const ARPortionViewer({
    super.key,
    required this.foodName,
    required this.portionGrams,
  });

  @override
  State<ARPortionViewer> createState() => _ARPortionViewerState();
}

enum ARMode { selection, camera, model, guide }

class _ARPortionViewerState extends State<ARPortionViewer> {
  ARMode _currentMode = ARMode.selection;
  String _cameraViewId = '';
  String _modelViewId = '';

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _cameraViewId = 'ar-camera-${widget.foodName.hashCode}';
      _modelViewId = 'ar-model-${widget.foodName.hashCode}';
      try {
        _registerWebARViews();
      } catch (e) {
        // If WebAR registration fails, default to guide mode
        debugPrint('WebAR registration failed: $e');
        _currentMode = ARMode.guide;
      }
    } else {
      _currentMode = ARMode.guide;
    }
  }

  void _registerWebARViews() {
    // Get the current window origin to build absolute URLs
    final baseUrl = html.window.location.origin;

    // Register camera AR iframe
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _cameraViewId,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src =
              '$baseUrl/ar_camera.html?food=${Uri.encodeComponent(widget.foodName)}&grams=${widget.portionGrams}'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%'
          ..allow = 'camera';

        return iframe;
      },
    );

    // Register 3D model AR iframe
    // ignore: undefined_prefixed_name
    ui.platformViewRegistry.registerViewFactory(
      _modelViewId,
      (int viewId) {
        final iframe = html.IFrameElement()
          ..src =
              '$baseUrl/ar_viewer.html?food=${Uri.encodeComponent(widget.foodName)}&grams=${widget.portionGrams}'
          ..style.border = 'none'
          ..style.width = '100%'
          ..style.height = '100%';

        return iframe;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    switch (_currentMode) {
      case ARMode.selection:
        return _buildSelectionScreen();
      case ARMode.camera:
        return _buildCameraARView();
      case ARMode.model:
        return _buildModelARView();
      case ARMode.guide:
        return _buildGuideView();
    }
  }

  Widget _buildSelectionScreen() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose AR Mode'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.purple.shade400, Colors.purple.shade700],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header
                Card(
                  color: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.view_in_ar,
                          size: 48,
                          color: Colors.purple,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.foodName,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${widget.portionGrams.toInt()}g',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // AR Mode Options
                Expanded(
                  child: ListView(
                    children: [
                      if (kIsWeb) ...[
                        _buildARModeCard(
                          icon: Icons.camera_alt,
                          title: 'Camera AR',
                          description:
                              'Point camera at your plate and see portion size overlay in real-time',
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade600
                            ],
                          ),
                          onTap: () =>
                              setState(() => _currentMode = ARMode.camera),
                        ),
                        const SizedBox(height: 16),
                        _buildARModeCard(
                          icon: Icons.view_in_ar,
                          title: '3D Model AR',
                          description:
                              'View interactive 3D portion model with AR placement',
                          gradient: LinearGradient(
                            colors: [
                              Colors.purple.shade400,
                              Colors.purple.shade600
                            ],
                          ),
                          onTap: () =>
                              setState(() => _currentMode = ARMode.model),
                        ),
                        const SizedBox(height: 16),
                      ],
                      _buildARModeCard(
                        icon: Icons.menu_book,
                        title: 'Visual Guide',
                        description:
                            'Hand-based portion references and diabetes tips',
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade400,
                            Colors.green.shade600
                          ],
                        ),
                        onTap: () =>
                            setState(() => _currentMode = ARMode.guide),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildARModeCard({
    required IconData icon,
    required String title,
    required String description,
    required Gradient gradient,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.white.withOpacity(0.7),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraARView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Try to load WebAR, with error handling
          HtmlElementView(viewType: _cameraViewId),
          _buildBackButton(),

          // Error message overlay (shows if iframe fails to load)
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'If AR camera doesn\'t load, use the Visual Guide instead.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () =>
                        setState(() => _currentMode = ARMode.guide),
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Open Visual Guide'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelARView() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          HtmlElementView(viewType: _modelViewId),
          _buildBackButton(),

          // Error message overlay
          Positioned(
            bottom: 100,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'If 3D model doesn\'t load, use the Visual Guide instead.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () =>
                        setState(() => _currentMode = ARMode.guide),
                    icon: const Icon(Icons.menu_book),
                    label: const Text('Open Visual Guide'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Positioned(
      top: 16,
      left: 16,
      child: SafeArea(
        child: CircleAvatar(
          backgroundColor: Colors.white.withOpacity(0.9),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.purple),
            onPressed: () => setState(() => _currentMode = ARMode.selection),
          ),
        ),
      ),
    );
  }

  Widget _buildGuideView() {
    final portionInfo = _getDetailedPortionInfo(widget.portionGrams);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Portion Size Guide'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (kIsWeb) {
              setState(() => _currentMode = ARMode.selection);
            } else {
              Navigator.pop(context);
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Food Info Header
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple.shade400, Colors.purple.shade600],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.view_in_ar,
                    size: 64,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.foodName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${widget.portionGrams.toInt()}g',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Main Visual Reference Card
            Card(
              margin: const EdgeInsets.all(16),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      portionInfo.emoji,
                      style: const TextStyle(fontSize: 80),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      portionInfo.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      portionInfo.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // How to Measure Card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.straighten, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'How to Measure',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...portionInfo.measurements.map((measurement) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '• ',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.blue.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  measurement,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Tips Card
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.tips_and_updates,
                            color: Colors.green.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Diabetes Management Tips',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...portionInfo.tips.map((tip) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '✓ ',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  tip,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Visual Comparison
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Common Household Items',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildComparisonItem(
                      portionInfo.comparisonEmoji,
                      portionInfo.comparisonText,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.check_circle),
        label: const Text('Got it!'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildComparisonItem(String emoji, String text) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 32),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }

  _PortionInfo _getDetailedPortionInfo(double grams) {
    if (grams <= 15) {
      return _PortionInfo(
        emoji: '👍',
        title: 'Thumb Size',
        description:
            'About the size of your thumb from the tip to the first knuckle',
        measurements: [
          'Approximately 1 tablespoon',
          'Good for condiments, sambol, or chutney',
          'Use your thumb as a quick reference',
        ],
        tips: [
          'Great for high-sugar or high-fat condiments',
          'Keep portions small to control calories',
          'Perfect for flavoring without overdoing it',
        ],
        comparisonEmoji: '🥄',
        comparisonText: 'Same as 1 tablespoon or a bottle cap',
      );
    } else if (grams <= 30) {
      return _PortionInfo(
        emoji: '🥄',
        title: '2 Tablespoons',
        description: 'About 2 tablespoons or the size of a ping pong ball',
        measurements: [
          'Two thumb-sized portions',
          'Good for seeni sambol, pickle, or pol sambol',
          'Use a regular tablespoon twice',
        ],
        tips: [
          'Common serving for condiments',
          'Watch out for oil-based items',
          'Measure when starting out',
        ],
        comparisonEmoji: '🏓',
        comparisonText: 'Same size as a ping pong ball',
      );
    } else if (grams <= 60) {
      return _PortionInfo(
        emoji: '⛳',
        title: 'Golf Ball Size',
        description: 'About the size of a golf ball or 1/4 cup',
        measurements: [
          'Approximately 1/4 cup',
          'Make a small ball with your hand',
          'Good for parippu (dhal) or curry',
        ],
        tips: [
          'Good portion for curry dishes',
          'Helps control carbohydrates',
          'Pair with vegetables for balance',
        ],
        comparisonEmoji: '⛳',
        comparisonText: 'Same size as a golf ball or small egg',
      );
    } else if (grams <= 120) {
      return _PortionInfo(
        emoji: '✊',
        title: 'Your Fist',
        description: 'About the size of your closed fist or 1/2 cup',
        measurements: [
          'Close your hand into a fist',
          'Approximately 1/2 cup',
          'Standard serve for rice, vegetables, or dhal',
        ],
        tips: [
          'Perfect portion for diabetics',
          'Your fist is always with you!',
          'Use for rice, vegetables, or curry',
        ],
        comparisonEmoji: '✊',
        comparisonText: 'Same as your closed fist or 1/2 cup measure',
      );
    } else if (grams <= 180) {
      return _PortionInfo(
        emoji: '⚾',
        title: 'Baseball Size',
        description: 'About the size of a baseball or 3/4 cup',
        measurements: [
          'Approximately 3/4 cup',
          'Slightly larger than your fist',
          'Good for string hoppers (3-4 pieces)',
        ],
        tips: [
          'Moderate portion for main dishes',
          'Monitor blood glucose response',
          'Balance with protein and vegetables',
        ],
        comparisonEmoji: '⚾',
        comparisonText: 'Same as a baseball or tennis ball',
      );
    } else if (grams <= 250) {
      return _PortionInfo(
        emoji: '🖐️',
        title: 'Cupped Hand',
        description: 'About what fits in your cupped hand or 1 cup',
        measurements: [
          'Hold your palm up and cup it',
          'Fill it to the brim',
          'Approximately 1 cup (200-250g)',
          'Recommended portion for rice or hoppers',
        ],
        tips: [
          'Standard diabetic portion for carbs',
          'Best for meals with balanced vegetables',
          'Monitor portion creep over time',
          'Pair with low-GI vegetables',
        ],
        comparisonEmoji: '🖐️',
        comparisonText: 'Fills your cupped palm or a standard cup',
      );
    } else if (grams <= 350) {
      return _PortionInfo(
        emoji: '🍽️',
        title: 'Small Plate',
        description: 'About 1.5 cups or covering a small side plate',
        measurements: [
          'Approximately 1 to 1.5 cups',
          'Use a small dessert plate as reference',
          'Covers a small plate when spread out',
        ],
        tips: [
          'Larger portion - check blood glucose',
          'Better to split into two meals',
          'Increase vegetables, reduce carbs',
          'Consider your activity level',
        ],
        comparisonEmoji: '🥗',
        comparisonText: 'Covers a small salad/dessert plate',
      );
    } else {
      return _PortionInfo(
        emoji: '🍛',
        title: 'Full Plate',
        description: 'Large portion - 2+ cups (400g+)',
        measurements: [
          'More than 2 cups',
          'Covers a full dinner plate',
          'Consider splitting into two meals',
        ],
        tips: [
          'CAUTION: Very large portion for diabetics',
          'May cause blood glucose spike',
          'Consider reducing by half',
          'Increase physical activity if consumed',
          'Check blood glucose 2 hours after',
        ],
        comparisonEmoji: '⚠️',
        comparisonText: 'Covers a full dinner plate - too much for one meal!',
      );
    }
  }
}

/// Portion information model
class _PortionInfo {
  final String emoji;
  final String title;
  final String description;
  final List<String> measurements;
  final List<String> tips;
  final String comparisonEmoji;
  final String comparisonText;

  _PortionInfo({
    required this.emoji,
    required this.title,
    required this.description,
    required this.measurements,
    required this.tips,
    required this.comparisonEmoji,
    required this.comparisonText,
  });
}
