import 'dart:async';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import '../../models/meal_item.dart';
import '../../models/food.dart';
import '../../providers/meal_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/food_detection_service.dart';
import '../../services/health_recommendation_service.dart';
import '../../services/supabase_service.dart';
import '../meal/results_screen.dart';
import 'web_live_camera_controller_stub.dart'
    if (dart.library.html) 'web_live_camera_controller.dart';

class LiveScanPlateScreen extends StatefulWidget {
  const LiveScanPlateScreen({super.key});

  @override
  State<LiveScanPlateScreen> createState() => _LiveScanPlateScreenState();
}

class _LiveScanPlateScreenState extends State<LiveScanPlateScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final FoodDetectionService _detectionService = FoodDetectionService();
  final HealthRecommendationService _healthService = HealthRecommendationService();

  final WebLiveCameraController _webController = WebLiveCameraController();
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;

  List<DetectedFood> _detectedFoods = [];
  List<Food> _availableFoods = [];
  final Set<String> _selectedFoodIds = {};
  final Map<String, double> _selectedPortions = {};

  bool _isInitializing = true;
  bool _isProcessing = false;
  String? _errorMessage;
  String? _mlNotice;
  bool _webNeedsStart = false;
  List<MealItem> _mealItems = [];
  MealAnalysis? _analysis;

  Timer? _webTimer;
  DateTime _lastProcessed = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void dispose() {
    _webTimer?.cancel();
    _cameraController?.dispose();
    _webController.dispose();
    _detectionService.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    try {
      _availableFoods = await _supabaseService.searchFoods();
      if (_availableFoods.isEmpty) {
        _mlNotice =
            'Food database is empty. Check your Supabase connection.';
      }
      if (kIsWeb) {
        _webNeedsStart = true;
      } else {
        _cameras = await availableCameras();
        if (_cameras.isEmpty) {
          _errorMessage = 'No camera found on this device.';
        } else {
          final backIndex = _cameras.indexWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
          );
          _selectedCameraIndex = backIndex >= 0 ? backIndex : 0;
          await _startMobileCamera(_selectedCameraIndex);
        }
      }
    } catch (e) {
      _errorMessage = 'Unable to initialize camera: $e';
    }

    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _startWebCamera() async {
    setState(() {
      _isInitializing = true;
      _errorMessage = null;
    });

    await _webController.initialize();
    if (_webController.error != null) {
      _errorMessage = _webController.error;
    } else {
      _startWebLoop();
      _webNeedsStart = false;
    }

    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  Future<void> _startMobileCamera(int index) async {
    final oldController = _cameraController;
    final newController = CameraController(
      _cameras[index],
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await oldController?.dispose();
    await newController.initialize();

    if (!mounted) {
      await newController.dispose();
      return;
    }

    _cameraController = newController;
    await newController.startImageStream(_processCameraImage);
  }

  Future<void> _switchCamera() async {
    if (_cameras.length < 2 || _isInitializing) return;
    setState(() {
      _isInitializing = true;
    });
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _startMobileCamera(_selectedCameraIndex);
    if (mounted) {
      setState(() => _isInitializing = false);
    }
  }

  void _startWebLoop() {
    _webTimer?.cancel();
    _webTimer = Timer.periodic(const Duration(milliseconds: 1200), (_) async {
      if (!mounted || _isProcessing) return;
      final bytes = await _webController.captureFrame();
      if (bytes == null) return;
      await _runDetectionFromBytes(bytes);
    });
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessing) return;
    final now = DateTime.now();
    if (now.difference(_lastProcessed) < const Duration(milliseconds: 900)) {
      return;
    }
    _lastProcessed = now;
    _isProcessing = true;

    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) {
        _isProcessing = false;
        return;
      }

      final detected = await _detectionService.detectFoodsFromInputImage(
        _availableFoods,
        inputImage,
      );

      if (!mounted) return;
      _updateDetections(detected);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mlNotice = 'Live detection error: $e';
      });
    } finally {
      _isProcessing = false;
    }
  }

  Future<void> _runDetectionFromBytes(Uint8List bytes) async {
    _isProcessing = true;
    try {
      final detected = await _detectionService.detectFoodsFromWebBytes(
        _availableFoods,
        bytes,
      );

      if (!mounted) return;
      if (detected.isEmpty) {
        _mlNotice ??=
            'No detections yet. Start the local YOLO server (tool/yolo_server.py).';
      }
      _updateDetections(detected);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _mlNotice = 'Live web detection error: $e';
      });
    } finally {
      _isProcessing = false;
    }
  }

  InputImage? _buildInputImage(CameraImage image) {
    final controller = _cameraController;
    if (controller == null) return null;

    final rotation = _rotationFromSensor(
      controller.description.sensorOrientation,
    );

    final format = InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;

    final bytes = _concatenatePlanes(image.planes);

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes.first.bytesPerRow,
      ),
    );
  }

  InputImageRotation _rotationFromSensor(int sensorOrientation) {
    switch (sensorOrientation) {
      case 90:
        return InputImageRotation.rotation90deg;
      case 180:
        return InputImageRotation.rotation180deg;
      case 270:
        return InputImageRotation.rotation270deg;
      case 0:
      default:
        return InputImageRotation.rotation0deg;
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final builder = BytesBuilder(copy: false);
    for (final Plane plane in planes) {
      builder.add(plane.bytes);
    }
    return builder.takeBytes();
  }

  void _updateDetections(List<DetectedFood> detected) {
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).userProfile;

    final selected = <String>{};
    final portions = <String, double>{};
    for (final item in detected) {
      selected.add(item.food.id);
      portions[item.food.id] =
          _detectionService.getSmartPortionFromProfile(item.food, profile);
    }

    final items = detected
        .where((item) => selected.contains(item.food.id))
        .map(
          (item) => MealItem(
            food: item.food,
            grams: (portions[item.food.id] ?? item.estimatedGrams)
                .clamp(20.0, 400.0)
                .toDouble(),
          ),
        )
        .toList();

    final analysis = _healthService.analyzeMeal(items, profile);

    setState(() {
      _detectedFoods = detected;
      _selectedFoodIds
        ..clear()
        ..addAll(selected);
      _selectedPortions
        ..clear()
        ..addAll(portions);
      _mealItems = items;
      _analysis = analysis;
    });
  }

  void _toggleFood(String foodId, bool selected) {
    setState(() {
      if (selected) {
        _selectedFoodIds.add(foodId);
      } else {
        _selectedFoodIds.remove(foodId);
      }
      _rebuildMealItems();
    });
  }

  void _rebuildMealItems() {
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).userProfile;
    final items = _detectedFoods
        .where((item) => _selectedFoodIds.contains(item.food.id))
        .map(
          (item) => MealItem(
            food: item.food,
            grams: (_selectedPortions[item.food.id] ?? item.estimatedGrams)
                .clamp(20.0, 400.0)
                .toDouble(),
          ),
        )
        .toList();
    _mealItems = items;
    _analysis = _healthService.analyzeMeal(items, profile);
  }

  void _addToMealAndAnalyze() {
    if (_mealItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No foods detected yet.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    mealProvider.clearMeal();
    for (final item in _mealItems) {
      mealProvider.addFood(item.food);
      mealProvider.updateGrams(item.food.id, item.grams);
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ResultsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final profile = Provider.of<UserProfileProvider>(context).userProfile;
    final analysis = _analysis;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildCameraPreview(),
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
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Live Scan',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (!kIsWeb && _cameras.length > 1)
                    IconButton(
                      onPressed: _switchCamera,
                      icon: const Icon(Icons.flip_camera_ios,
                          color: Colors.white),
                    ),
                ],
              ),
            ),
            if (_isInitializing)
              const Center(child: CircularProgressIndicator())
            else if (_errorMessage != null)
              _buildErrorState()
            else if (kIsWeb && _webNeedsStart)
              _buildWebStartOverlay()
            else ...[
              Positioned(
                top: 70,
                left: 12,
                right: 12,
                child: _buildHealthSummary(analysis, profile),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: _buildDetectedPanel(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCameraPreview() {
    if (kIsWeb) {
      return _webController.buildPreview();
    }
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return CameraPreview(controller);
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 56),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Unable to start live scan.',
              style: const TextStyle(color: Colors.white),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: kIsWeb ? _startWebCamera : _initialize,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWebStartOverlay() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.videocam, color: Colors.white, size: 56),
            const SizedBox(height: 12),
            const Text(
              'Start live camera',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap below to allow camera access in your browser.',
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _startWebCamera,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Camera'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthSummary(MealAnalysis? analysis, profile) {
    if (analysis == null) {
      return _buildInfoCard(
        'Scanning your plate...',
        _mlNotice ?? 'Point the camera at your meal for live detection.',
      );
    }

    final rating = analysis.overallRating;
    final color = _ratingColor(rating);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.health_and_safety, color: color, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Health status: ${_ratingLabel(rating)}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${analysis.healthScore}/100',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildTotalsRow(),
          if (analysis.warnings.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              analysis.warnings.first,
              style: const TextStyle(color: Colors.orangeAccent, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (_mlNotice != null) ...[
            const SizedBox(height: 6),
            Text(
              _mlNotice!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalsRow() {
    final totalKcal = _mealItems.fold(0.0, (sum, item) => sum + item.kcal);
    final totalCarbs = _mealItems.fold(0.0, (sum, item) => sum + item.carbs);
    final totalProtein = _mealItems.fold(0.0, (sum, item) => sum + item.protein);
    final totalFat = _mealItems.fold(0.0, (sum, item) => sum + item.fat);

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: [
        _metricChip('kcal', totalKcal),
        _metricChip('carbs', totalCarbs),
        _metricChip('protein', totalProtein),
        _metricChip('fat', totalFat),
      ],
    );
  }

  Widget _metricChip(String label, double value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
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

  Widget _buildDetectedPanel() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Detected foods',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              if (_mealItems.isNotEmpty)
                TextButton(
                  onPressed: _addToMealAndAnalyze,
                  child: const Text('Analyze'),
                ),
            ],
          ),
          if (_detectedFoods.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text(
                'No foods detected yet. Keep the plate in view.',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
            )
          else
            SizedBox(
              height: 160,
              child: ListView.builder(
                itemCount: _detectedFoods.length,
                itemBuilder: (context, index) {
                  final detected = _detectedFoods[index];
                  final isSelected =
                      _selectedFoodIds.contains(detected.food.id);
                  final portion =
                      _selectedPortions[detected.food.id] ??
                          detected.estimatedGrams;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(
                          value: isSelected,
                          onChanged: (value) =>
                              _toggleFood(detected.food.id, value ?? false),
                          activeColor: Colors.white,
                          checkColor: Colors.black,
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                detected.food.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${portion.toStringAsFixed(0)}g • ${detected.confidencePercent}',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
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

  Widget _buildInfoCard(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _ratingColor(String rating) {
    switch (rating) {
      case 'excellent':
        return Colors.greenAccent;
      case 'good':
        return Colors.lightGreenAccent;
      case 'moderate':
        return Colors.orangeAccent;
      case 'caution':
      default:
        return Colors.redAccent;
    }
  }

  String _ratingLabel(String rating) {
    switch (rating) {
      case 'excellent':
        return 'Excellent';
      case 'good':
        return 'Good';
      case 'moderate':
        return 'Moderate';
      case 'caution':
      default:
        return 'Caution';
    }
  }
}
