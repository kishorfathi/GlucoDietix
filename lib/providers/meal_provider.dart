import 'package:flutter/material.dart';
import '../models/meal_item.dart';
import '../models/food.dart';

/// Meal Provider
class MealProvider with ChangeNotifier {
  final List<MealItem> _mealItems = [];

  List<MealItem> get mealItems => _mealItems;

  // Add food to meal
  void addFood(Food food) {
    // Check if food already exists
    final existingIndex =
        _mealItems.indexWhere((item) => item.food.id == food.id);
    if (existingIndex == -1) {
      _mealItems.add(MealItem(food: food, grams: 100)); // Default 100g
      notifyListeners();
    }
  }

  // Remove food from meal
  void removeFood(String foodId) {
    _mealItems.removeWhere((item) => item.food.id == foodId);
    notifyListeners();
  }

  // Update grams for a food
  void updateGrams(String foodId, double grams) {
    final index = _mealItems.indexWhere((item) => item.food.id == foodId);
    if (index != -1) {
      _mealItems[index].grams = grams;
      notifyListeners();
    }
  }

  // Calculate totals
  double get totalKcal => _mealItems.fold(0.0, (sum, item) => sum + item.kcal);
  double get totalCarbs =>
      _mealItems.fold(0.0, (sum, item) => sum + item.carbs);
  double get totalProtein =>
      _mealItems.fold(0.0, (sum, item) => sum + item.protein);
  double get totalFat => _mealItems.fold(0.0, (sum, item) => sum + item.fat);
  double get totalFiber =>
      _mealItems.fold(0.0, (sum, item) => sum + item.fiber);

  // Clear all items
  void clearMeal() {
    _mealItems.clear();
    notifyListeners();
  }

  // Check if meal is empty
  bool get isEmpty => _mealItems.isEmpty;
}
