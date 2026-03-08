import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../services/food_detection_service.dart';
import '../../services/supabase_service.dart';
import '../../providers/meal_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../meal/results_screen.dart';
import '../foods/food_search_screen.dart';

/// Scan Plate Screen
class ScanPlateScreen extends StatefulWidget {
  const ScanPlateScreen({super.key});

  @override
  State<ScanPlateScreen> createState() => _ScanPlateScreenState();
}

class _ScanPlateScreenState extends State<ScanPlateScreen> {
  final ImagePicker _picker = ImagePicker();
  final FoodDetectionService _detectionService = FoodDetectionService();
  final SupabaseService _supabaseService = SupabaseService();

  XFile? _imageFile;
  Uint8List? _webImage;
  List<DetectedFood>? _detectedFoods;
  bool _isDetecting = false;

  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        if (kIsWeb) {
          final bytes = await photo.readAsBytes();
          setState(() {
            _imageFile = photo;
            _webImage = bytes;
          });
          await _detectFoods(bytes);
        } else {
          setState(() {
            _imageFile = photo;
          });
          final bytes = await photo.readAsBytes();
          await _detectFoods(bytes);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error taking picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo != null) {
        if (kIsWeb) {
          final bytes = await photo.readAsBytes();
          setState(() {
            _imageFile = photo;
            _webImage = bytes;
          });
          await _detectFoods(bytes);
        } else {
          setState(() {
            _imageFile = photo;
          });
          final bytes = await photo.readAsBytes();
          await _detectFoods(bytes);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _detectFoods(Uint8List imageBytes) async {
    setState(() {
      _isDetecting = true;
      _detectedFoods = null;
    });

    try {
      // Load available foods from database
      final foods = await _supabaseService.searchFoods();

      // Detect foods from image
      final detected = await _detectionService.detectFoodsFromImage(
        imageBytes,
        foods,
      );

      if (mounted) {
        setState(() {
          _detectedFoods = detected;
          _isDetecting = false;
        });

        if (detected.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No foods detected. Try another image or manual selection.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDetecting = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Detection error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addToMealAndAnalyze() async {
    if (_detectedFoods == null || _detectedFoods!.isEmpty) return;

    final mealProvider = Provider.of<MealProvider>(context, listen: false);
    final profileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);

    // Get smart portions based on health profile
    final profile = profileProvider.userProfile;

    // Clear current meal
    mealProvider.clearMeal();

    // Add detected foods with smart portions
    for (var detected in _detectedFoods!) {
      double grams = detected.estimatedGrams;

      // Adjust portion based on health profile
      if (profile != null) {
        grams = _detectionService.getSmartPortion(
          detected.food,
          profile.diabetes,
          profile.glucoseRange,
          profile.cholesterolConcern,
        );
      }

      mealProvider.addFood(detected.food);
      mealProvider.updateGrams(detected.food.id, grams);
    }

    // Navigate to results screen
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const ResultsScreen(),
        ),
      );
    }
  }

  void _selectFoods() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FoodSearchScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Plate'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Capture your meal',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_imageFile == null) ...[
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt,
                        size: 100,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No image captured yet',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: _takePicture,
                icon: const Icon(Icons.camera),
                label: const Text('Take Picture'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _pickFromGallery,
                icon: const Icon(Icons.photo_library),
                label: const Text('Pick from Gallery'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ] else ...[
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: kIsWeb
                            ? Image.memory(
                                _webImage!,
                                fit: BoxFit.contain,
                                height: 250,
                              )
                            : Image.file(
                                File(_imageFile!.path),
                                fit: BoxFit.contain,
                                height: 250,
                              ),
                      ),
                      const SizedBox(height: 16),
                      if (_isDetecting) ...[
                        const LoadingIndicator(),
                        const SizedBox(height: 8),
                        const Text(
                          'Detecting foods...',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!_isDetecting &&
                          _detectedFoods != null &&
                          _detectedFoods!.isNotEmpty) ...[
                        Card(
                          color: Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.check_circle,
                                        color: Colors.green.shade700),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Foods Detected',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ..._detectedFoods!.map((detected) {
                                  final confidencePercent =
                                      (detected.confidence * 100).toInt();
                                  final confidenceColor =
                                      detected.confidence >= 0.8
                                          ? Colors.green
                                          : detected.confidence >= 0.6
                                              ? Colors.orange
                                              : Colors.grey;

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                detected.food.name,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                '${detected.estimatedGrams.toInt()}g',
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: confidenceColor
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                              color: confidenceColor,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            '$confidencePercent%',
                                            style: TextStyle(
                                              color: confidenceColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      if (!_isDetecting &&
                          _detectedFoods != null &&
                          _detectedFoods!.isEmpty) ...[
                        Card(
                          color: Colors.orange.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: Colors.orange.shade700),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'No foods detected. Try manual selection.',
                                    style: TextStyle(
                                        color: Colors.orange.shade700),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (_detectedFoods != null && _detectedFoods!.isNotEmpty) ...[
                ElevatedButton.icon(
                  onPressed: _addToMealAndAnalyze,
                  icon: const Icon(Icons.analytics),
                  label: const Text('Add All to Meal & Analyze'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              OutlinedButton.icon(
                onPressed: _selectFoods,
                icon: const Icon(Icons.restaurant),
                label: const Text('Manual Food Selection'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _imageFile = null;
                    _webImage = null;
                    _detectedFoods = null;
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Retake Picture'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
