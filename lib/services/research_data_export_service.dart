import '../models/glucose_reading.dart';
import '../models/research_assessment.dart';
import '../models/dietary_adherence.dart';
import '../models/user_profile.dart';

/// Research Data Export Service
/// Exports data in formats suitable for statistical analysis (CSV, JSON)
class ResearchDataExportService {
  /// Export glucose readings to CSV format
  String exportGlucoseReadingsToCSV(List<GlucoseReading> readings) {
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln(
        'user_id,timestamp,glucose_level,reading_type,status,meal_id,notes');

    // CSV Rows
    for (var reading in readings) {
      buffer.writeln([
        reading.userId,
        reading.timestamp.toIso8601String(),
        reading.glucoseLevel,
        reading.readingType,
        reading.getStatus(),
        reading.mealId ?? '',
        _escapeCSV(reading.notes ?? ''),
      ].join(','));
    }

    return buffer.toString();
  }

  /// Export research assessments to CSV format
  String exportAssessmentsToCSV(List<ResearchAssessment> assessments) {
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln(
        'user_id,assessment_type,completed_at,dietary_adherence_score,'
        'portion_control_score,meal_selection_accuracy,average_glucose,weight,hba1c,'
        'usability_score,engagement_score,perceived_usefulness_score,ar_feature_usefulness_score,'
        'overall_satisfaction,challenges_faced,suggestions_for_improvement,additional_comments');

    // CSV Rows
    for (var assessment in assessments) {
      buffer.writeln([
        assessment.userId,
        assessment.assessmentType,
        assessment.completedAt.toIso8601String(),
        assessment.dietaryAdherenceScore,
        assessment.portionControlScore,
        assessment.mealSelectionAccuracy,
        assessment.averageGlucose ?? '',
        assessment.weight ?? '',
        assessment.hba1c ?? '',
        assessment.usabilityScore,
        assessment.engagementScore,
        assessment.perceivedUsefulnessScore,
        assessment.arFeatureUsefulnessScore,
        assessment.getOverallSatisfaction().toStringAsFixed(2),
        _escapeCSV(assessment.challengesFaced ?? ''),
        _escapeCSV(assessment.suggestionsForImprovement ?? ''),
        _escapeCSV(assessment.additionalComments ?? ''),
      ].join(','));
    }

    return buffer.toString();
  }

  /// Export dietary adherence records to CSV
  String exportDietaryAdherenceToCSV(List<DietaryAdherenceRecord> records) {
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln(
        'user_id,date,meal_id,recommended_calories,recommended_carbs,'
        'recommended_portion_grams,actual_calories,actual_carbs,actual_portion_grams,'
        'followed_portion_advice,avoided_high_gi_foods,included_recommended_foods,'
        'adherence_score,adherence_level,recommendations_count');

    // CSV Rows
    for (var record in records) {
      buffer.writeln([
        record.userId,
        record.date.toIso8601String(),
        record.mealId,
        record.recommendedCalories,
        record.recommendedCarbs,
        record.recommendedPortionGrams,
        record.actualCalories,
        record.actualCarbs,
        record.actualPortionGrams,
        record.followedPortionAdvice ? 1 : 0,
        record.avoidedHighGIFoods ? 1 : 0,
        record.includedRecommendedFoods ? 1 : 0,
        record.adherenceScore,
        record.getAdherenceLevel(),
        record.recommendationsGiven.length,
      ].join(','));
    }

    return buffer.toString();
  }

  /// Export pre/post intervention comparison to CSV
  String exportPrePostComparisonToCSV(
    List<ResearchAssessment> preAssessments,
    List<ResearchAssessment> postAssessments,
  ) {
    final buffer = StringBuffer();

    // CSV Header
    buffer.writeln(
        'user_id,pre_dietary_adherence,post_dietary_adherence,adherence_improvement,'
        'pre_portion_control,post_portion_control,portion_improvement,'
        'pre_meal_selection,post_meal_selection,meal_selection_improvement,'
        'pre_average_glucose,post_average_glucose,glucose_improvement,'
        'pre_weight,post_weight,weight_change,'
        'pre_usability,post_usability,pre_engagement,post_engagement,'
        'pre_usefulness,post_usefulness,intervention_days');

    // Match pre and post assessments by user
    final preMap = {for (var a in preAssessments) a.userId: a};
    final postMap = {for (var a in postAssessments) a.userId: a};

    for (var userId in preMap.keys) {
      if (postMap.containsKey(userId)) {
        final pre = preMap[userId]!;
        final post = postMap[userId]!;
        final improvements = ResearchAssessment.calculateImprovement(pre, post);
        final interventionDays =
            post.completedAt.difference(pre.completedAt).inDays;

        buffer.writeln([
          userId,
          pre.dietaryAdherenceScore,
          post.dietaryAdherenceScore,
          improvements['dietary_adherence_improvement']!.toStringAsFixed(1),
          pre.portionControlScore,
          post.portionControlScore,
          improvements['portion_control_improvement']!.toStringAsFixed(1),
          pre.mealSelectionAccuracy,
          post.mealSelectionAccuracy,
          improvements['meal_selection_improvement']!.toStringAsFixed(1),
          pre.averageGlucose ?? '',
          post.averageGlucose ?? '',
          improvements['glucose_improvement']!.toStringAsFixed(1),
          pre.weight ?? '',
          post.weight ?? '',
          improvements['weight_change']!.toStringAsFixed(2),
          pre.usabilityScore,
          post.usabilityScore,
          pre.engagementScore,
          post.engagementScore,
          pre.perceivedUsefulnessScore,
          post.perceivedUsefulnessScore,
          interventionDays,
        ].join(','));
      }
    }

    return buffer.toString();
  }

  /// Export all research data as JSON
  Map<String, dynamic> exportAllDataToJSON({
    required List<UserProfile> participants,
    required List<GlucoseReading> glucoseReadings,
    required List<ResearchAssessment> assessments,
    required List<DietaryAdherenceRecord> adherenceRecords,
    required List<WeeklyAdherenceSummary> weeklySummaries,
  }) {
    return {
      'export_date': DateTime.now().toIso8601String(),
      'study_title': 'ML-Based Dietary Management for Diabetes in Sri Lanka',
      'participant_count': participants.length,
      'data': {
        'participants': participants
            .map((p) => {
                  'user_id': p.id,
                  'diabetes': p.diabetes,
                  'glucose_range': p.glucoseRange,
                  'cholesterol_concern': p.cholesterolConcern,
                  'weight': p.weightKg,
                  'height': p.heightCm,
                  'diabetes_type': p.diabetesType,
                  'treatment': p.treatment,
                })
            .toList(),
        'glucose_readings': glucoseReadings.map((r) => r.toJson()).toList(),
        'assessments': assessments.map((a) => a.toJson()).toList(),
        'dietary_adherence': adherenceRecords.map((r) => r.toJson()).toList(),
        'weekly_summaries': weeklySummaries.map((s) => s.toJson()).toList(),
      },
      'statistics': {
        'total_glucose_readings': glucoseReadings.length,
        'total_assessments': assessments.length,
        'total_meals_tracked': adherenceRecords.length,
        'average_adherence_score': _calculateAverageAdherence(adherenceRecords),
        'participants_with_pre_assessment': assessments
            .where((a) => a.assessmentType == 'pre_intervention')
            .length,
        'participants_with_post_assessment': assessments
            .where((a) => a.assessmentType == 'post_intervention')
            .length,
      },
    };
  }

  /// Generate statistical summary for research paper
  Map<String, dynamic> generateStatisticalSummary({
    required List<ResearchAssessment> preAssessments,
    required List<ResearchAssessment> postAssessments,
    required List<DietaryAdherenceRecord> adherenceRecords,
    required List<GlucoseReading> glucoseReadings,
  }) {
    // Calculate improvements
    final improvements = <Map<String, double>>[];
    final preMap = {for (var a in preAssessments) a.userId: a};
    final postMap = {for (var a in postAssessments) a.userId: a};

    for (var userId in preMap.keys) {
      if (postMap.containsKey(userId)) {
        improvements.add(ResearchAssessment.calculateImprovement(
            preMap[userId]!, postMap[userId]!));
      }
    }

    return {
      'sample_size': improvements.length,
      'mean_dietary_adherence_improvement': _mean(improvements
          .map((i) => i['dietary_adherence_improvement']!)
          .toList()),
      'mean_portion_control_improvement': _mean(
          improvements.map((i) => i['portion_control_improvement']!).toList()),
      'mean_meal_selection_improvement': _mean(
          improvements.map((i) => i['meal_selection_improvement']!).toList()),
      'mean_glucose_improvement':
          _mean(improvements.map((i) => i['glucose_improvement']!).toList()),
      'std_deviation_adherence': _standardDeviation(improvements
          .map((i) => i['dietary_adherence_improvement']!)
          .toList()),
      'overall_adherence_rate': _calculateAverageAdherence(adherenceRecords),
      'portion_compliance_rate': _calculatePortionCompliance(adherenceRecords),
      'gi_avoidance_rate': _calculateGIAvoidance(adherenceRecords),
      'average_usability_score': _mean(
          postAssessments.map((a) => a.usabilityScore.toDouble()).toList()),
      'average_engagement_score': _mean(
          postAssessments.map((a) => a.engagementScore.toDouble()).toList()),
      'average_perceived_usefulness': _mean(postAssessments
          .map((a) => a.perceivedUsefulnessScore.toDouble())
          .toList()),
      'ar_feature_usefulness': _mean(postAssessments
          .map((a) => a.arFeatureUsefulnessScore.toDouble())
          .toList()),
    };
  }

  // Helper methods
  String _escapeCSV(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  double _calculateAverageAdherence(List<DietaryAdherenceRecord> records) {
    if (records.isEmpty) return 0.0;
    return records.map((r) => r.adherenceScore).reduce((a, b) => a + b) /
        records.length;
  }

  double _calculatePortionCompliance(List<DietaryAdherenceRecord> records) {
    if (records.isEmpty) return 0.0;
    return (records.where((r) => r.followedPortionAdvice).length /
            records.length) *
        100;
  }

  double _calculateGIAvoidance(List<DietaryAdherenceRecord> records) {
    if (records.isEmpty) return 0.0;
    return (records.where((r) => r.avoidedHighGIFoods).length /
            records.length) *
        100;
  }

  double _mean(List<double> values) {
    if (values.isEmpty) return 0.0;
    return values.reduce((a, b) => a + b) / values.length;
  }

  double _standardDeviation(List<double> values) {
    if (values.isEmpty) return 0.0;
    final mean = _mean(values);
    final variance =
        values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) /
            values.length;
    return variance < 0 ? 0.0 : variance;
  }
}
