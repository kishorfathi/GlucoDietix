import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
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
    defaultValue: 'http://127.0.0.1:5000/detect',
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
      // Try YOLO server first (primary ML path for mobile + desktop)
      if (imageBytes.isNotEmpty) {
        final yoloSignals = await _detectWithYoloServer(imageBytes);
        print('🔍 YOLO returned ${yoloSignals.length} detections');
        if (yoloSignals.isNotEmpty) {
          print('✅ Detected ${yoloSignals.length} objects with YOLO:');
          for (final signal in yoloSignals.take(10)) {
            print(
                '   - ${signal.label} (${(signal.confidence * 100).toStringAsFixed(1)}%)');
          }
          final matched = _matchSignalsToFoods(
            yoloSignals,
            availableFoods,
            detectionMethod: 'YOLOv11 (Server)',
          );
          print('📋 Matched ${matched.length} foods from YOLO detections');
          return matched;
        } else {
          print(
              '⚠️ YOLO returned 0 detections - image may not contain recognizable food');
        }
      }

      // ML Kit fallback only on mobile platforms (not desktop)
      if (imagePath != null && imagePath.isNotEmpty && !kIsWeb) {
        try {
          print('📸 Processing image with ML Kit (mobile fallback)...');

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
              print(
                  '   - ${label.label} (${(label.confidence * 100).toStringAsFixed(1)}%)');
            }

            return _matchSignalsToFoods(
              signals,
              availableFoods,
              detectionMethod: 'ML Kit (On-device)',
            );
          }
        } catch (e) {
          print('ℹ️  ML Kit not available on this platform: $e');
        }
      }
    } catch (e) {
      print('❌ Detection error: $e');
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
    final url = Uri.parse(
        'https://vision.googleapis.com/v1/images:annotate?key=$_visionApiKey');
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

      final signals = annotations
          .map((item) {
            return _LabelSignal(
              label: item['description'] as String? ?? '',
              confidence: (item['score'] as num?)?.toDouble() ?? 0,
            );
          })
          .where((signal) => signal.label.isNotEmpty)
          .toList();

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

    final urlsToTry = _buildYoloUrlsToTry(_yoloServerUrl);

    for (final url in urlsToTry) {
      try {
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'image': base64Encode(imageBytes),
            'topK': 25,
          }),
        );

        if (response.statusCode != 200) {
          continue;
        }

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final detections = data['detections'] as List<dynamic>? ?? [];
        if (detections.isEmpty) return [];

        return detections
            .map((item) {
              return _LabelSignal(
                label: item['label'] as String? ?? '',
                confidence: (item['confidence'] as num?)?.toDouble() ?? 0,
              );
            })
            .where((signal) => signal.label.isNotEmpty)
            .toList();
      } catch (_) {
        continue;
      }
    }

    return [];
  }

  List<String> _buildYoloUrlsToTry(String baseUrl) {
    final urls = <String>{baseUrl};

    if (baseUrl.contains('localhost')) {
      urls.add(baseUrl.replaceAll('localhost', '127.0.0.1'));
    }
    if (baseUrl.contains('127.0.0.1')) {
      urls.add(baseUrl.replaceAll('127.0.0.1', 'localhost'));
    }

    return urls.toList();
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
    if (!_hasPlateSpecificEvidence(labels)) {
      return const [];
    }

    final candidates = <String, _CandidateScore>{};

    for (final label in labels) {
      final normalizedSignal = _normalize(_fixCommonTypos(label.label));
      if (_ignoredGenericLabels.contains(normalizedSignal)) {
        continue;
      }
      if (label.confidence < 0.001) {
        continue;
      }

      final expandedLabels = _expandSignalLabels(label.label);
      if (expandedLabels.isEmpty) continue;

      for (final food in foods) {
        double score = 0;
        for (final expandedLabel in expandedLabels) {
          score +=
              _scoreFoodAgainstLabel(food, expandedLabel, label.confidence);
        }
        if (score <= 0) {
          continue;
        }

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

    final refined = _preferPreparedPlateItems(ranked);

    if (refined.isEmpty) {
      return const [];
    }

    final bestScore = refined.first.score;
    final shortlisted = refined
        .where((candidate) => candidate.score >= (bestScore * 0.25))
        .toList();

    return shortlisted.take(6).map((candidate) {
      return DetectedFood(
        food: candidate.food,
        estimatedGrams:
            _estimatePortion(candidate.food, candidate.bestConfidence),
        confidence: candidate.bestConfidence.clamp(0.001, 0.99).toDouble(),
        detectionMethod: detectionMethod,
        sourceLabel: candidate.bestLabel,
      );
    }).toList();
  }

  bool _hasPlateSpecificEvidence(List<_LabelSignal> labels) {
    var maxConfidence = 0.0;
    var foundFoodToken = false;
    var foodTokensFound = <String>[];

    for (final signal in labels) {
      final normalized = _normalize(_fixCommonTypos(signal.label));
      if (signal.confidence > maxConfidence) {
        maxConfidence = signal.confidence;
      }

      if (_ignoredGenericLabels.contains(normalized)) {
        continue;
      }

      final hasFoodSpecificToken = _plateSpecificEvidenceTokens
          .any((token) => normalized.contains(token));
      if (hasFoodSpecificToken && signal.confidence >= 0.001) {
        foundFoodToken = true;
        final matchedTokens = _plateSpecificEvidenceTokens
            .where((token) => normalized.contains(token))
            .toList();
        foodTokensFound.addAll(matchedTokens);
        print(
            '✓ Found food token in "${signal.label}": ${matchedTokens.join(", ")}');
        return true;
      }
    }

    // Allow very confident detections even if tokens are uncommon.
    final allowByConfidence = maxConfidence >= 0.01;
    if (allowByConfidence) {
      print(
          '✓ Accepting due to high confidence: ${(maxConfidence * 100).toStringAsFixed(1)}%');
      return true;
    }

    print(
        '✗ No plate-specific evidence found (max confidence: ${(maxConfidence * 100).toStringAsFixed(1)}%)');
    print(
        '  Required: food tokens (${_plateSpecificEvidenceTokens.take(5).join(", ")}, ...) with ≥0.1% confidence OR any detection ≥1% confidence');
    return false;
  }

  List<_CandidateScore> _preferPreparedPlateItems(
      List<_CandidateScore> ranked) {
    if (ranked.length <= 1) return ranked;

    final preparedByToken = <String, _CandidateScore>{};
    final rawByToken = <String, _CandidateScore>{};

    for (final candidate in ranked) {
      final tokens = _dishTokens(candidate.food);
      if (tokens.isEmpty) continue;

      final isPrepared = _isPreparedDish(candidate.food);
      for (final token in tokens) {
        final target = isPrepared ? preparedByToken : rawByToken;
        final existing = target[token];
        if (existing == null || candidate.score > existing.score) {
          target[token] = candidate;
        }
      }
    }

    final filtered = <_CandidateScore>[];
    for (final candidate in ranked) {
      if (!_isLikelyRawIngredient(candidate.food)) {
        filtered.add(candidate);
        continue;
      }

      final tokens = _dishTokens(candidate.food);
      var suppress = false;
      for (final token in tokens) {
        final prepared = preparedByToken[token];
        if (prepared == null) continue;

        // If a prepared dish for the same ingredient exists, prefer it.
        if (prepared.score >= candidate.score * 0.5) {
          suppress = true;
          break;
        }
      }

      if (!suppress) {
        filtered.add(candidate);
      }
    }

    return filtered;
  }

  bool _isPreparedDish(Food food) {
    final text = _foodSearchText(food);
    final category = food.category.toLowerCase();
    return category.contains('curr') ||
        category.contains('mallum') ||
        category.contains('condiment') ||
        text.contains(' curry') ||
        text.contains('mallum') ||
        text.contains('sambol') ||
        text.contains('papadam') ||
        text.contains('papadum') ||
        text.contains('poppadom');
  }

  bool _isLikelyRawIngredient(Food food) {
    final text = _foodSearchText(food);
    final category = food.category.toLowerCase();
    if (_isPreparedDish(food)) return false;

    return category.contains('vegetable') ||
        category.contains('fruit') ||
        category.contains('greens') ||
        text.contains(' tomato') ||
        text.startsWith('tomato ') ||
        text == 'tomato' ||
        text.contains(' spinach') ||
        text.startsWith('spinach ') ||
        text == 'spinach' ||
        text.contains(' pumpkin') ||
        text.startsWith('pumpkin ') ||
        text == 'pumpkin' ||
        text.contains(' beans ') ||
        text.startsWith('beans ');
  }

  List<String> _dishTokens(Food food) {
    final text = _foodSearchText(food);
    final tokens = text.split(' ').where((w) => w.length >= 4).toSet();
    tokens.removeWhere((w) => _descriptorWords.contains(w));
    tokens.removeAll(const {
      'curry',
      'mallum',
      'sambol',
      'boiled',
      'fried',
      'thick',
      'watery',
      'cooked',
      'green',
      'white',
      'red',
      'rice',
    });
    return tokens.toList();
  }

  List<String> _expandSignalLabels(String rawLabel) {
    final normalized = _normalize(_fixCommonTypos(rawLabel));
    if (normalized.length < 3) {
      return const [];
    }

    final expanded = <String>{normalized};
    expanded.addAll(_expandCompositeFoodLabel(normalized));

    for (final entry in _yoloLabelAliases.entries) {
      if (normalized == entry.key || normalized.contains(entry.key)) {
        expanded
            .addAll(entry.value.map(_normalize).where((v) => v.length >= 3));
      }
    }

    for (final entry in _specificFoodAliases.entries) {
      if (normalized == entry.key || normalized.contains(entry.key)) {
        expanded
            .addAll(entry.value.map(_normalize).where((v) => v.length >= 3));
      }
    }

    return expanded.toList();
  }

  List<String> _expandCompositeFoodLabel(String normalized) {
    final expanded = <String>{};
    final words = normalized.split(' ').where((w) => w.length >= 3).toList();
    if (words.isEmpty) return const [];

    expanded.addAll(words.where((w) => !_descriptorWords.contains(w)));

    final coreWords =
        words.where((w) => !_descriptorWords.contains(w)).toList();
    if (coreWords.isNotEmpty) {
      expanded.add(coreWords.join(' '));
    }

    if (normalized.contains('rice')) expanded.addAll(['rice', 'boiled rice']);
    if (normalized.contains('milk rice')) {
      expanded.addAll(['milk rice', 'kiribath']);
    }
    if (normalized.contains('fried rice')) expanded.add('fried rice');
    if (normalized.contains('bread')) expanded.addAll(['bread', 'bun']);
    if (normalized.contains('pizza')) expanded.add('pizza');
    if (normalized.contains('kottu')) expanded.addAll(['kottu', 'roti']);
    if (normalized.contains('hopper')) expanded.addAll(['hopper', 'appa']);
    if (normalized.contains('string hopper')) {
      expanded.addAll(['string hopper', 'idiyappam']);
    }
    if (normalized.contains('noodle')) expanded.addAll(['noodle', 'noodles']);
    if (normalized.contains('curry')) expanded.add('curry');
    if (normalized.contains('salad')) expanded.add('salad');
    if (normalized.contains('boiled')) expanded.add('boiled');
    if (normalized.contains('tempered')) expanded.add('tempered');
    if (normalized.contains('fruit')) expanded.add('fruit');
    if (normalized.contains('banana')) expanded.add('banana');
    if (normalized.contains('mango')) expanded.add('mango');
    if (normalized.contains('apple')) expanded.add('apple');
    if (normalized.contains('milk')) expanded.add('milk');
    if (normalized.contains('tea')) expanded.add('tea');
    if (normalized.contains('coffee')) expanded.add('coffee');
    if (normalized.contains('chicken')) expanded.add('chicken');
    if (normalized.contains('fish')) expanded.add('fish');
    if (normalized.contains('egg')) expanded.add('egg');

    return expanded.where((v) => v.length >= 3).toList();
  }

  String _fixCommonTypos(String value) {
    final lower = value.toLowerCase();
    return lower
        .replaceAll('bolied', 'boiled')
        .replaceAll('boild', 'boiled')
        .replaceAll('sambha', 'samba')
        .replaceAll('parippu', 'dhal')
        .replaceAll('dal', 'dhal')
        .replaceAll('pappadam', 'papadam')
        .replaceAll('papadum', 'papadam')
        .replaceAll('poppadom', 'papadam')
        .replaceAll('mange', 'mango')
        .replaceAll('mozerella', 'mozzarella')
        .replaceAll('thosai', 'dosa');
  }

  double _scoreFoodAgainstLabel(Food food, String label, double confidence) {
    final foodText = _foodSearchText(food);
    double score = 0;

    if (foodText == label) {
      score += confidence * 3.0;
    }

    if (foodText.startsWith('$label ') || foodText.endsWith(' $label')) {
      score += confidence * 1.8;
    }

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

const Set<String> _descriptorWords = {
  'boiled',
  'fried',
  'white',
  'red',
  'yellow',
  'thick',
  'watery',
  'fresh',
  'instant',
  'mixed',
  'liquid',
  'full',
  'low',
  'fat',
  'non',
  'flavored',
  'immature',
  'plain',
  'black',
  'green',
  'china',
  'royal',
  'delicious',
  'fuji',
  'first',
  'second',
  'st',
  'nd',
  'with',
  'and',
};

const Map<String, List<String>> _specificFoodAliases = {
  'rice basmati boiled': ['basmati rice', 'boiled rice', 'rice'],
  'rice keeri samba boiled': ['keeri samba', 'boiled rice', 'rice'],
  'rice red kekulu boiled': ['red kekulu rice', 'red rice', 'rice'],
  'rice samba boiled': ['samba rice', 'boiled rice', 'rice'],
  'rice white kekulu boiled': ['white kekulu rice', 'white rice', 'rice'],
  'rice white nadu boiled': ['white nadu rice', 'white rice', 'rice'],
  'fried rice': ['rice'],
  'milk rice white': ['milk rice', 'kiribath', 'rice'],
  'milk rice red': ['milk rice', 'kiribath', 'red rice'],
  'big mac burger': ['burger', 'bun', 'beef'],
  'pepperoni pizza': ['pizza', 'pepperoni'],
  'sausage pizza': ['pizza', 'sausage'],
  'cheese pizza': ['pizza', 'cheese'],
  'chapathi': ['roti', 'flatbread'],
  'paratha': ['roti', 'flatbread'],
  'thosai': ['dosa', 'flatbread'],
  'naan': ['flatbread', 'bread'],
  'coconut roti': ['roti', 'coconut', 'bread'],
  'vegetable rotti': ['roti', 'vegetable'],
  'chicken kottu roti': ['kottu', 'roti', 'chicken'],
  'fried noodles': ['noodles'],
  'boiled noodles': ['noodles'],
  'instant noodles': ['noodles'],
  'string hoppers white': ['string hoppers', 'idiyappam'],
  'string hoppers red': ['string hoppers', 'idiyappam'],
  'hoppers': ['hopper', 'appa'],
  'pasta boiled': ['pasta'],
  'dhal curry thick': ['dhal curry', 'lentil curry'],
  'dhal curry': ['dhal curry', 'lentil curry', 'parippu'],
  'dhal curry watery': ['dhal curry', 'lentil curry'],
  'dhal curry spinach': ['dhal curry', 'lentil curry', 'spinach'],
  'beans curry': ['green bean curry', 'bonchi curry', 'bean curry'],
  'green bean curry': ['beans curry', 'bonchi curry', 'bean curry'],
  'beetroot curry': ['beetroot curry', 'beet curry', 'vegetable curry'],
  'beetroot': ['beetroot curry', 'vegetable curry'],
  'beans': ['green bean curry', 'beans curry', 'vegetable curry'],
  'green beans': ['green bean curry', 'beans curry', 'vegetable curry'],
  'lentil': ['dhal curry thick', 'dhal curry', 'parippu'],
  'dhal': ['dhal curry thick', 'dhal curry', 'parippu'],
  'dal': ['dhal curry thick', 'dhal curry', 'parippu'],
  'cracker': ['papadam', 'papadum', 'poppadom'],
  'fried cracker': ['papadam', 'papadum', 'poppadom'],
  'papadum': ['papadam', 'papadum', 'poppadom'],
  'poppadom': ['papadam', 'papadum', 'poppadom'],
  'mallum': ['gotukola mallum', 'mukunuwenna mallum', 'pol mallum'],
  'papadam': ['papadam', 'papadum', 'poppadom', 'fried cracker'],
  'fish ambul thiyal': ['fish curry', 'fish'],
  'fish white curry': ['fish curry', 'fish'],
  'canned salmon mackeral curry': ['fish curry', 'salmon', 'mackerel'],
  'devilled fish': ['fish', 'fried fish'],
  'deep fried fish': ['fried fish', 'fish'],
  'chicken curry': ['chicken'],
  'devilled chicken': ['chicken'],
  'fried chicken': ['chicken'],
  'kfc fried chicken': ['fried chicken', 'chicken'],
  'mcdonalds chicken nuggets': ['chicken nuggets', 'fried chicken'],
  'egg bulls eye': ['fried egg', 'egg'],
  'omelet': ['egg'],
  'full cream liquid milk fresh milk': ['fresh milk', 'full cream milk'],
  'low fat fresh milk': ['fresh milk', 'low fat milk'],
  'full cream milk tea': ['milk tea', 'tea'],
  'non fat milk tea': ['milk tea', 'tea'],
  'malted drink nestomalt': ['malted drink', 'milk drink'],
  'mozerella cheese': ['mozzarella cheese', 'cheese'],
  'paneer cottage cheese': ['paneer', 'cottage cheese'],
  'coconut milk gravy kiri hodi': ['kiri hodi', 'coconut milk gravy'],
  'coconut milk 1st milk': ['coconut milk'],
  'coconut milk 2nd milk': ['coconut milk'],
  'orange juice': ['juice', 'orange'],
  'king coconut water': ['coconut water'],
  'coca cola': ['cola', 'soft drink'],
  'coke zero': ['cola', 'soft drink'],
  'sprite': ['soft drink'],
  'pepsi': ['soft drink'],
  'plain biscuit': ['biscuit'],
  'cream biscuit': ['biscuit'],
  'cracker biscuit': ['biscuit', 'cracker'],
};

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

const Map<String, List<String>> _yoloLabelAliases = {
  'rice': ['rice', 'white rice', 'red rice', 'steam rice', 'staple'],
  'rice plate': ['rice', 'plate meal', 'meal'],
  'chicken curry': ['chicken', 'curry', 'poultry curry'],
  'fish curry': ['fish', 'seafood', 'curry'],
  'egg curry': ['egg', 'curry'],
  'dhal curry': ['dhal', 'lentil', 'curry', 'bean curry'],
  'dhal curry thick': ['dhal curry', 'lentil curry', 'parippu'],
  'parippu': ['dhal curry', 'lentil curry', 'bean curry'],
  'beans curry': ['green bean curry', 'bonchi curry', 'vegetable curry'],
  'green beans curry': ['green bean curry', 'bonchi curry', 'vegetable curry'],
  'potato curry': ['potato', 'vegetable curry', 'curry'],
  'beetroot curry': ['beetroot', 'vegetable curry', 'curry'],
  'beetroot': ['beetroot curry', 'vegetable curry', 'curry'],
  'beans': ['green bean curry', 'beans curry', 'vegetable curry'],
  'green beans': ['green bean curry', 'beans curry', 'vegetable curry'],
  'string hopper': ['string hopper', 'idiyappam', 'noodle', 'staple'],
  'hopper': ['hopper', 'appa', 'bread'],
  'egg hopper': ['egg', 'hopper', 'bread'],
  'roti': ['roti', 'bread', 'flatbread'],
  'kottu': ['kottu', 'roti', 'mixed dish'],
  'biriyani': ['biriyani', 'rice', 'chicken rice'],
  'fried rice': ['fried rice', 'rice'],
  'noodles': ['noodle', 'pasta'],
  'mallum': ['greens', 'vegetable', 'salad'],
  'leafy greens': ['mallum', 'greens', 'vegetable'],
  'sambol': ['sambol', 'condiment'],
  'pol sambol': ['coconut sambol', 'sambol', 'condiment'],
  'papadam': ['papadam', 'papadum', 'poppadom', 'cracker'],
  'papadum': ['papadam', 'papadum', 'poppadom', 'cracker'],
  'poppadom': ['papadam', 'papadum', 'poppadom', 'cracker'],
  'banana': ['banana', 'fruit'],
  'mango': ['mango', 'fruit'],
  'papaya': ['papaya', 'fruit'],
};

const Set<String> _ignoredGenericLabels = {
  'person',
  'table',
  'dining table',
  'chair',
  'couch',
  'sofa',
  'bed',
  'bowl',
  'cup',
  'mug',
  'spoon',
  'fork',
  'knife',
  'bottle',
  'cell phone',
  'remote',
  'tv',
  'laptop',
  'book',
};

const Set<String> _plateSpecificEvidenceTokens = {
  'rice',
  'curry',
  'dhal',
  'parippu',
  'lentil',
  'beans',
  'beetroot',
  'mallum',
  'sambol',
  'papadam',
  'papadum',
  'poppadom',
  'hopper',
  'kottu',
  'noodle',
  'fish',
  'chicken',
  'egg',
  'potato',
  'pumpkin',
  'vegetable',
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
