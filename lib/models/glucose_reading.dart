/// Glucose Reading Model - For Research Data Collection
class GlucoseReading {
  final String id;
  final String userId;
  final double glucoseLevel; // mg/dL
  final DateTime timestamp;
  final String readingType; // fasting, before_meal, after_meal, random
  final String? mealId; // Link to meal if after_meal
  final String? notes;

  GlucoseReading({
    required this.id,
    required this.userId,
    required this.glucoseLevel,
    required this.timestamp,
    required this.readingType,
    this.mealId,
    this.notes,
  });

  factory GlucoseReading.fromJson(Map<String, dynamic> json) {
    return GlucoseReading(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      glucoseLevel: (json['glucose_level'] as num).toDouble(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      readingType: json['reading_type'] as String,
      mealId: json['meal_id'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'glucose_level': glucoseLevel,
      'timestamp': timestamp.toIso8601String(),
      'reading_type': readingType,
      'meal_id': mealId,
      'notes': notes,
    };
  }

  /// Check if glucose is in target range (80-130 mg/dL for fasting)
  bool isInTargetRange({double minTarget = 80, double maxTarget = 130}) {
    return glucoseLevel >= minTarget && glucoseLevel <= maxTarget;
  }

  /// Get status color based on range
  String getStatus() {
    if (glucoseLevel < 70) return 'Low';
    if (glucoseLevel <= 130) return 'Normal';
    if (glucoseLevel <= 180) return 'High';
    return 'Very High';
  }
}
