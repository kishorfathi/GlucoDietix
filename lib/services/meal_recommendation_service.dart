import '../models/food.dart';
import '../models/user_profile.dart';

/// ML-Based Meal Recommendation Service
/// Analyzes user data (age, BMI, glucose level, diet preferences)
/// to recommend personalized meals for breakfast, lunch, and dinner
class MealRecommendationService {
  // Meal categories by time of day
  final Map<String, List<String>> _mealCategories = {
    'breakfast': [
      'string hoppers',
      'rice',
      'bread',
      'milk',
      'eggs',
      'fruit',
      'yogurt',
      'oats',
    ],
    'lunch': [
      'rice',
      'chicken',
      'fish',
      'vegetables',
      'curry',
      'dhal',
      'lentils',
      'salad',
    ],
    'dinner': [
      'rice',
      'fish',
      'vegetables',
      'curry',
      'soup',
      'salad',
      'lean protein',
    ],
  };

  /// Generate personalized meal recommendations based on user profile
  MealRecommendations getPersonalizedRecommendations(
    UserProfile profile,
    List<Food> availableFoods, {
    double? currentGlucose,
  }) {
    // Calculate BMI
    final bmi = _calculateBMI(profile.weightKg, profile.heightCm);

    // Determine calorie needs based on BMI and diabetes status
    final targetCalories = _calculateTargetCalories(profile, bmi);

    // Get glucose-aware recommendations
    final glucoseLevel = currentGlucose ?? _estimateGlucoseFromProfile(profile);

    return MealRecommendations(
      breakfast: _generateMealRecommendation(
        'breakfast',
        availableFoods,
        targetCalories * 0.3, // 30% of daily calories
        profile,
        glucoseLevel,
      ),
      lunch: _generateMealRecommendation(
        'lunch',
        availableFoods,
        targetCalories * 0.4, // 40% of daily calories
        profile,
        glucoseLevel,
      ),
      dinner: _generateMealRecommendation(
        'dinner',
        availableFoods,
        targetCalories * 0.3, // 30% of daily calories
        profile,
        glucoseLevel,
      ),
      bmi: bmi,
      targetDailyCalories: targetCalories,
      glucoseStatus: _getGlucoseStatus(glucoseLevel),
    );
  }

  double _calculateBMI(double weightKg, double heightCm) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  double _calculateTargetCalories(UserProfile profile, double bmi) {
    // Base calorie calculation
    double baseCalories = 1800;

    // Adjust for BMI
    if (bmi < 18.5) {
      baseCalories = 2200; // Underweight - need more calories
    } else if (bmi >= 18.5 && bmi < 25) {
      baseCalories = 1800; // Normal weight
    } else if (bmi >= 25 && bmi < 30) {
      baseCalories = 1600; // Overweight - reduce calories
    } else {
      baseCalories = 1400; // Obese - significant reduction
    }

    // Adjust for diabetes
    if (profile.diabetes) {
      baseCalories *= 0.95; // Slight reduction for better glucose control
    }

    // Adjust for glucose range
    if (profile.glucoseRange == 'high') {
      baseCalories *= 0.90; // Further reduction for high glucose
    }

    return baseCalories;
  }

  double _estimateGlucoseFromProfile(UserProfile profile) {
    switch (profile.glucoseRange) {
      case 'low':
        return 65;
      case 'normal':
        return 95;
      case 'high':
        return 160;
      default:
        return 100;
    }
  }

  String _getGlucoseStatus(double glucose) {
    if (glucose < 70) return 'Low';
    if (glucose <= 130) return 'Normal';
    if (glucose <= 180) return 'High';
    return 'Very High';
  }

  MealRecommendation _generateMealRecommendation(
    String mealType,
    List<Food> availableFoods,
    double targetCalories,
    UserProfile profile,
    double glucoseLevel,
  ) {
    final recommendedFoods = <RecommendedFood>[];
    final categories = _mealCategories[mealType] ?? [];

    // Filter foods for this meal type
    final suitableFoods = availableFoods.where((food) {
      final foodName = food.name.toLowerCase();
      return categories.any((cat) => foodName.contains(cat.toLowerCase()));
    }).toList();

    double totalCalories = 0;
    double totalCarbs = 0;

    // Select foods based on health profile
    for (final food in suitableFoods) {
      if (totalCalories >= targetCalories) break;

      // Skip high GI foods if glucose is high
      if (glucoseLevel > 140 && (food.glycemicIndex ?? 55) > 70) {
        continue;
      }

      // Skip high cholesterol foods if user has cholesterol concern
      if (profile.cholesterolConcern && food.fat100g > 15) {
        continue;
      }

      // Calculate appropriate portion size
      final portionGrams = _calculatePortionSize(
        food,
        targetCalories - totalCalories,
        profile,
      );

      if (portionGrams > 0) {
        final calories = (food.energyKcal * portionGrams / 100);
        final carbs = (food.carbs100g * portionGrams / 100);

        recommendedFoods.add(RecommendedFood(
          food: food,
          portionGrams: portionGrams,
          reason: _getRecommendationReason(food, profile, glucoseLevel),
        ));

        totalCalories += calories;
        totalCarbs += carbs;

        // Limit number of items per meal
        if (recommendedFoods.length >= 4) break;
      }
    }

    return MealRecommendation(
      mealType: mealType,
      foods: recommendedFoods,
      totalCalories: totalCalories,
      totalCarbs: totalCarbs,
      healthTip: _getHealthTip(mealType, profile, glucoseLevel),
    );
  }

  double _calculatePortionSize(
    Food food,
    double remainingCalories,
    UserProfile profile,
  ) {
    // Standard portions
    const standardRicePortion = 150.0; // grams
    const standardProteinPortion = 100.0;
    const standardVegPortion = 120.0;

    final foodName = food.name.toLowerCase();

    if (foodName.contains('rice')) {
      // Reduce rice portion for diabetics
      return profile.diabetes ? 100.0 : standardRicePortion;
    } else if (foodName.contains('chicken') ||
        foodName.contains('fish') ||
        foodName.contains('egg')) {
      return standardProteinPortion;
    } else if (foodName.contains('vegetable') || foodName.contains('salad')) {
      return standardVegPortion;
    }

    // Calculate based on remaining calories
    if (food.energyKcal > 0) {
      final portion =
          (remainingCalories / food.energyKcal * 100).clamp(50.0, 200.0);
      return portion;
    }

    return 100.0; // Default portion
  }

  String _getRecommendationReason(
    Food food,
    UserProfile profile,
    double glucoseLevel,
  ) {
    final gi = food.glycemicIndex ?? 55;
    final protein = food.protein100g;

    if (gi < 55 && profile.diabetes) {
      return 'Low GI - Good for blood sugar control';
    } else if (protein > 15) {
      return 'High protein - Helps stabilize blood sugar';
    } else if (food.fiber100g > 5) {
      return 'High fiber - Promotes digestive health';
    } else if (food.fat100g < 5) {
      return 'Low fat - Heart healthy choice';
    }

    return 'Balanced nutritional profile';
  }

  String _getHealthTip(
    String mealType,
    UserProfile profile,
    double glucoseLevel,
  ) {
    if (glucoseLevel < 70) {
      return '⚠️ Low glucose detected. Include quick-acting carbs and monitor levels.';
    } else if (glucoseLevel > 180) {
      return '⚠️ High glucose detected. Avoid high GI foods and consider light exercise.';
    }

    switch (mealType) {
      case 'breakfast':
        return '💡 Start your day with balanced nutrition. Include protein and fiber!';
      case 'lunch':
        return '💡 Main meal of the day. Balance carbs with protein and vegetables.';
      case 'dinner':
        return '💡 Keep it light. Avoid heavy carbs before bedtime.';
      default:
        return '💡 Stay hydrated and maintain regular meal times.';
    }
  }
}

/// Meal Recommendations Result
class MealRecommendations {
  final MealRecommendation breakfast;
  final MealRecommendation lunch;
  final MealRecommendation dinner;
  final double bmi;
  final double targetDailyCalories;
  final String glucoseStatus;

  MealRecommendations({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.bmi,
    required this.targetDailyCalories,
    required this.glucoseStatus,
  });

  String getBMICategory() {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }
}

/// Single Meal Recommendation
class MealRecommendation {
  final String mealType;
  final List<RecommendedFood> foods;
  final double totalCalories;
  final double totalCarbs;
  final String healthTip;

  MealRecommendation({
    required this.mealType,
    required this.foods,
    required this.totalCalories,
    required this.totalCarbs,
    required this.healthTip,
  });
}

/// Recommended Food Item
class RecommendedFood {
  final Food food;
  final double portionGrams;
  final String reason;

  RecommendedFood({
    required this.food,
    required this.portionGrams,
    required this.reason,
  });
}
