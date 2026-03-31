import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/glucodietix_detection_service.dart';
import '../services/glucodietix_nutrition_service.dart';

/// GlucoDietix Home Screen
/// Main screen with food detection and portion guidance
class GlucoDietixHomeScreen extends StatefulWidget {
  const GlucoDietixHomeScreen({super.key});

  @override
  State<GlucoDietixHomeScreen> createState() => _GlucoDietixHomeScreenState();
}

class _GlucoDietixHomeScreenState extends State<GlucoDietixHomeScreen> {
  final _detectionService = GlucoDietixDetectionService();
  final _nutritionService = GlucoDietixNutritionService();

  File? _selectedImage;
  List<String> _detectedFoods = [];
  List<FoodNutrition> _nutritionData = [];
  bool _isLoading = false;
  bool _backendHealthy = false;

  @override
  void initState() {
    super.initState();
    _checkBackend();
  }

  /// Check if backend is running
  Future<void> _checkBackend() async {
    final isHealthy = await _detectionService.checkBackendHealth();
    setState(() {
      _backendHealthy = isHealthy;
    });
  }

  /// Pick image from camera
  Future<void> _captureFromCamera() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      await _processImage();
    }
  }

  /// Pick image from gallery
  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
      await _processImage();
    }
  }

  /// Process the selected image
  Future<void> _processImage() async {
    if (_selectedImage == null) return;

    setState(() {
      _isLoading = true;
      _detectedFoods = [];
      _nutritionData = [];
    });

    try {
      // Step 1: Detect foods using YOLO
      final foods =
          await _detectionService.detectFoodsFromFile(_selectedImage!);

      setState(() {
        _detectedFoods = foods;
      });

      if (foods.isEmpty) {
        _showMessage('No foods detected. Try another image.');
        return;
      }

      // Step 2: Get nutrition data from Supabase
      final nutrition =
          await _nutritionService.getNutritionForMultipleFoods(foods);

      setState(() {
        _nutritionData = nutrition;
      });

      if (nutrition.isEmpty) {
        _showMessage(
            'Foods detected but no nutrition data available in database.');
      }
    } catch (e) {
      _showMessage('Error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Calculate total calories
  double get _totalCalories {
    return _nutritionData.fold(0.0, (sum, item) => sum + item.energyKcal);
  }

  /// Show message to user
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  /// Open AR Portion Guidance
  Future<void> _openARGuidance() async {
    if (_nutritionData.isEmpty) {
      _showMessage('Please detect foods first');
      return;
    }

    // Create URL with food data as parameters
    final foodNames = _nutritionData.map((f) => f.name).join(',');
    final portions = _nutritionData.map((f) => f.portionG).join(',');

    // URL to WebAR page (you can host this on GitHub Pages or local server)
    final arUrl = Uri.parse(
      'http://localhost:8080/ar_portion.html?foods=$foodNames&portions=$portions',
    );

    if (await canLaunchUrl(arUrl)) {
      await launchUrl(arUrl, mode: LaunchMode.externalApplication);
    } else {
      _showMessage('Could not open AR view');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.fastfood, color: Colors.white),
            SizedBox(width: 8),
            Text('GlucoDietix'),
          ],
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(
              _backendHealthy ? Icons.check_circle : Icons.error,
              color: _backendHealthy ? Colors.green : Colors.red,
            ),
            onPressed: _checkBackend,
            tooltip: _backendHealthy ? 'Backend Online' : 'Backend Offline',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Card(
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.restaurant_menu,
                        size: 48, color: Colors.green[700]),
                    const SizedBox(height: 8),
                    Text(
                      'Diabetic Portion Manager',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Scan your plate and get portion guidance',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Scan Plate Button
            ElevatedButton.icon(
              onPressed: _isLoading
                  ? null
                  : () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Take Photo'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _captureFromCamera();
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Choose from Gallery'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickFromGallery();
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
              icon: const Icon(Icons.camera),
              label: const Text('Scan Plate'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            // Selected Image
            if (_selectedImage != null) ...[
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Image.file(
                      _selectedImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Selected Image',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Loading Indicator
            if (_isLoading) ...[
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Analyzing food...'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Detected Foods
            if (_detectedFoods.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Detected Foods',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _detectedFoods
                            .map((food) => Chip(
                                  label: Text(food),
                                  backgroundColor: Colors.green[100],
                                ))
                            .toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Nutrition Information
            if (_nutritionData.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nutrition Information',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const Divider(),
                      ..._nutritionData
                          .map((food) => _buildNutritionCard(food)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Total Calories
              Card(
                color: Colors.orange[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Calories',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      Text(
                        '${_totalCalories.toStringAsFixed(1)} kcal',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.orange[900],
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // AR Guidance Button
              ElevatedButton.icon(
                onPressed: _openARGuidance,
                icon: const Icon(Icons.view_in_ar),
                label: const Text('View AR Portion Guidance'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionCard(FoodNutrition food) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              food.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildNutrientInfo(
                      'Portion', '${food.portionG.toInt()}g'),
                ),
                Expanded(
                  child: _buildNutrientInfo(
                      'Calories', '${food.energyKcal.toInt()} kcal'),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _buildNutrientInfo('Protein', '${food.proteinG}g'),
                ),
                Expanded(
                  child: _buildNutrientInfo('Fat', '${food.fatG}g'),
                ),
                Expanded(
                  child: _buildNutrientInfo('Carbs', '${food.carbohydrateG}g'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber[50],
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.amber[900]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      food.diabeticGuideline,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.amber[900],
                      ),
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

  Widget _buildNutrientInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
