import '../models/user_profile.dart';

/// Exercise Recommendation Service
/// Provides personalized exercise suggestions based on health condition and glucose levels
class ExerciseRecommendationService {
  /// Get daily exercise recommendations
  List<ExerciseRecommendation> getDailyRecommendations(
    UserProfile profile, {
    double? currentGlucose,
  }) {
    final recommendations = <ExerciseRecommendation>[];
    final glucoseLevel = currentGlucose ?? _estimateGlucoseFromProfile(profile);
    final bmi = _calculateBMI(profile.weightKg, profile.heightCm);

    // Check if it's safe to exercise
    if (!_isSafeToExercise(glucoseLevel)) {
      return [
        ExerciseRecommendation(
          title: '⚠️ Exercise Not Recommended',
          description: glucoseLevel > 240
              ? 'Blood sugar is too high. Wait until it drops below 240 mg/dL'
              : 'Blood sugar is too low. Have a snack and wait 15-30 minutes',
          duration: 0,
          intensity: ExerciseIntensity.none,
          caloriesBurn: 0,
          safetyNote: 'Monitor your glucose before exercising',
          benefits: [],
          instructions: [],
        )
      ];
    }

    // Morning routine
    recommendations.add(ExerciseRecommendation(
      title: '🌅 Morning Walk',
      description: 'Start your day with a gentle walk to boost metabolism',
      duration: 20,
      intensity: ExerciseIntensity.low,
      caloriesBurn: 80,
      bestTime: 'Morning (before breakfast or 1-2 hours after)',
      safetyNote: 'Check glucose before and after. Carry fast-acting carbs.',
      benefits: [
        'Lowers fasting blood sugar',
        'Improves insulin sensitivity',
        'Boosts mood and energy',
        'Supports cardiovascular health',
      ],
      instructions: [
        'Wear comfortable shoes',
        'Start slow and gradually increase pace',
        'Stay hydrated',
        'Monitor how you feel',
      ],
    ));

    // Yoga/Stretching
    recommendations.add(ExerciseRecommendation(
      title: '🧘 Yoga & Stretching',
      description: 'Gentle yoga to reduce stress and improve flexibility',
      duration: 15,
      intensity: ExerciseIntensity.low,
      caloriesBurn: 50,
      bestTime: 'Anytime (great before bed)',
      safetyNote: 'Avoid inverted poses if blood pressure is high',
      benefits: [
        'Reduces stress and cortisol',
        'Improves flexibility',
        'Supports better sleep',
        'Enhances mind-body connection',
      ],
      instructions: [
        'Use a yoga mat for comfort',
        'Focus on breathing',
        'Don\'t push beyond comfort',
        'Hold each pose for 15-30 seconds',
      ],
    ));

    // Moderate activity based on fitness level
    if (bmi < 30 && profile.glucoseRange != 'high') {
      recommendations.add(ExerciseRecommendation(
        title: '🚴 Cycling or Swimming',
        description: 'Low-impact cardio for better glucose control',
        duration: 30,
        intensity: ExerciseIntensity.moderate,
        caloriesBurn: 200,
        bestTime: 'Afternoon or early evening',
        safetyNote:
            'Check glucose before, during (if >30 min), and after exercise',
        benefits: [
          'Excellent for cardiovascular health',
          'Low impact on joints',
          'Burns significant calories',
          'Improves endurance',
        ],
        instructions: [
          'Start with 15 min and build up',
          'Maintain steady, comfortable pace',
          'Stay well hydrated',
          'Have a snack ready post-exercise',
        ],
      ));
    }

    // Strength training (for all)
    recommendations.add(ExerciseRecommendation(
      title: '💪 Light Resistance Training',
      description: 'Build muscle to improve glucose metabolism',
      duration: 20,
      intensity: ExerciseIntensity.moderate,
      caloriesBurn: 100,
      bestTime: '2-3 times per week',
      safetyNote: 'Start with light weights or body weight exercises',
      benefits: [
        'Builds muscle mass',
        'Increases metabolic rate',
        'Improves insulin sensitivity',
        'Strengthens bones',
      ],
      instructions: [
        'Focus on major muscle groups',
        'Use proper form over heavy weights',
        'Rest 48 hours between sessions',
        'Include: squats, push-ups, planks',
      ],
    ));

    // Evening walk
    if (profile.glucoseRange == 'high') {
      recommendations.add(ExerciseRecommendation(
        title: '🌙 Post-Dinner Walk',
        description: 'Evening walk to help manage post-meal glucose spike',
        duration: 15,
        intensity: ExerciseIntensity.low,
        caloriesBurn: 60,
        bestTime: '30 minutes after dinner',
        safetyNote: 'Great for controlling post-meal glucose',
        benefits: [
          'Reduces post-meal glucose spike',
          'Aids digestion',
          'Promotes better sleep',
          'Easy to maintain routine',
        ],
        instructions: [
          'Wait 30 min after eating',
          'Keep it gentle and relaxed',
          'Make it a daily habit',
          'Can be done with family',
        ],
      ));
    }

    return recommendations;
  }

  /// Get exercise recommendation based on current glucose level
  ExerciseRecommendation? getGlucoseBasedRecommendation(double glucoseLevel) {
    if (glucoseLevel < 100) {
      return ExerciseRecommendation(
        title: '🚶 Gentle Movement',
        description: 'Light activity recommended with glucose monitoring',
        duration: 10,
        intensity: ExerciseIntensity.low,
        caloriesBurn: 40,
        safetyNote:
            'Have fast-acting carbs available. Check glucose every 15 min.',
        benefits: ['Prevents further glucose drop while staying active'],
        instructions: [
          'Keep it very light',
          'Have glucose tablets ready',
          'Stop if you feel dizzy or shaky',
        ],
      );
    } else if (glucoseLevel > 240) {
      return null; // Not safe to exercise
    } else if (glucoseLevel > 180) {
      return ExerciseRecommendation(
        title: '🚶‍♂️ Brisk Walk',
        description: 'Moderate activity to help lower elevated glucose',
        duration: 15,
        intensity: ExerciseIntensity.moderate,
        caloriesBurn: 80,
        safetyNote: 'Will help bring glucose down. Stay hydrated.',
        benefits: [
          'Helps lower high blood sugar',
          'Improves insulin sensitivity'
        ],
        instructions: [
          'Drink water before and during',
          'Monitor how you feel',
          'Stop if glucose goes above 250',
        ],
      );
    }

    return null; // Normal range - follow regular recommendations
  }

  double _calculateBMI(double weightKg, double heightCm) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
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

  bool _isSafeToExercise(double glucoseLevel) {
    // Too low (<70) or too high (>240) is not safe
    return glucoseLevel >= 70 && glucoseLevel <= 240;
  }
}

/// Exercise Recommendation Model
class ExerciseRecommendation {
  final String title;
  final String description;
  final int duration; // minutes
  final ExerciseIntensity intensity;
  final int caloriesBurn; // estimated calories burned
  final String? bestTime;
  final String safetyNote;
  final List<String> benefits;
  final List<String> instructions;

  ExerciseRecommendation({
    required this.title,
    required this.description,
    required this.duration,
    required this.intensity,
    required this.caloriesBurn,
    this.bestTime,
    required this.safetyNote,
    required this.benefits,
    required this.instructions,
  });

  String getIntensityLabel() {
    switch (intensity) {
      case ExerciseIntensity.none:
        return 'Not Recommended';
      case ExerciseIntensity.low:
        return 'Low Intensity';
      case ExerciseIntensity.moderate:
        return 'Moderate Intensity';
      case ExerciseIntensity.high:
        return 'High Intensity';
    }
  }

  int getIntensityColor() {
    switch (intensity) {
      case ExerciseIntensity.none:
        return 0xFF9E9E9E; // Gray
      case ExerciseIntensity.low:
        return 0xFF66BB6A; // Green
      case ExerciseIntensity.moderate:
        return 0xFFFFA726; // Orange
      case ExerciseIntensity.high:
        return 0xFFEF5350; // Red
    }
  }
}

enum ExerciseIntensity {
  none,
  low,
  moderate,
  high,
}
