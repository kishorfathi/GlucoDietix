import '../models/food.dart';
import '../models/meal_item.dart';
import '../models/user_profile.dart';

/// Health Recommendation Service
/// Analyzes meals and provides personalized health recommendations
class HealthRecommendationService {
  /// Analyze meal and generate recommendations
  MealAnalysis analyzeMeal(List<MealItem> mealItems, UserProfile? profile) {
    if (mealItems.isEmpty) {
      return MealAnalysis(
        overallRating: 'neutral',
        recommendations: ['Add foods to your meal to get recommendations'],
        warnings: [],
        portionSuggestions: [],
        healthScore: 0,
      );
    }

    final totalCarbs = _calculateTotalCarbs(mealItems);
    final totalProtein = _calculateTotalProtein(mealItems);
    final totalFat = _calculateTotalFat(mealItems);
    final totalCalories = _calculateTotalCalories(mealItems);
    final avgGlycemicIndex = _calculateAvgGI(mealItems);

    final recommendations = <String>[];
    final warnings = <String>[];
    final portionSuggestions = <String>[];
    int healthScore = 100;

    // Analyze for diabetes
    if (profile?.diabetes == true || profile?.glucoseRange == 'high') {
      _analyzeDiabetes(
        mealItems,
        totalCarbs,
        avgGlycemicIndex,
        recommendations,
        warnings,
        portionSuggestions,
      );
      healthScore -= _calculateDiabetesRisk(totalCarbs, avgGlycemicIndex);
    }

    // Analyze for cholesterol
    if (profile?.cholesterolConcern == true) {
      _analyzeCholesterol(
        mealItems,
        totalFat,
        recommendations,
        warnings,
        portionSuggestions,
      );
      healthScore -= _calculateCholesterolRisk(totalFat, mealItems);
    }

    // General nutrition analysis
    _analyzeGeneralNutrition(
      totalCarbs,
      totalProtein,
      totalFat,
      totalCalories,
      recommendations,
      warnings,
    );

    // Determine overall rating
    String overallRating;
    if (healthScore >= 80) {
      overallRating = 'excellent';
    } else if (healthScore >= 60) {
      overallRating = 'good';
    } else if (healthScore >= 40) {
      overallRating = 'moderate';
    } else {
      overallRating = 'caution';
    }

    return MealAnalysis(
      overallRating: overallRating,
      recommendations: recommendations.isEmpty
          ? ['Your meal looks balanced!']
          : recommendations,
      warnings: warnings,
      portionSuggestions: portionSuggestions,
      healthScore: healthScore.clamp(0, 100),
    );
  }

  double _calculateTotalCarbs(List<MealItem> items) {
    return items.fold(0.0, (sum, item) {
      return sum + (item.food.carbs100g * item.grams / 100);
    });
  }

  double _calculateTotalProtein(List<MealItem> items) {
    return items.fold(0.0, (sum, item) {
      return sum + (item.food.protein100g * item.grams / 100);
    });
  }

  double _calculateTotalFat(List<MealItem> items) {
    return items.fold(0.0, (sum, item) {
      return sum + (item.food.fat100g * item.grams / 100);
    });
  }

  double _calculateTotalCalories(List<MealItem> items) {
    return items.fold(0.0, (sum, item) {
      return sum + (item.food.energyKcal * item.grams / 100);
    });
  }

  double _calculateAvgGI(List<MealItem> items) {
    final itemsWithGI = items.where((item) => item.food.glycemicIndex != null);
    if (itemsWithGI.isEmpty) return 55; // Default medium GI

    return itemsWithGI.fold(0.0, (sum, item) {
          return sum + (item.food.glycemicIndex ?? 55);
        }) /
        itemsWithGI.length;
  }

  void _analyzeDiabetes(
    List<MealItem> items,
    double totalCarbs,
    double avgGI,
    List<String> recommendations,
    List<String> warnings,
    List<String> portionSuggestions,
  ) {
    // Check high GI foods
    final highGIFoods = items.where((item) {
      return (item.food.glycemicIndex ?? 0) > 70;
    }).toList();

    if (highGIFoods.isNotEmpty) {
      warnings.add(
          '⚠️ High GI foods detected: ${highGIFoods.map((e) => e.food.name).join(", ")}');
      recommendations.add(
          '💡 Consider reducing portions of high GI foods or replacing with lower GI alternatives');
    }

    // Check total carbs
    if (totalCarbs > 60) {
      warnings.add(
          '⚠️ High carbohydrate content (${totalCarbs.toStringAsFixed(1)}g)');
      recommendations.add(
          '💡 Reduce rice/bread portions by 30-50% for better glucose control');

      // Specific portion suggestions
      for (var item in items) {
        if (item.food.category == 'Staples' && item.grams > 150) {
          portionSuggestions.add(
              'Reduce ${item.food.name} from ${item.grams.toStringAsFixed(0)}g to ${(item.grams * 0.6).toStringAsFixed(0)}g');
        }
      }
    } else if (totalCarbs < 30) {
      recommendations
          .add('✅ Good carb control! This meal is diabetes-friendly');
    }

    // Check for fiber
    final totalFiber = items.fold(0.0, (sum, item) {
      return sum + (item.food.fiber100g * item.grams / 100);
    });

    if (totalFiber < 5) {
      recommendations.add(
          '💡 Add more fiber (vegetables, brown rice) to slow glucose absorption');
    }
  }

  void _analyzeCholesterol(
    List<MealItem> items,
    double totalFat,
    List<String> recommendations,
    List<String> warnings,
    List<String> portionSuggestions,
  ) {
    // Check for high-fat foods
    final highFatFoods = items.where((item) => item.food.fat100g > 15).toList();

    if (highFatFoods.isNotEmpty) {
      warnings.add(
          '⚠️ High-fat items: ${highFatFoods.map((e) => e.food.name).join(", ")}');
      recommendations.add('💡 Limit fried foods and coconut-based dishes');
    }

    // Check for high cholesterol foods
    final highCholFoods = items.where((item) {
      return (item.food.cholesterolMg ?? 0) > 100;
    }).toList();

    if (highCholFoods.isNotEmpty) {
      warnings.add(
          '⚠️ High cholesterol foods: ${highCholFoods.map((e) => e.food.name).join(", ")}');
      portionSuggestions.add('Reduce egg/meat dishes to smaller portions');
    }

    if (totalFat > 30) {
      recommendations
          .add('💡 Total fat is high - consider grilling instead of frying');
    }
  }

  void _analyzeGeneralNutrition(
    double carbs,
    double protein,
    double fat,
    double calories,
    List<String> recommendations,
    List<String> warnings,
  ) {
    // Check protein adequacy
    if (protein < 15) {
      recommendations.add('💡 Add more protein (fish, chicken, dhal, eggs)');
    } else if (protein > 20) {
      recommendations.add('✅ Good protein content!');
    }

    // Check calorie balance
    if (calories > 800) {
      warnings
          .add('⚠️ High calorie meal (${calories.toStringAsFixed(0)} kcal)');
      recommendations
          .add('💡 This is suitable as a main meal, avoid snacking after');
    } else if (calories < 300) {
      recommendations
          .add('💡 Light meal - consider adding more vegetables or protein');
    }

    // Macronutrient balance
    final total = carbs + protein + fat;
    final carbPercent = (carbs * 4 / (total * 4)) * 100;
    final proteinPercent = (protein * 4 / (total * 4)) * 100;

    if (carbPercent > 60) {
      recommendations
          .add('💡 Carb-heavy meal - balance with more protein/vegetables');
    } else if (proteinPercent > 35) {
      recommendations.add('✅ Well-balanced meal!');
    }
  }

  int _calculateDiabetesRisk(double totalCarbs, double avgGI) {
    int risk = 0;

    if (totalCarbs > 60)
      risk += 30;
    else if (totalCarbs > 45) risk += 15;

    if (avgGI > 70)
      risk += 25;
    else if (avgGI > 60) risk += 10;

    return risk;
  }

  int _calculateCholesterolRisk(double totalFat, List<MealItem> items) {
    int risk = 0;

    if (totalFat > 30)
      risk += 20;
    else if (totalFat > 20) risk += 10;

    final totalChol = items.fold(0.0, (sum, item) {
      return sum + ((item.food.cholesterolMg ?? 0) * item.grams / 100);
    });

    if (totalChol > 200)
      risk += 20;
    else if (totalChol > 100) risk += 10;

    return risk;
  }

  /// Get food-specific recommendation
  String getFoodRecommendation(Food food, UserProfile? profile) {
    final recommendations = <String>[];

    // Diabetes check
    if (profile?.diabetes == true) {
      final gi = food.glycemicIndex ?? 55;
      if (gi > 70) {
        recommendations
            .add('⚠️ High GI (${gi.toInt()}) - eat in small portions');
      } else if (gi < 55) {
        recommendations.add('✅ Low GI (${gi.toInt()}) - good for diabetes');
      }
    }

    // Cholesterol check
    if (profile?.cholesterolConcern == true) {
      if (food.fat100g > 15) {
        recommendations.add('⚠️ High in fat - limit portion size');
      }
      if ((food.cholesterolMg ?? 0) > 100) {
        recommendations.add('⚠️ Contains cholesterol - consume occasionally');
      }
    }

    return recommendations.isEmpty
        ? '✅ Suitable for your health profile'
        : recommendations.join('\n');
  }
}

/// Meal Analysis Result
class MealAnalysis {
  final String overallRating; // excellent, good, moderate, caution
  final List<String> recommendations;
  final List<String> warnings;
  final List<String> portionSuggestions;
  final int healthScore; // 0-100

  MealAnalysis({
    required this.overallRating,
    required this.recommendations,
    required this.warnings,
    required this.portionSuggestions,
    required this.healthScore,
  });
}
