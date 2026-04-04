import '../models/meal_item.dart';
import '../models/user_profile.dart';
import '../models/dietary_adherence.dart';
import '../services/food_detection_service.dart';
import '../services/health_recommendation_service.dart';
import '../services/supabase_service.dart';
import '../utils/uuid.dart';

class ResearchLoggingService {
  final SupabaseService _supabaseService;
  final FoodDetectionService _portionService = FoodDetectionService();

  ResearchLoggingService({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  Future<void> logMealForResearch({
    required String userId,
    required List<MealItem> items,
    required MealAnalysis analysis,
    required UserProfile? profile,
  }) async {
    if (items.isEmpty) return;

    final mealId = await _supabaseService.saveMealHistory(
      userId: userId,
      items: items,
      healthScore: analysis.healthScore,
      warnings: analysis.warnings,
      recommendations: analysis.recommendations,
    );

    final record = _buildAdherenceRecord(
      userId: userId,
      mealId: mealId,
      items: items,
      analysis: analysis,
      profile: profile,
    );

    await _supabaseService.saveDietaryAdherenceRecord(record);
  }

  DietaryAdherenceRecord _buildAdherenceRecord({
    required String userId,
    required String mealId,
    required List<MealItem> items,
    required MealAnalysis analysis,
    required UserProfile? profile,
  }) {
    final recommendedByFood = {
      for (final item in items)
        item.food.id: _portionService.getSmartPortionFromProfile(
          item.food,
          profile,
        ),
    };

    double recommendedCalories = 0;
    double recommendedCarbs = 0;
    double recommendedPortionGrams = 0;

    for (final item in items) {
      final recommendedGrams = recommendedByFood[item.food.id] ?? item.grams;
      recommendedPortionGrams += recommendedGrams;
      recommendedCalories += item.food.energyKcal * recommendedGrams / 100;
      recommendedCarbs += item.food.carbs100g * recommendedGrams / 100;
    }

    final actualCalories =
        items.fold<double>(0, (sum, item) => sum + item.kcal);
    final actualCarbs = items.fold<double>(0, (sum, item) => sum + item.carbs);
    final actualPortionGrams =
        items.fold<double>(0, (sum, item) => sum + item.grams);

    final calorieVariance =
        _percentVariance(actualCalories, recommendedCalories);
    final carbVariance = _percentVariance(actualCarbs, recommendedCarbs);

    final followedPortionAdvice =
        actualPortionGrams <= (recommendedPortionGrams * 1.1);

    final avoidedHighGI = items.every((item) {
      final gi = item.food.glycemicIndex ?? 55;
      return gi < 70;
    });

    final includedRecommendedFoods = items.any((item) {
      final gi = item.food.glycemicIndex ?? 55;
      final category = item.food.category.toLowerCase();
      return gi <= 55 ||
          category.contains('vegetable') ||
          category.contains('fruit');
    });

    final combinedRecommendations = <String>{
      ...analysis.recommendations,
      ...analysis.warnings,
      ...analysis.portionSuggestions,
    }.toList();

    final adherenceScore = DietaryAdherenceRecord.calculateAdherenceScore(
      followedPortionAdvice: followedPortionAdvice,
      avoidedHighGIFoods: avoidedHighGI,
      includedRecommendedFoods: includedRecommendedFoods,
      calorieVariance: calorieVariance,
      carbVariance: carbVariance,
    );

    return DietaryAdherenceRecord(
      id: generateUuidV4(),
      userId: userId,
      date: DateTime.now(),
      mealId: mealId,
      recommendationsGiven: combinedRecommendations,
      recommendedCalories: recommendedCalories,
      recommendedCarbs: recommendedCarbs,
      recommendedPortionGrams: recommendedPortionGrams,
      actualCalories: actualCalories,
      actualCarbs: actualCarbs,
      actualPortionGrams: actualPortionGrams,
      followedPortionAdvice: followedPortionAdvice,
      avoidedHighGIFoods: avoidedHighGI,
      includedRecommendedFoods: includedRecommendedFoods,
      adherenceScore: adherenceScore,
    );
  }

  double _percentVariance(double actual, double recommended) {
    if (recommended <= 0) return 0;
    return ((actual - recommended) / recommended) * 100;
  }
}
