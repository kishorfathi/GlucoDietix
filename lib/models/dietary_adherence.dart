/// Dietary Adherence Record - Tracks compliance with recommendations
class DietaryAdherenceRecord {
  final String id;
  final String userId;
  final DateTime date;
  final String mealId;

  // Recommendations given
  final List<String> recommendationsGiven;
  final double recommendedCalories;
  final double recommendedCarbs;
  final double recommendedPortionGrams;

  // Actual consumption
  final double actualCalories;
  final double actualCarbs;
  final double actualPortionGrams;
  final bool followedPortionAdvice; // Did user reduce portion as suggested?
  final bool avoidedHighGIFoods; // Did user avoid high GI foods?
  final bool
      includedRecommendedFoods; // Did user include suggested alternatives?

  // Adherence metrics
  final double adherenceScore; // 0-100

  DietaryAdherenceRecord({
    required this.id,
    required this.userId,
    required this.date,
    required this.mealId,
    required this.recommendationsGiven,
    required this.recommendedCalories,
    required this.recommendedCarbs,
    required this.recommendedPortionGrams,
    required this.actualCalories,
    required this.actualCarbs,
    required this.actualPortionGrams,
    required this.followedPortionAdvice,
    required this.avoidedHighGIFoods,
    required this.includedRecommendedFoods,
    required this.adherenceScore,
  });

  factory DietaryAdherenceRecord.fromJson(Map<String, dynamic> json) {
    return DietaryAdherenceRecord(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      date: DateTime.parse(json['date'] as String),
      mealId: json['meal_id'] as String,
      recommendationsGiven:
          List<String>.from(json['recommendations_given'] as List),
      recommendedCalories: (json['recommended_calories'] as num).toDouble(),
      recommendedCarbs: (json['recommended_carbs'] as num).toDouble(),
      recommendedPortionGrams:
          (json['recommended_portion_grams'] as num).toDouble(),
      actualCalories: (json['actual_calories'] as num).toDouble(),
      actualCarbs: (json['actual_carbs'] as num).toDouble(),
      actualPortionGrams: (json['actual_portion_grams'] as num).toDouble(),
      followedPortionAdvice: json['followed_portion_advice'] as bool,
      avoidedHighGIFoods: json['avoided_high_gi_foods'] as bool,
      includedRecommendedFoods: json['included_recommended_foods'] as bool,
      adherenceScore: (json['adherence_score'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'date': date.toIso8601String(),
      'meal_id': mealId,
      'recommendations_given': recommendationsGiven,
      'recommended_calories': recommendedCalories,
      'recommended_carbs': recommendedCarbs,
      'recommended_portion_grams': recommendedPortionGrams,
      'actual_calories': actualCalories,
      'actual_carbs': actualCarbs,
      'actual_portion_grams': actualPortionGrams,
      'followed_portion_advice': followedPortionAdvice,
      'avoided_high_gi_foods': avoidedHighGIFoods,
      'included_recommended_foods': includedRecommendedFoods,
      'adherence_score': adherenceScore,
    };
  }

  /// Calculate adherence score based on compliance metrics
  static double calculateAdherenceScore({
    required bool followedPortionAdvice,
    required bool avoidedHighGIFoods,
    required bool includedRecommendedFoods,
    required double calorieVariance, // % difference from recommended
    required double carbVariance, // % difference from recommended
  }) {
    double score = 0.0;

    // Portion compliance (30 points)
    if (followedPortionAdvice) score += 30;

    // High GI avoidance (25 points)
    if (avoidedHighGIFoods) score += 25;

    // Recommended foods inclusion (20 points)
    if (includedRecommendedFoods) score += 20;

    // Calorie accuracy (15 points - lose points for >20% variance)
    if (calorieVariance.abs() <= 10) {
      score += 15;
    } else if (calorieVariance.abs() <= 20) {
      score += 10;
    } else if (calorieVariance.abs() <= 30) {
      score += 5;
    }

    // Carb accuracy (10 points - lose points for >20% variance)
    if (carbVariance.abs() <= 10) {
      score += 10;
    } else if (carbVariance.abs() <= 20) {
      score += 7;
    } else if (carbVariance.abs() <= 30) {
      score += 3;
    }

    return score.clamp(0.0, 100.0);
  }

  /// Get adherence level description
  String getAdherenceLevel() {
    if (adherenceScore >= 80) return 'Excellent';
    if (adherenceScore >= 65) return 'Good';
    if (adherenceScore >= 50) return 'Fair';
    return 'Needs Improvement';
  }
}

/// Weekly Dietary Adherence Summary
class WeeklyAdherenceSummary {
  final String userId;
  final DateTime weekStartDate;
  final DateTime weekEndDate;
  final int totalMeals;
  final int mealsWithRecommendations;
  final double averageAdherenceScore;
  final int daysFollowedPlan;
  final double portionComplianceRate; // %
  final double giComplianceRate; // %

  WeeklyAdherenceSummary({
    required this.userId,
    required this.weekStartDate,
    required this.weekEndDate,
    required this.totalMeals,
    required this.mealsWithRecommendations,
    required this.averageAdherenceScore,
    required this.daysFollowedPlan,
    required this.portionComplianceRate,
    required this.giComplianceRate,
  });

  factory WeeklyAdherenceSummary.fromRecords(
    String userId,
    DateTime weekStart,
    List<DietaryAdherenceRecord> records,
  ) {
    final weekEnd = weekStart.add(const Duration(days: 7));
    final totalMeals = records.length;
    final mealsWithRecs =
        records.where((r) => r.recommendationsGiven.isNotEmpty).length;

    final avgAdherence = totalMeals > 0
        ? records.map((r) => r.adherenceScore).reduce((a, b) => a + b) /
            totalMeals
        : 0.0;

    final daysFollowed = records.map((r) => r.date.day).toSet().length;

    final portionCompliance = totalMeals > 0
        ? (records.where((r) => r.followedPortionAdvice).length / totalMeals) *
            100
        : 0.0;

    final giCompliance = totalMeals > 0
        ? (records.where((r) => r.avoidedHighGIFoods).length / totalMeals) * 100
        : 0.0;

    return WeeklyAdherenceSummary(
      userId: userId,
      weekStartDate: weekStart,
      weekEndDate: weekEnd,
      totalMeals: totalMeals,
      mealsWithRecommendations: mealsWithRecs,
      averageAdherenceScore: avgAdherence,
      daysFollowedPlan: daysFollowed,
      portionComplianceRate: portionCompliance,
      giComplianceRate: giCompliance,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'week_start_date': weekStartDate.toIso8601String(),
      'week_end_date': weekEndDate.toIso8601String(),
      'total_meals': totalMeals,
      'meals_with_recommendations': mealsWithRecommendations,
      'average_adherence_score': averageAdherenceScore,
      'days_followed_plan': daysFollowedPlan,
      'portion_compliance_rate': portionComplianceRate,
      'gi_compliance_rate': giComplianceRate,
    };
  }

  String getWeeklyPerformance() {
    if (averageAdherenceScore >= 80) return 'Outstanding';
    if (averageAdherenceScore >= 65) return 'Good Progress';
    if (averageAdherenceScore >= 50) return 'Making Efforts';
    return 'Needs Support';
  }
}
