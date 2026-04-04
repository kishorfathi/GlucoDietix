import 'dart:convert';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../../widgets/web_iframe_view/web_iframe_view.dart';
import '../../models/meal_item.dart';
import '../../models/user_profile.dart';
import '../../services/food_detection_service.dart';
import '../../services/plate_method_service.dart';

class ARPlateViewerScreen extends StatefulWidget {
  final List<MealItem> items;
  final UserProfile? profile;

  const ARPlateViewerScreen({
    super.key,
    required this.items,
    required this.profile,
  });

  @override
  State<ARPlateViewerScreen> createState() => _ARPlateViewerScreenState();
}

class _ARPlateViewerScreenState extends State<ARPlateViewerScreen> {
  final PlateMethodService _plateService = PlateMethodService();
  final FoodDetectionService _detectionService = FoodDetectionService();
  CameraController? _controller;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isInitializing = true;
  String? _errorMessage;
  String _webViewId = '';
  late Map<String, MealItem> _itemsById;
  late Map<String, double> _gramsById;
  late Map<String, double> _recommendedById;

  @override
  void initState() {
    super.initState();
    _itemsById = {
      for (final item in widget.items) item.food.id: item,
    };
    _gramsById = {
      for (final item in widget.items) item.food.id: item.grams,
    };
    _recommendedById = {
      for (final item in widget.items)
        item.food.id: _detectionService.getSmartPortionFromProfile(
            item.food, widget.profile),
    };

    if (kIsWeb) {
      _webViewId = 'ar-plate-${DateTime.now().millisecondsSinceEpoch}';
      try {
        _registerWebARView();
      } catch (e) {
        _errorMessage = 'Web AR failed to initialize: $e';
      }
    } else {
      _initializeCamera();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _detectionService.dispose();
    super.dispose();
  }

  void _registerWebARView() {
    final payload = _buildWebPayload();
    final encoded = Uri.encodeComponent(jsonEncode(payload));
    final src = 'ar_plate.html?data=$encoded';

    WebIFrameView.register(
      viewType: _webViewId,
      src: src,
      allowCamera: true,
    );
  }

  Map<String, dynamic> _buildWebPayload() {
    final items = _currentItems();
    final recommendation = _plateService.getPlateRecommendations(items);
    return {
      'title': 'Live AR Plate',
      'items': items
          .map((item) => {
                'name': item.food.name,
                'grams': _gramsById[item.food.id] ?? item.grams,
                'recommended': _recommendedById[item.food.id] ?? item.grams,
                'category': item.food.category,
              })
          .toList(),
      'segments': recommendation.portions
          .map((portion) => {
                'category': portion.category.name,
                'portionCount': portion.portionCount,
              })
          .toList(),
    };
  }

  Future<void> _initializeCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      _cameras = await availableCameras();
      if (_cameras.isEmpty) {
        setState(() {
          _errorMessage = 'No camera found on this device.';
          _isInitializing = false;
        });
        return;
      }

      final backIndex = _cameras.indexWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      _selectedCameraIndex = backIndex >= 0 ? backIndex : 0;
      await _startController(_selectedCameraIndex);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Unable to open camera: $e';
        _isInitializing = false;
      });
    }
  }

  Future<void> _startController(int index) async {
    final oldController = _controller;
    final newController = CameraController(
      _cameras[index],
      ResolutionPreset.high,
      enableAudio: false,
    );

    await oldController?.dispose();
    await newController.initialize();

    if (!mounted) {
      await newController.dispose();
      return;
    }

    setState(() {
      _controller = newController;
      _isInitializing = false;
      _errorMessage = null;
    });
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isInitializing) return;
    setState(() {
      _isInitializing = true;
    });
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _startController(_selectedCameraIndex);
  }

  List<MealItem> _currentItems() {
    return _itemsById.values
        .map(
          (item) => MealItem(
            food: item.food,
            grams: _gramsById[item.food.id] ?? item.grams,
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: const Text('AR Plate'),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
        ),
        body: _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
              )
            : WebIFrameView(viewType: _webViewId, src: ''),
      );
    }

    final controller = _controller;
    final theme = Theme.of(context);
    final items = _currentItems();
    final recommendation = _plateService.getPlateRecommendations(items);
    final totalKcal =
        items.fold(0.0, (sum, item) => sum + item.kcal).toDouble();
    final totalCarbs =
        items.fold(0.0, (sum, item) => sum + item.carbs).toDouble();
    final totalProtein =
        items.fold(0.0, (sum, item) => sum + item.protein).toDouble();
    final totalFat = items.fold(0.0, (sum, item) => sum + item.fat).toDouble();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _errorMessage != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.white, size: 56),
                      const SizedBox(height: 12),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton.icon(
                        onPressed: _initializeCamera,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Back',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              )
            : _isInitializing ||
                    controller == null ||
                    !controller.value.isInitialized
                ? const Center(child: CircularProgressIndicator())
                : Stack(
                    fit: StackFit.expand,
                    children: [
                      CameraPreview(controller),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color.fromRGBO(0, 0, 0, 0.45),
                              Colors.transparent,
                              Color.fromRGBO(0, 0, 0, 0.75),
                            ],
                            stops: [0, 0.45, 1],
                          ),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        right: 12,
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon:
                                  const Icon(Icons.close, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Live AR Plate',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (_cameras.length > 1)
                              IconButton(
                                onPressed: _switchCamera,
                                icon: const Icon(Icons.flip_camera_ios,
                                    color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                      Center(
                        child: CustomPaint(
                          size: const Size(240, 240),
                          painter: _ARPlatePainter(
                            portions: recommendation.portions,
                            colors: _categoryColors(),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 70,
                        left: 16,
                        right: 16,
                        child: _buildSummaryCard(
                          totalKcal: totalKcal,
                          totalCarbs: totalCarbs,
                          totalProtein: totalProtein,
                          totalFat: totalFat,
                          isBalanced: recommendation.isBalanced,
                          missingGroups: recommendation.missingGroups,
                        ),
                      ),
                      Positioned(
                        left: 16,
                        right: 16,
                        bottom: 16,
                        child: _buildFoodPanel(items),
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required double totalKcal,
    required double totalCarbs,
    required double totalProtein,
    required double totalFat,
    required bool isBalanced,
    required List<String> missingGroups,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.restaurant, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isBalanced ? 'Balanced plate' : 'Needs balance',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isBalanced ? Colors.green : Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isBalanced ? 'OK' : 'Adjust',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _buildMetricChip('kcal', totalKcal),
              _buildMetricChip('carbs', totalCarbs),
              _buildMetricChip('protein', totalProtein),
              _buildMetricChip('fat', totalFat),
            ],
          ),
          if (!isBalanced && missingGroups.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Add: ${missingGroups.join(', ')}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMetricChip(String label, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${value.toStringAsFixed(0)} $label',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildFoodPanel(List<MealItem> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white24),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Adjust portions (live)',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: min(220, 60.0 * items.length),
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                final current = _gramsById[item.food.id] ?? item.grams;
                final recommended =
                    _recommendedById[item.food.id] ?? item.grams;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.food.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: current.clamp(20.0, 400.0).toDouble(),
                              min: 20,
                              max: 400,
                              divisions: 76,
                              activeColor: Colors.white,
                              inactiveColor: Colors.white24,
                              onChanged: (value) {
                                setState(() {
                                  _gramsById[item.food.id] = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${current.toStringAsFixed(0)}g',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Recommended ${recommended.toStringAsFixed(0)}g',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<FoodCategory, Color> _categoryColors() {
    return {
      FoodCategory.rice: const Color(0xFFFFF3C4),
      FoodCategory.vegetable: const Color(0xFFE7F6EA),
      FoodCategory.protein: const Color(0xFFFFE6E6),
      FoodCategory.dhal: const Color(0xFFFFF0D6),
      FoodCategory.other: Colors.grey.shade200,
    };
  }
}

class _ARPlatePainter extends CustomPainter {
  final List<PlatePortion> portions;
  final Map<FoodCategory, Color> colors;

  _ARPlatePainter({required this.portions, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius - 2, rimPaint);

    double startAngle = -pi / 2;
    for (final portion in portions) {
      final sweepAngle = (portion.portionCount / 4) * 2 * pi;
      final paint = Paint()
        ..color = (colors[portion.category] ?? Colors.grey.shade200)
            .withValues(alpha: 0.55)
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 6),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }

    final centerPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.35, centerPaint);
  }

  @override
  bool shouldRepaint(_ARPlatePainter oldDelegate) => true;
}
