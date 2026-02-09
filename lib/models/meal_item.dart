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
  double get kcal => food.kcal100g * grams / 100;
  double get carbs => food.carbs100g * grams / 100;
  double get protein => food.protein100g * grams / 100;
  double get fat => food.fat100g * grams / 100;
  double get fiber => (food.fiber100g ?? 0) * grams / 100;
  double get sugar => (food.sugar100g ?? 0) * grams / 100;
}
