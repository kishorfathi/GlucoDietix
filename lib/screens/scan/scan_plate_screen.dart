import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/food.dart';
import '../../models/user_profile.dart';
import '../../models/meal_item.dart';
import '../../providers/meal_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/food_detection_service.dart';
import '../../services/plate_method_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/loading_indicator.dart';
import '../foods/food_search_screen.dart';
import '../meal/results_screen.dart';
import '../ar/ar_plate_viewer.dart';
import 'live_scan_plate_screen.dart';

class ScanPlateScreen extends StatefulWidget {
  const ScanPlateScreen({super.key});

  @override
  State<ScanPlateScreen> createState() => _ScanPlateScreenState();
}

class _ScanPlateScreenState extends State<ScanPlateScreen> {
  final FoodDetectionService _detectionService = FoodDetectionService();
  final SupabaseService _supabaseService = SupabaseService();
  final PlateMethodService _plateService = PlateMethodService();
  final ImagePicker _picker = ImagePicker();

  Uint8List? _imageBytes;
  List<DetectedFood> _detectedFoods = [];
  final Set<String> _selectedFoodIds = {};
  final Map<String, double> _selectedPortions = {};
  bool _isDetecting = false;
  String? _mlNotice;
  bool _useCupMeasurement = true; // Default to cup/spoon measurements

  @override
  void dispose() {
    _detectionService.dispose();
    super.dispose();
  }

  Future<void> _openCameraAndDetect() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LiveScanPlateScreen()),
    );
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

  double _targetCarbsForProfile(UserProfile? profile) {
    if (profile == null) return 60;
    if (profile.glucoseRange == 'high') return 45;
    if (profile.glucoseRange == 'low') return 70;
    return 60;
  }

  String _carbTargetReason(UserProfile? profile) {
    if (profile == null) return 'Default carb target';
    switch (profile.glucoseRange) {
      case 'high':
        return 'Lower target due to high glucose range';
      case 'low':
        return 'Higher target due to low glucose range';
      default:
        return 'Standard target for normal glucose range';
    }
  }

  List<MealItem> _selectedMealItems() {
    return _detectedFoods
        .where((detected) => _selectedFoodIds.contains(detected.food.id))
        .map((detected) => MealItem(
              food: detected.food,
              grams: (_selectedPortions[detected.food.id] ??
                      detected.estimatedGrams)
                  .clamp(20.0, 400.0)
                  .toDouble(),
            ))
        .toList();
  }

  double _recommendedPortion(Food food, UserProfile? profile) {
    return _detectionService.getSmartPortionFromProfile(food, profile);
  }

  double _maxPortionLimit(Food food, UserProfile? profile, double recommended) {
    double limit = recommended * 1.5;
    final gi = food.glycemicIndex ?? 55;

    if (profile?.diabetes == true || profile?.glucoseRange == 'high') {
      if (gi >= 70 || food.carbs100g >= 30) {
        limit = recommended * 1.15;
      } else if (gi >= 55 || food.carbs100g >= 20) {
        limit = recommended * 1.3;
      }
    }

    if (profile?.cholesterolConcern == true) {
      if (food.fat100g >= 15 || (food.cholesterolMg ?? 0) >= 100) {
        limit = min(limit, recommended * 1.2);
      }
    }

    if ((food.sodiumMg ?? 0) >= 500) {
      limit = min(limit, recommended * 1.25);
    }

    return limit.clamp(30.0, 400.0).toDouble();
  }

  String _portionLimitReason(Food food, UserProfile? profile) {
    final reasons = <String>[];
    if (profile?.diabetes == true || profile?.glucoseRange == 'high') {
      final gi = food.glycemicIndex ?? 55;
      if (gi >= 70) {
        reasons.add('high GI');
      } else if (food.carbs100g >= 30) {
        reasons.add('high carbs');
      }
    }
    if (profile?.cholesterolConcern == true) {
      if (food.fat100g >= 15 || (food.cholesterolMg ?? 0) >= 100) {
        reasons.add('high fat');
      }
    }
    if ((food.sodiumMg ?? 0) >= 500) {
      reasons.add('high sodium');
    }
    if (reasons.isEmpty) {
      return 'general limit';
    }
    return reasons.join(', ');
  }

  String _formatPortion(double grams, DetectedFood detected) {
    if (_useCupMeasurement) {
      return _gramsToCupSpoon(grams, detected);
    }
    return '${grams.toStringAsFixed(0)} g';
  }

  // Convert grams to cup/spoon measurement
  String _gramsToCupSpoon(double grams, DetectedFood detected) {
    final food = detected.food;
    final category = food.category.toLowerCase();
    final name = food.name.toLowerCase();

    // Rice and grains
    if (category.contains('rice') ||
        category.contains('grain') ||
        name.contains('rice') ||
        name.contains('bread')) {
      final cups = grams / 150; // 1 cup ≈ 150g cooked rice
      if (cups < 0.25) {
        return '${(grams / 37.5).toStringAsFixed(1)} tbsp';
      } else if (cups < 1) {
        return '${(cups * 4).toStringAsFixed(1)}/4 cup';
      } else {
        return '${cups.toStringAsFixed(1)} cup${cups > 1 ? 's' : ''}';
      }
    }

    // Vegetables
    if (category.contains('vegetable') ||
        category.contains('salad') ||
        name.contains('vegetable') ||
        name.contains('beetroot') ||
        name.contains('carrot')) {
      final cups = grams / 150; // 1 cup ≈ 150g vegetables
      if (cups < 1) {
        return '${(cups * 4).toStringAsFixed(1)}/4 cup';
      } else {
        return '${cups.toStringAsFixed(1)} cup${cups > 1 ? 's' : ''}';
      }
    }

    // Dhal/Lentils (liquid curry)
    if (category.contains('lentil') ||
        category.contains('dhal') ||
        name.contains('dhal') ||
        name.contains('dal') ||
        name.contains('parippu')) {
      final cups = grams / 240; // 1 cup ≈ 240g liquid
      if (cups < 0.25) {
        return '${(grams / 15).toStringAsFixed(0)} tbsp';
      } else if (cups < 1) {
        return '${(cups * 4).toStringAsFixed(1)}/4 cup';
      } else {
        return '${cups.toStringAsFixed(1)} cup${cups > 1 ? 's' : ''}';
      }
    }

    // Protein/Curry (use tablespoons for smaller amounts)
    if (category.contains('meat') ||
        category.contains('fish') ||
        category.contains('curry') ||
        name.contains('curry') ||
        name.contains('chicken') ||
        name.contains('beef') ||
        name.contains('fish')) {
      final tbsp = grams / 15; // 1 tbsp ≈ 15g
      if (tbsp < 4) {
        return '${tbsp.toStringAsFixed(1)} tbsp';
      } else if (tbsp < 16) {
        return '${(tbsp / 4).toStringAsFixed(1)}/4 cup';
      } else {
        return '${(grams / 240).toStringAsFixed(1)} cup';
      }
    }

    // Default: use tablespoons
    final tbsp = grams / 15;
    if (tbsp < 4) {
      return '${tbsp.toStringAsFixed(1)} tbsp';
    } else {
      return '${(grams / 240).toStringAsFixed(1)} cup';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final profile = Provider.of<UserProfileProvider>(context).userProfile;

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
                  border:
                      Border.all(color: scheme.primary.withValues(alpha: 0.3)),
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
                  label: const Text('Open Live Camera'),
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
                          _buildLivePlateAndNutrition(theme, scheme, profile),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Detected foods (${_detectedFoods.length})',
                                  style: theme.textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              // Measurement toggle
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  color: scheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildMeasurementToggle(
                                      icon: Icons.restaurant,
                                      label: 'Cup',
                                      isSelected: _useCupMeasurement,
                                      onTap: () {
                                        setState(() {
                                          _useCupMeasurement = true;
                                        });
                                      },
                                      scheme: scheme,
                                    ),
                                    const SizedBox(width: 2),
                                    _buildMeasurementToggle(
                                      icon: Icons.scale,
                                      label: 'g',
                                      isSelected: !_useCupMeasurement,
                                      onTap: () {
                                        setState(() {
                                          _useCupMeasurement = false;
                                        });
                                      },
                                      scheme: scheme,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ..._detectedFoods.map((detected) {
                            final isSelected =
                                _selectedFoodIds.contains(detected.food.id);
                            final currentPortion =
                                _selectedPortions[detected.food.id] ??
                                    detected.estimatedGrams;
                            final recommended =
                                _recommendedPortion(detected.food, profile);
                            final maxLimit = _maxPortionLimit(
                              detected.food,
                              profile,
                              recommended,
                            );
                            final isOverLimit = currentPortion > maxLimit;
                            final nutrients = detected.food
                                .getNutrientsForPortion(currentPortion);
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
                                          onChanged: (value) =>
                                              _toggleDetectedItem(
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
                                                style:
                                                    theme.textTheme.bodySmall,
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: confidenceColor.withValues(
                                                alpha: 0.1),
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
                                            label: _useCupMeasurement
                                                ? _gramsToCupSpoon(
                                                    currentPortion, detected)
                                                : '${currentPortion.toStringAsFixed(0)} g',
                                            onChanged: isSelected
                                                ? (value) {
                                                    setState(() {
                                                      _selectedPortions[detected
                                                          .food.id] = value;
                                                    });
                                                  }
                                                : null,
                                          ),
                                        ),
                                        SizedBox(
                                          width: 90,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                _useCupMeasurement
                                                    ? _gramsToCupSpoon(
                                                        currentPortion,
                                                        detected)
                                                    : '${currentPortion.toStringAsFixed(0)} g',
                                                textAlign: TextAlign.right,
                                                style: theme
                                                    .textTheme.titleSmall
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color: scheme.primary,
                                                ),
                                              ),
                                              if (_useCupMeasurement)
                                                Text(
                                                  '${currentPortion.toStringAsFixed(0)} g',
                                                  textAlign: TextAlign.right,
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Recommended: ${_formatPortion(recommended, detected)}',
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: scheme.onSurface,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          'Max: ${_formatPortion(maxLimit, detected)}',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: isOverLimit
                                                ? Colors.red
                                                : scheme.onSurface,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    LinearProgressIndicator(
                                      value: (currentPortion / maxLimit)
                                          .clamp(0.0, 1.0),
                                      minHeight: 6,
                                      backgroundColor: scheme.surfaceVariant,
                                      valueColor: AlwaysStoppedAnimation(
                                        isOverLimit
                                            ? Colors.red
                                            : scheme.primary,
                                      ),
                                    ),
                                    if (isOverLimit) ...[
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          'Over limit by ${(currentPortion - maxLimit).toStringAsFixed(0)} g (${_portionLimitReason(detected.food, profile)})',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(color: Colors.red),
                                        ),
                                      ),
                                    ] else ...[
                                      const SizedBox(height: 4),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: Text(
                                          'Limit based on your health profile (${_portionLimitReason(detected.food, profile)})',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            color: scheme.onSurface
                                                .withValues(alpha: 0.7),
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 6),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _buildNutrientChip(
                                          'kcal',
                                          nutrients['energy'] ?? 0,
                                          scheme,
                                        ),
                                        _buildNutrientChip(
                                          'carbs',
                                          nutrients['carbs'] ?? 0,
                                          scheme,
                                        ),
                                        _buildNutrientChip(
                                          'protein',
                                          nutrients['protein'] ?? 0,
                                          scheme,
                                        ),
                                        _buildNutrientChip(
                                          'fat',
                                          nutrients['fat'] ?? 0,
                                          scheme,
                                        ),
                                        _buildNutrientChip(
                                          'fiber',
                                          nutrients['fiber'] ?? 0,
                                          scheme,
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
                if (_detectedFoods.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => _openARPlateViewer(profile),
                    icon: const Icon(Icons.view_in_ar),
                    label: const Text('View AR Portion Guide'),
                  ),
                ],
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

  void _openARPlateViewer(UserProfile? profile) {
    if (_selectedFoodIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one food item.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final items = _selectedMealItems();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ARPlateViewerScreen(
          items: items,
          profile: profile,
        ),
      ),
    );
  }

  Widget _buildLivePlateAndNutrition(
    ThemeData theme,
    ColorScheme scheme,
    UserProfile? profile,
  ) {
    final items = _selectedMealItems();
    final plateRecommendation = _plateService.getPlateRecommendations(items);
    final totalKcal =
        items.fold(0.0, (sum, item) => sum + item.kcal).toDouble();
    final totalCarbs =
        items.fold(0.0, (sum, item) => sum + item.carbs).toDouble();
    final totalProtein =
        items.fold(0.0, (sum, item) => sum + item.protein).toDouble();
    final totalFat =
        items.fold(0.0, (sum, item) => sum + item.fat).toDouble();
    final totalFiber =
        items.fold(0.0, (sum, item) => sum + item.fiber).toDouble();
    final targetCarbs = _targetCarbsForProfile(profile);
    final overCarbLimit = totalCarbs > targetCarbs;

    final categoryColors = {
      FoodCategory.rice: const Color(0xFFFFF3C4),
      FoodCategory.vegetable: const Color(0xFFE7F6EA),
      FoodCategory.protein: const Color(0xFFFFE6E6),
      FoodCategory.dhal: const Color(0xFFFFF0D6),
      FoodCategory.other: Colors.grey.shade200,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.restaurant, color: scheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Live plate and nutrition',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (items.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: plateRecommendation.isBalanced
                          ? Colors.green.shade100
                          : Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      plateRecommendation.isBalanced
                          ? 'Balanced'
                          : 'Needs balance',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: plateRecommendation.isBalanced
                            ? Colors.green.shade700
                            : Colors.orange.shade700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (items.isEmpty)
              Text(
                'Select foods below to see live portions, nutrition, and limits.',
                style:
                    theme.textTheme.bodySmall?.copyWith(color: Colors.black54),
              )
            else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CustomPaint(
                      painter: _MiniPlatePainter(
                        portions: plateRecommendation.portions,
                        colors: categoryColors,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryRow(
                          'Calories',
                          totalKcal,
                          'kcal',
                          theme,
                          scheme,
                        ),
                        _buildSummaryRow(
                          'Carbs',
                          totalCarbs,
                          'g',
                          theme,
                          scheme,
                          isAlert: overCarbLimit,
                        ),
                        _buildSummaryRow(
                          'Protein',
                          totalProtein,
                          'g',
                          theme,
                          scheme,
                        ),
                        _buildSummaryRow(
                          'Fat',
                          totalFat,
                          'g',
                          theme,
                          scheme,
                        ),
                        _buildSummaryRow(
                          'Fiber',
                          totalFiber,
                          'g',
                          theme,
                          scheme,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Carb target: ${targetCarbs.toStringAsFixed(0)} g',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: overCarbLimit
                                ? Colors.red
                                : scheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value:
                              (totalCarbs / max(targetCarbs, 1)).clamp(0.0, 1),
                          minHeight: 6,
                          backgroundColor: scheme.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation(
                            overCarbLimit ? Colors.red : scheme.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _carbTargetReason(profile),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            if (items.isNotEmpty &&
                !plateRecommendation.isBalanced &&
                plateRecommendation.missingGroups.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                'Consider adding: ${plateRecommendation.missingGroups.join(', ')}',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurface.withValues(alpha: 0.8)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    String label,
    double value,
    String unit,
    ThemeData theme,
    ColorScheme scheme, {
    bool isAlert = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodySmall),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: isAlert ? Colors.red : scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientChip(
    String label,
    double value,
    ColorScheme scheme,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.surfaceVariant,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        '${value.toStringAsFixed(1)} $label',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: scheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildMeasurementToggle({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ColorScheme scheme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected ? scheme.onPrimary : scheme.onPrimaryContainer,
            ),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color:
                    isSelected ? scheme.onPrimary : scheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniPlatePainter extends CustomPainter {
  final List<PlatePortion> portions;
  final Map<FoodCategory, Color> colors;

  _MiniPlatePainter({required this.portions, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final rimPaint = Paint()
      ..color = Colors.grey.shade300
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius - 2, rimPaint);

    double startAngle = -3.14159 / 2;
    for (final portion in portions) {
      final sweepAngle =
          (portion.portionCount / 4) * 2 * 3.14159; // 4 portions = full plate
      final paint = Paint()
        ..color = colors[portion.category] ?? Colors.grey.shade200
        ..style = PaintingStyle.fill;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 4),
        startAngle,
        sweepAngle,
        true,
        paint,
      );

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(_MiniPlatePainter oldDelegate) => true;
}
