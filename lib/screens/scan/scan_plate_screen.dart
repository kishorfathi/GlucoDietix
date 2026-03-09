import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/food_detection_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/loading_indicator.dart';
import '../foods/food_search_screen.dart';
import '../meal/results_screen.dart';
import 'camera_capture_screen.dart';

class ScanPlateScreen extends StatefulWidget {
  const ScanPlateScreen({super.key});

  @override
  State<ScanPlateScreen> createState() => _ScanPlateScreenState();
}

class _ScanPlateScreenState extends State<ScanPlateScreen> {
  final FoodDetectionService _detectionService = FoodDetectionService();
  final SupabaseService _supabaseService = SupabaseService();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  List<DetectedFood> _detectedFoods = [];
  final Set<String> _selectedFoodIds = {};
  final Map<String, double> _selectedPortions = {};
  bool _isDetecting = false;
  String? _mlNotice;

  @override
  void dispose() {
    _detectionService.dispose();
    super.dispose();
  }

  Future<void> _openCameraAndDetect() async {
    final captured = await Navigator.push<CapturedPhoto>(
      context,
      MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
    );

    if (!mounted || captured == null) return;

    setState(() {
      _imageBytes = captured.bytes;
      _detectedFoods = [];
      _selectedFoodIds.clear();
      _selectedPortions.clear();
      _mlNotice = null;
    });

    await _detectFoods(captured.file.path);
  }

  Future<void> _uploadPlateAndDetect() async {
    try {
      final photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 90,
      );

      if (!mounted || photo == null) return;

      final bytes = await photo.readAsBytes();
      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _detectedFoods = [];
        _selectedFoodIds.clear();
        _selectedPortions.clear();
        _mlNotice = null;
      });

      await _detectFoods(photo.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _detectFoods(String? imagePath) async {
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).userProfile;

    setState(() {
      _isDetecting = true;
      _mlNotice = null;
    });

    try {
      final foods = await _supabaseService.searchFoods();
      final detected = await _detectionService.detectFoodsFromImage(
        foods,
        imageBytes: _imageBytes ?? Uint8List(0),
        imagePath: imagePath,
      );

      final portions = <String, double>{};
      final selected = <String>{};
      for (final item in detected) {
        selected.add(item.food.id);
        portions[item.food.id] =
            _detectionService.getSmartPortionFromProfile(item.food, profile);
      }

      if (!mounted) return;
      setState(() {
        _detectedFoods = detected;
        _selectedFoodIds
          ..clear()
          ..addAll(selected);
        _selectedPortions
          ..clear()
          ..addAll(portions);
        _isDetecting = false;
        if (kIsWeb && detected.isEmpty) {
          _mlNotice =
              'No web ML labels received. Set GOOGLE_VISION_API_KEY with --dart-define, or use manual multi-select.';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isDetecting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Detection failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _addSelectedToMealAndAnalyze() async {
    if (_selectedFoodIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one food item.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    mealProvider.clearMeal();

    for (final detected in _detectedFoods) {
      if (!_selectedFoodIds.contains(detected.food.id)) continue;
      mealProvider.addFood(detected.food);
      mealProvider.updateGrams(
        detected.food.id,
        (_selectedPortions[detected.food.id] ?? detected.estimatedGrams)
            .clamp(20.0, 400.0)
            .toDouble(),
      );
    }

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const ResultsScreen()),
    );
  }

  void _toggleDetectedItem(String foodId, bool selected) {
    setState(() {
      if (selected) {
        _selectedFoodIds.add(foodId);
      } else {
        _selectedFoodIds.remove(foodId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Scan Plate')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary.withValues(alpha: 0.12),
                      scheme.tertiary.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.3)),
                ),
                child: const Text(
                  'Take a live photo, review predicted foods, and adjust portions before analysis.',
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 14),
              if (_imageBytes == null) ...[
                Expanded(
                  child: Center(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.camera_alt_rounded,
                              size: 80, color: scheme.primary),
                          const SizedBox(height: 12),
                          Text(
                            'Ready to capture your meal',
                            style: theme.textTheme.titleMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _openCameraAndDetect,
                  icon: const Icon(Icons.camera),
                  label: const Text('Open Camera'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _uploadPlateAndDetect,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Plate Photo'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FoodSearchScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Manual Multi-Select'),
                ),
              ] else ...[
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.memory(
                            _imageBytes!,
                            height: 240,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (_isDetecting) ...[
                          const LoadingIndicator(),
                          const SizedBox(height: 8),
                          const Text(
                            'Analyzing with ML...',
                            textAlign: TextAlign.center,
                          ),
                        ] else if (_detectedFoods.isEmpty) ...[
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'No confident food matches found.',
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _mlNotice ??
                                        'Try a clearer angle or add foods manually.',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Detected foods (${_detectedFoods.length})',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          ..._detectedFoods.map((detected) {
                            final isSelected =
                                _selectedFoodIds.contains(detected.food.id);
                            final currentPortion = _selectedPortions[
                                    detected.food.id] ??
                                detected.estimatedGrams;
                            final confidenceColor = detected.confidence >= 0.75
                                ? Colors.green
                                : detected.confidence >= 0.55
                                    ? Colors.orange
                                    : Colors.red;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  children: [
                                    Row(
                                      children: [
                                        Checkbox(
                                          value: isSelected,
                                          onChanged: (value) => _toggleDetectedItem(
                                            detected.food.id,
                                            value ?? false,
                                          ),
                                        ),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                detected.food.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              Text(
                                                'Source label: ${detected.sourceLabel}',
                                                style: theme.textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: confidenceColor
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                              color: confidenceColor,
                                            ),
                                          ),
                                          child: Text(
                                            detected.confidencePercent,
                                            style: TextStyle(
                                              color: confidenceColor,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Slider(
                                            value: currentPortion
                                                .clamp(20.0, 400.0)
                                                .toDouble(),
                                            min: 20,
                                            max: 400,
                                            divisions: 76,
                                            label:
                                                '${currentPortion.toStringAsFixed(0)} g',
                                            onChanged: isSelected
                                                ? (value) {
                                                    setState(() {
                                                      _selectedPortions[
                                                          detected.food.id] = value;
                                                    });
                                                  }
                                                : null,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 78,
                                          child: Text(
                                            '${currentPortion.toStringAsFixed(0)} g',
                                            textAlign: TextAlign.right,
                                            style: theme.textTheme.titleSmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_detectedFoods.isNotEmpty)
                  FilledButton.icon(
                    onPressed: _addSelectedToMealAndAnalyze,
                    icon: const Icon(Icons.analytics),
                    label: Text(
                      'Add Selected (${_selectedFoodIds.length}) and Analyze',
                    ),
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FoodSearchScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.restaurant),
                  label: const Text('Manual Multi-Select'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _openCameraAndDetect,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Retake Photo'),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _uploadPlateAndDetect,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Another Photo'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
