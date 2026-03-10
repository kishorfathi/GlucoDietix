import '../models/food.dart';
import '../models/meal_item.dart';

/// Plate Method Recommendation Service
/// Provides portion recommendations based on the healthy plate method for diabetes management
/// Divides a standard plate into 4 portions with appropriate food groups
class PlateMethodService {
  /// Food category classifications for plate method
  static const _riceCategories = ['Rice & Grains', 'Rice', 'Grains'];
  static const _proteinCategories = ['Meat', 'Fish', 'Protein', 'Curry'];
  static const _vegetableCategories = ['Vegetables', 'Vegetable', 'Salad'];
  static const _dhalCategories = ['Lentils', 'Dhal', 'Legumes'];

  /// Standard plate portions (in grams) for diabetes management
  static const double _platePortionGrams = 150.0; // 1/4 of a standard plate

  /// Gets plate method recommendations for selected foods
  PlateRecommendation getPlateRecommendations(List<MealItem> selectedFoods) {
    if (selectedFoods.isEmpty) {
      return PlateRecommendation(portions: []);
    }

    final portions = <PlatePortion>[];

    // Categorize foods
    for (final item in selectedFoods) {
      final food = item.food;
      final category = _categorizeFood(food);

      if (category == null) continue;

      final portion = _getPortion(food, category);
      portions.add(portion);
    }

    return PlateRecommendation(portions: portions);
  }

  FoodCategory? _categorizeFood(Food food) {
    final foodName = food.name.toLowerCase();
    final category = food.category.toLowerCase();

    // Rice and grains
    if (_riceCategories.any((cat) => category.contains(cat.toLowerCase())) ||
        foodName.contains('rice') ||
        foodName.contains('bread') ||
        foodName.contains('roti')) {
      return FoodCategory.rice;
    }

    // Vegetables
    if (_vegetableCategories
            .any((cat) => category.contains(cat.toLowerCase())) ||
        foodName.contains('vegetable') ||
        foodName.contains('veg') ||
        foodName.contains('salad') ||
        foodName.contains('beetroot') ||
        foodName.contains('carrot') ||
        foodName.contains('beans')) {
      return FoodCategory.vegetable;
    }

    // Dhal/Lentils
    if (_dhalCategories.any((cat) => category.contains(cat.toLowerCase())) ||
        foodName.contains('dhal') ||
        foodName.contains('dal') ||
        foodName.contains('lentil') ||
        foodName.contains('parippu')) {
      return FoodCategory.dhal;
    }

    // Protein/Curry
    if (_proteinCategories.any((cat) => category.contains(cat.toLowerCase())) ||
        foodName.contains('curry') ||
        foodName.contains('chicken') ||
        foodName.contains('beef') ||
        foodName.contains('fish') ||
        foodName.contains('egg') ||
        foodName.contains('meat')) {
      return FoodCategory.protein;
    }

    // Default to other if can't categorize
    return FoodCategory.other;
  }

  PlatePortion _getPortion(Food food, FoodCategory category) {
    double portionCount;
    double gramsAmount;
    String measurement;
    String recommendation;

    switch (category) {
      case FoodCategory.rice:
        // 1 portion of plate (1/4)
        portionCount = 1;
        gramsAmount = _platePortionGrams; // ~150g
        measurement = '1 cup';
        recommendation = '1 portion (1/4 of plate) - About 1 cup cooked rice';
        break;

      case FoodCategory.vegetable:
        // 2 portions of plate (1/2) - Largest portion
        portionCount = 2;
        gramsAmount = _platePortionGrams * 2; // ~300g
        measurement = '2 cups';
        recommendation =
            '2 portions (1/2 of plate) - Fill half your plate with vegetables';
        break;

      case FoodCategory.dhal:
        // 1 portion of plate (1/4)
        portionCount = 1;
        gramsAmount = 120; // Slightly less as it's usually liquid
        measurement = '1/2 cup';
        recommendation = '1 portion (1/4 of plate) - About 1/2 cup dhal curry';
        break;

      case FoodCategory.protein:
        // 1 portion of plate (1/4) - But smaller amount as it's dense
        portionCount = 1;
        gramsAmount = 100; // ~100g protein
        measurement = '3-4 tablespoons';
        recommendation =
            '1 portion (1/4 of plate) - About 3-4 tablespoons of curry';
        break;

      case FoodCategory.other:
        portionCount = 0.5;
        gramsAmount = 75;
        measurement = '1/2 portion';
        recommendation = 'Small serving as a side';
        break;
    }

    return PlatePortion(
      food: food,
      category: category,
      portionCount: portionCount,
      recommendedGrams: gramsAmount,
      measurement: measurement,
      recommendation: recommendation,
    );
  }

  /// Gets user-friendly portion guide text
  String getPortionGuide() {
    return '''
🍽️ Healthy Plate Method for Diabetes

Divide your plate into 4 equal portions:

📍 1 Portion (1/4) - Rice/Grains
   • 1 cup cooked rice or
   • 2 roti or
   • 1 cup other grains

📍 2 Portions (1/2) - Vegetables
   • Fill half your plate with:
   • Non-starchy vegetables
   • Salads, leafy greens
   • Vegetable curries

📍 1 Portion (1/4) - Protein
   • Fish, chicken, or lean meat curry
   • About 3-4 tablespoons
   • Palm-sized portion

📍 1 Portion (1/4) - Dhal/Legumes
   • Dhal curry or
   • Lentils or
   • Beans curry
   • About 1/2 cup

💡 Tips:
• Always fill half the plate with vegetables first
• Choose brown rice over white rice when possible
• Limit high-fat curries
• Drink water, not sugary beverages
''';
  }
}

/// Food category for plate method
enum FoodCategory {
  rice,
  vegetable,
  protein,
  dhal,
  other,
}

extension FoodCategoryExtension on FoodCategory {
  String get displayName {
    switch (this) {
      case FoodCategory.rice:
        return 'Rice & Grains';
      case FoodCategory.vegetable:
        return 'Vegetables';
      case FoodCategory.protein:
        return 'Protein/Curry';
      case FoodCategory.dhal:
        return 'Dhal/Lentils';
      case FoodCategory.other:
        return 'Other';
    }
  }

  String get emoji {
    switch (this) {
      case FoodCategory.rice:
        return '🍚';
      case FoodCategory.vegetable:
        return '🥗';
      case FoodCategory.protein:
        return '🍖';
      case FoodCategory.dhal:
        return '🫘';
      case FoodCategory.other:
        return '🍽️';
    }
  }
}

/// Plate portion recommendation
class PlatePortion {
  final Food food;
  final FoodCategory category;
  final double portionCount; // How many quarters of the plate
  final double recommendedGrams;
  final String measurement; // e.g., "1 cup", "3 tablespoons"
  final String recommendation;

  PlatePortion({
    required this.food,
    required this.category,
    required this.portionCount,
    required this.recommendedGrams,
    required this.measurement,
    required this.recommendation,
  });
}

/// Complete plate recommendation
class PlateRecommendation {
  final List<PlatePortion> portions;

  PlateRecommendation({required this.portions});

  /// Gets total portions (should ideally be 4.0)
  double get totalPortions =>
      portions.fold(0.0, (sum, portion) => sum + portion.portionCount);

  /// Checks if plate is balanced (has appropriate food groups)
  bool get isBalanced {
    final hasRice = portions.any((p) => p.category == FoodCategory.rice);
    final hasVeg = portions.any((p) => p.category == FoodCategory.vegetable);
    final hasProtein = portions.any((p) =>
        p.category == FoodCategory.protein || p.category == FoodCategory.dhal);

    return hasRice && hasVeg && hasProtein;
  }

  /// Gets missing food groups
  List<String> get missingGroups {
    final missing = <String>[];

    if (!portions.any((p) => p.category == FoodCategory.rice)) {
      missing.add('Rice/Grains');
    }
    if (!portions.any((p) => p.category == FoodCategory.vegetable)) {
      missing.add('Vegetables (1/2 plate)');
    }
    if (!portions.any((p) =>
        p.category == FoodCategory.protein ||
        p.category == FoodCategory.dhal)) {
      missing.add('Protein or Dhal');
    }

    return missing;
  }

  /// Gets portions grouped by category
  Map<FoodCategory, List<PlatePortion>> get portionsByCategory {
    final grouped = <FoodCategory, List<PlatePortion>>{};

    for (final portion in portions) {
      grouped.putIfAbsent(portion.category, () => []).add(portion);
    }

    return grouped;
  }
}
