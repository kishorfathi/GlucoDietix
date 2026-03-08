/// Research Assessment Model - Pre/Post Intervention Surveys
class ResearchAssessment {
  final String id;
  final String userId;
  final String
      assessmentType; // pre_intervention, post_intervention, weekly_followup
  final DateTime completedAt;

  // Quantitative Metrics
  final int dietaryAdherenceScore; // 1-10 self-reported
  final int portionControlScore; // 1-10 self-reported
  final int mealSelectionAccuracy; // 1-10 self-reported
  final double? averageGlucose; // mg/dL (last 7 days)
  final double? weight; // kg
  final double? hba1c; // % (if available)

  // Qualitative Feedback
  final int usabilityScore; // 1-5 Likert scale
  final int engagementScore; // 1-5 Likert scale
  final int perceivedUsefulnessScore; // 1-5 Likert scale
  final int arFeatureUsefulnessScore; // 1-5 Likert scale (nullable if not used)

  final String? challengesFaced; // Open text
  final String? suggestionsForImprovement; // Open text
  final String? additionalComments; // Open text

  ResearchAssessment({
    required this.id,
    required this.userId,
    required this.assessmentType,
    required this.completedAt,
    required this.dietaryAdherenceScore,
    required this.portionControlScore,
    required this.mealSelectionAccuracy,
    this.averageGlucose,
    this.weight,
    this.hba1c,
    required this.usabilityScore,
    required this.engagementScore,
    required this.perceivedUsefulnessScore,
    required this.arFeatureUsefulnessScore,
    this.challengesFaced,
    this.suggestionsForImprovement,
    this.additionalComments,
  });

  factory ResearchAssessment.fromJson(Map<String, dynamic> json) {
    return ResearchAssessment(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      assessmentType: json['assessment_type'] as String,
      completedAt: DateTime.parse(json['completed_at'] as String),
      dietaryAdherenceScore: json['dietary_adherence_score'] as int,
      portionControlScore: json['portion_control_score'] as int,
      mealSelectionAccuracy: json['meal_selection_accuracy'] as int,
      averageGlucose: json['average_glucose'] != null
          ? (json['average_glucose'] as num).toDouble()
          : null,
      weight:
          json['weight'] != null ? (json['weight'] as num).toDouble() : null,
      hba1c: json['hba1c'] != null ? (json['hba1c'] as num).toDouble() : null,
      usabilityScore: json['usability_score'] as int,
      engagementScore: json['engagement_score'] as int,
      perceivedUsefulnessScore: json['perceived_usefulness_score'] as int,
      arFeatureUsefulnessScore: json['ar_feature_usefulness_score'] as int,
      challengesFaced: json['challenges_faced'] as String?,
      suggestionsForImprovement: json['suggestions_for_improvement'] as String?,
      additionalComments: json['additional_comments'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'assessment_type': assessmentType,
      'completed_at': completedAt.toIso8601String(),
      'dietary_adherence_score': dietaryAdherenceScore,
      'portion_control_score': portionControlScore,
      'meal_selection_accuracy': mealSelectionAccuracy,
      'average_glucose': averageGlucose,
      'weight': weight,
      'hba1c': hba1c,
      'usability_score': usabilityScore,
      'engagement_score': engagementScore,
      'perceived_usefulness_score': perceivedUsefulnessScore,
      'ar_feature_usefulness_score': arFeatureUsefulnessScore,
      'challenges_faced': challengesFaced,
      'suggestions_for_improvement': suggestionsForImprovement,
      'additional_comments': additionalComments,
    };
  }

  /// Calculate overall satisfaction score (average of usability, engagement, usefulness)
  double getOverallSatisfaction() {
    return (usabilityScore + engagementScore + perceivedUsefulnessScore) / 3.0;
  }

  /// Get improvement from pre to post (for comparison)
  static Map<String, double> calculateImprovement(
    ResearchAssessment pre,
    ResearchAssessment post,
  ) {
    return {
      'dietary_adherence_improvement':
          (post.dietaryAdherenceScore - pre.dietaryAdherenceScore).toDouble(),
      'portion_control_improvement':
          (post.portionControlScore - pre.portionControlScore).toDouble(),
      'meal_selection_improvement':
          (post.mealSelectionAccuracy - pre.mealSelectionAccuracy).toDouble(),
      'glucose_improvement':
          post.averageGlucose != null && pre.averageGlucose != null
              ? pre.averageGlucose! - post.averageGlucose!
              : 0.0,
      'weight_change': post.weight != null && pre.weight != null
          ? pre.weight! - post.weight!
          : 0.0,
    };
  }
}
