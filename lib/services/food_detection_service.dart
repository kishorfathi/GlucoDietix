import 'dart:typed_data';
import '../models/food.dart';

/// Food Detection Service
/// Detects foods from images and estimates portions
///
/// NOTE: This is a MOCK implementation for demonstration.
/// For production, integrate with ML services like:
/// - Google Cloud Vision API
/// - AWS Rekognition
/// - Custom TensorFlow/ML model
/// - Clarifai Food Model
class FoodDetectionService {
  /// Detect foods from image
  /// Returns list of detected foods with estimated portions
  Future<List<DetectedFood>> detectFoodsFromImage(
    Uint8List imageBytes,
    List<Food> availableFoods,
  ) async {
    // Simulate ML processing delay
    await Future.delayed(const Duration(seconds: 2));

    // MOCK IMPLEMENTATION
    // In production, send image to ML service and get results
    // Example with Google Vision:
    // final vision = VisionApi(credentials);
    // final response = await vision.images.annotate(imageBytes);
    // final labels = response.labelAnnotations;

    // For demo, detect common Sri Lankan meal items
    final detectedFoods = <DetectedFood>[];

    // Simulate detecting rice (very common in Sri Lankan meals)
    final rice = availableFoods.firstWhere(
      (f) => f.name.toLowerCase().contains('white rice'),
      orElse: () => availableFoods.first,
    );
    detectedFoods.add(DetectedFood(
      food: rice,
      estimatedGrams: 250, // Typical plate portion
      confidence: 0.95,
      detectionMethod: 'Visual Recognition',
    ));

    // Try to detect curry
    final curry = availableFoods
        .where(
          (f) => f.category == 'Curries',
        )
        .take(2);

    for (var c in curry) {
      detectedFoods.add(DetectedFood(
        food: c,
        estimatedGrams: 120, // Typical curry portion
        confidence: 0.85,
        detectionMethod: 'Visual Recognition',
      ));
    }

    // Try to detect sambol
    final sambol = availableFoods.firstWhere(
      (f) => f.name.toLowerCase().contains('sambol'),
      orElse: () => availableFoods.first,
    );
    if (sambol.category == 'Condiments') {
      detectedFoods.add(DetectedFood(
        food: sambol,
        estimatedGrams: 30, // Small portion
        confidence: 0.75,
        detectionMethod: 'Visual Recognition',
      ));
    }

    return detectedFoods;
  }

  /// Detect from search query (manual selection helper)
  Future<List<DetectedFood>> detectFromQuery(
    String query,
    List<Food> availableFoods,
  ) async {
    await Future.delayed(const Duration(milliseconds: 500));

    final detected = <DetectedFood>[];
    final queryLower = query.toLowerCase();

    // Find matching foods
    final matches = availableFoods
        .where((f) =>
            f.name.toLowerCase().contains(queryLower) ||
            (f.nameSinhala?.toLowerCase().contains(queryLower) ?? false) ||
            (f.nameTamil?.toLowerCase().contains(queryLower) ?? false))
        .take(5);

    for (var food in matches) {
      // Estimate portion based on food type
      double grams;
      if (food.category == 'Staples') {
        grams = 200;
      } else if (food.category == 'Curries') {
        grams = 120;
      } else if (food.category == 'Condiments') {
        grams = 30;
      } else if (food.category == 'Fruits') {
        grams = 150;
      } else {
        grams = 100;
      }

      detected.add(DetectedFood(
        food: food,
        estimatedGrams: grams,
        confidence: 0.9,
        detectionMethod: 'Text Search',
      ));
    }

    return detected;
  }

  /// Get smart portion recommendation based on health profile
  double getSmartPortion(
    Food food,
    bool hasDiabetes,
    String glucoseRange,
    bool cholesterolConcern,
  ) {
    double baseGrams = food.servingSizeG;

    // Adjust for diabetes
    if (hasDiabetes || glucoseRange == 'high') {
      // High GI foods - reduce significantly
      if ((food.glycemicIndex ?? 0) > 70) {
        baseGrams *= 0.6; // 40% reduction
      }
      // High carb foods - reduce moderately
      else if (food.carbs100g > 30) {
        baseGrams *= 0.75; // 25% reduction
      }
    }

    // Adjust for cholesterol
    if (cholesterolConcern) {
      // High fat foods - reduce
      if (food.fat100g > 15) {
        baseGrams *= 0.7; // 30% reduction
      }
    }

    return baseGrams;
  }
}

/// Detected Food with portion estimation
class DetectedFood {
  final Food food;
  final double estimatedGrams;
  final double confidence; // 0.0 to 1.0
  final String detectionMethod;

  DetectedFood({
    required this.food,
    required this.estimatedGrams,
    required this.confidence,
    required this.detectionMethod,
  });

  String get confidencePercent => '${(confidence * 100).toInt()}%';
}
