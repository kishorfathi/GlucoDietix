import 'food.dart';

/// Meal Item Model
class MealItem {
  final Food food;
  double grams;

  MealItem({
    required this.food,
    required this.grams,
  });

  // Calculate nutrients for this item
  double get kcal => food.energyKcal * grams / 100;
  double get carbs => food.carbs100g * grams / 100;
  double get protein => food.protein100g * grams / 100;
  double get fat => food.fat100g * grams / 100;
  double get fiber => food.fiber100g * grams / 100;
}
