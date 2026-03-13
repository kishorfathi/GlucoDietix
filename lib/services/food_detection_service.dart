import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import '../models/food.dart';
import '../models/user_profile.dart';

/// Food Detection Service
/// Uses on-device ML Kit for food detection (simple and stable)
class FoodDetectionService {
  ImageLabeler? _labeler;
  static const String _visionApiKey =
      String.fromEnvironment('GOOGLE_VISION_API_KEY');
  static const String _yoloServerUrl = String.fromEnvironment(
    'YOLO_SERVER_URL',
    defaultValue: 'http://localhost:8008/detect',
  );

  ImageLabeler _getLabeler() {
    _labeler ??= ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: 0.35),
    );
    return _labeler!;
  }

  /// Detect foods from image and estimate portions.
  Future<List<DetectedFood>> detectFoodsFromImage(
    List<Food> availableFoods, {
    required Uint8List imageBytes,
    required String? imagePath,
  }) async {
    if (availableFoods.isEmpty) return [];

    try {
      if (imagePath != null && imagePath.isNotEmpty) {
        print('📸 Processing image with ML Kit...');
        
        final input = InputImage.fromFilePath(imagePath);
        final labels = await _getLabeler().processImage(input);
        
        final signals = labels
            .map((label) => _LabelSignal(
                  label: label.label,
                  confidence: label.confidence,
                ))
            .toList();

        if (signals.isNotEmpty) {
          print('✅ Detected ${signals.length} objects with ML Kit');
          for (final label in signals) {
            print('   - ${label.label} (${(label.confidence * 100).toStringAsFixed(1)}%)');
          }

          return _matchSignalsToFoods(
            signals,
            availableFoods,
            detectionMethod: 'ML Kit (On-device)',
          );
        }
      }
    } catch (e) {
      print('❌ ML Kit detection error: $e');
    }

    return [];
  }

  /// Detect foods from an InputImage (live camera stream).
  Future<List<DetectedFood>> detectFoodsFromInputImage(
    List<Food> availableFoods,
    InputImage inputImage,
  ) async {
    if (availableFoods.isEmpty) return [];

    try {
      final labels = await _getLabeler().processImage(inputImage);
      final signals = labels
          .map((label) => _LabelSignal(
                label: label.label,
                confidence: label.confidence,
              ))
          .toList();

      if (signals.isEmpty) return [];

      return _matchSignalsToFoods(
        signals,
        availableFoods,
        detectionMethod: 'ML Kit (Live)',
      );
    } catch (e) {
      return [];
    }
  }

  /// Detect foods on web using Google Vision API.
  Future<List<DetectedFood>> detectFoodsFromWebBytes(
    List<Food> availableFoods,
    Uint8List imageBytes,
  ) async {
    if (availableFoods.isEmpty) return [];
    final yoloSignals = await _detectWithYoloServer(imageBytes);
    if (yoloSignals.isNotEmpty) {
      return _matchSignalsToFoods(
        yoloSignals,
        availableFoods,
        detectionMethod: 'YOLOv8 (Local)',
      );
    }

    if (_visionApiKey.isEmpty) return [];

    final base64Image = base64Encode(imageBytes);
    final url =
        Uri.parse('https://vision.googleapis.com/v1/images:annotate?key=$_visionApiKey');
    final body = jsonEncode({
      'requests': [
        {
          'image': {'content': base64Image},
          'features': [
            {'type': 'LABEL_DETECTION', 'maxResults': 10}
          ]
        }
      ]
    });

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final responses = data['responses'] as List<dynamic>? ?? [];
      if (responses.isEmpty) return [];

      final annotations =
          responses.first['labelAnnotations'] as List<dynamic>? ?? [];
      if (annotations.isEmpty) return [];

      final signals = annotations.map((item) {
        return _LabelSignal(
          label: item['description'] as String? ?? '',
          confidence: (item['score'] as num?)?.toDouble() ?? 0,
        );
      }).where((signal) => signal.label.isNotEmpty).toList();

      if (signals.isEmpty) return [];

      return _matchSignalsToFoods(
        signals,
        availableFoods,
        detectionMethod: 'Google Vision (Web)',
      );
    } catch (e) {
      return [];
    }
  }

  Future<List<_LabelSignal>> _detectWithYoloServer(Uint8List imageBytes) async {
    if (_yoloServerUrl.isEmpty) return [];

    try {
      final response = await http.post(
        Uri.parse(_yoloServerUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Encode(imageBytes),
          'topK': 10,
        }),
      );

      if (response.statusCode != 200) {
        return [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final detections = data['detections'] as List<dynamic>? ?? [];
      if (detections.isEmpty) return [];

      return detections.map((item) {
        return _LabelSignal(
          label: item['label'] as String? ?? '',
          confidence: (item['confidence'] as num?)?.toDouble() ?? 0,
        );
      }).where((signal) => signal.label.isNotEmpty).toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> dispose() async {
    if (_labeler != null) {
      await _labeler!.close();
      _labeler = null;
    }
  }

  List<DetectedFood> _matchSignalsToFoods(
    List<_LabelSignal> labels,
    List<Food> foods, {
    required String detectionMethod,
  }) {
    final candidates = <String, _CandidateScore>{};

    for (final label in labels) {
      final labelText = _normalize(label.label);
      if (labelText.length < 3) continue;

      for (final food in foods) {
        final score = _scoreFoodAgainstLabel(food, labelText, label.confidence);
        if (score <= 0) continue;

        final existing = candidates[food.id];
        if (existing == null) {
          candidates[food.id] = _CandidateScore(
            food: food,
            score: score,
            bestConfidence: label.confidence,
            bestLabel: label.label,
          );
        } else {
          candidates[food.id] = _CandidateScore(
            food: existing.food,
            score: existing.score + score,
            bestConfidence: label.confidence > existing.bestConfidence
                ? label.confidence
                : existing.bestConfidence,
            bestLabel: label.confidence > existing.bestConfidence
                ? label.label
                : existing.bestLabel,
          );
        }
      }
    }

    final ranked = candidates.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    return ranked.take(6).map((candidate) {
      return DetectedFood(
        food: candidate.food,
        estimatedGrams:
            _estimatePortion(candidate.food, candidate.bestConfidence),
        confidence: candidate.bestConfidence.clamp(0.35, 0.99).toDouble(),
        detectionMethod: detectionMethod,
        sourceLabel: candidate.bestLabel,
      );
    }).toList();
  }

  double _scoreFoodAgainstLabel(Food food, String label, double confidence) {
    final foodText = _foodSearchText(food);
    double score = 0;

    if (foodText.contains(label)) {
      score += confidence * 1.5;
    }

    final words = label.split(' ').where((w) => w.length >= 3);
    final matchedWords = words.where(foodText.contains).length;
    if (matchedWords > 0) {
      score += confidence * (0.6 + (matchedWords * 0.25));
    }

    for (final entry in _labelIntentToFoodKeywords.entries) {
      if (!label.contains(entry.key)) continue;
      final matchesKeyword = entry.value.any(foodText.contains);
      if (matchesKeyword) {
        score += confidence * 1.0;
      }
    }

    return score;
  }

  String _foodSearchText(Food food) {
    return _normalize([
      food.name,
      food.nameSinhala ?? '',
      food.nameTamil ?? '',
      food.category,
      food.subCategory ?? '',
    ].join(' '));
  }

  String _normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  double _estimatePortion(Food food, double confidence) {
    double grams = _estimateBasePortionByCategory(food);

    if (confidence < 0.5) {
      grams *= 0.85;
    } else if (confidence > 0.8) {
      grams *= 1.1;
    }

    return grams.clamp(20.0, 450.0).toDouble();
  }

  double _estimateBasePortionByCategory(Food food) {
    if (food.servingSizeG > 0) return food.servingSizeG;

    final category = food.category.toLowerCase();
    if (category.contains('staple')) return 180;
    if (category.contains('curr')) return 120;
    if (category.contains('condiment') || category.contains('sambol')) {
      return 35;
    }
    if (category.contains('fruit')) return 130;
    if (category.contains('dessert')) return 90;
    if (category.contains('beverage')) return 220;
    return 100;
  }

  /// Detect from search query (manual selection helper)
  Future<List<DetectedFood>> detectFromQuery(
    String query,
    List<Food> availableFoods,
  ) async {
    final detected = <DetectedFood>[];
    final queryLower = query.toLowerCase();

    final matches = availableFoods
        .where((f) =>
            f.name.toLowerCase().contains(queryLower) ||
            (f.nameSinhala?.toLowerCase().contains(queryLower) ?? false) ||
            (f.nameTamil?.toLowerCase().contains(queryLower) ?? false))
        .take(5);

    for (final food in matches) {
      detected.add(
        DetectedFood(
          food: food,
          estimatedGrams: _estimateBasePortionByCategory(food),
          confidence: 0.9,
          detectionMethod: 'Text search',
          sourceLabel: query,
        ),
      );
    }

    return detected;
  }

  /// Personalized portion recommendation based on health profile.
  double getSmartPortion(
    Food food,
    bool hasDiabetes,
    String glucoseRange,
    bool cholesterolConcern, {
    double? weightKg,
    double? heightCm,
    double? targetGlucoseMax,
  }) {
    double grams = _estimateBasePortionByCategory(food);
    final gi = food.glycemicIndex ?? 0;

    if (hasDiabetes || glucoseRange.toLowerCase() == 'high') {
      if (gi >= 70) {
        grams *= 0.6;
      } else if (gi >= 55) {
        grams *= 0.78;
      }

      if (food.carbs100g >= 45) {
        grams *= 0.7;
      } else if (food.carbs100g >= 30) {
        grams *= 0.85;
      }

      if ((targetGlucoseMax ?? 140) <= 110 && food.carbs100g > 20) {
        grams *= 0.9;
      }
    }

    if (cholesterolConcern) {
      if (food.fat100g >= 15) grams *= 0.75;
      if ((food.cholesterolMg ?? 0) >= 80) grams *= 0.85;
    }

    if (weightKg != null && heightCm != null && heightCm > 0) {
      final heightM = heightCm / 100;
      final bmi = weightKg / (heightM * heightM);
      if (bmi >= 27) grams *= 0.9;
      if (bmi <= 20) grams *= 1.05;
    }

    final rounded = (grams / 5).round() * 5.0;
    return rounded.clamp(20.0, 400.0).toDouble();
  }

  double getSmartPortionFromProfile(Food food, UserProfile? profile) {
    if (profile == null) {
      return _estimateBasePortionByCategory(food);
    }

    return getSmartPortion(
      food,
      profile.diabetes,
      profile.glucoseRange,
      profile.cholesterolConcern,
      weightKg: profile.weightKg,
      heightCm: profile.heightCm,
      targetGlucoseMax: profile.targetGlucoseMax,
    );
  }
}

class _LabelSignal {
  final String label;
  final double confidence;

  _LabelSignal({
    required this.label,
    required this.confidence,
  });
}

class _CandidateScore {
  final Food food;
  final double score;
  final double bestConfidence;
  final String bestLabel;

  _CandidateScore({
    required this.food,
    required this.score,
    required this.bestConfidence,
    required this.bestLabel,
  });
}

const Map<String, List<String>> _labelIntentToFoodKeywords = {
  'rice': ['rice', 'bhat', 'bath', 'staples'],
  'curry': ['curry', 'curries', 'gravy'],
  'fish': ['fish', 'seafood'],
  'chicken': ['chicken', 'poultry'],
  'egg': ['egg'],
  'bread': ['bread', 'roti', 'hopper', 'pittu', 'string hopper'],
  'vegetable': ['vegetable', 'mallum', 'greens', 'salad'],
  'fruit': ['fruit', 'mango', 'banana', 'papaya'],
  'bean': ['dhal', 'lentil', 'bean'],
  'dessert': ['dessert', 'sweet', 'wattalappan', 'kavum'],
  'noodle': ['noodle', 'pasta'],
  'soup': ['soup'],
};

/// Detected food with portion estimation.
class DetectedFood {
  final Food food;
  final double estimatedGrams;
  final double confidence;
  final String detectionMethod;
  final String sourceLabel;

  DetectedFood({
    required this.food,
    required this.estimatedGrams,
    required this.confidence,
    required this.detectionMethod,
    required this.sourceLabel,
  });

  String get confidencePercent => '${(confidence * 100).toInt()}%';
}
