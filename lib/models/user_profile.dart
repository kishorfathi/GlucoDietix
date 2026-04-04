/// User Profile Model
class UserProfile {
  final String id;
  final String? username;
  final bool diabetes;
  final String glucoseRange; // "low", "normal", "high"
  final bool cholesterolConcern;
  final String glucoseUnit;
  final double targetGlucoseMin;
  final double targetGlucoseMax;
  final double weightKg;
  final double heightCm;
  final String diabetesType;
  final String treatment;
  final String updateFrequency;
  final String dietaryPreference;
  final bool lowGIPreference;
  final bool lowSodiumPreference;
  final DateTime? lastUpdatedAt;

  UserProfile({
    required this.id,
    this.username,
    required this.diabetes,
    required this.glucoseRange,
    required this.cholesterolConcern,
    this.glucoseUnit = 'mg/dL',
    this.targetGlucoseMin = 70,
    this.targetGlucoseMax = 95,
    this.weightKg = 70,
    this.heightCm = 170,
    this.diabetesType = 'Type 2',
    this.treatment = 'Diet',
    this.updateFrequency = 'weekly',
    this.dietaryPreference = 'none',
    this.lowGIPreference = false,
    this.lowSodiumPreference = false,
    this.lastUpdatedAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final updatedAtRaw = json['last_updated_at'] ?? json['updated_at'];
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String?,
      diabetes: json['diabetes'] as bool,
      glucoseRange: json['glucose_range'] as String,
      cholesterolConcern: json['cholesterol_concern'] as bool,
      glucoseUnit: (json['glucose_unit'] as String?) ?? 'mg/dL',
      targetGlucoseMin: (json['target_glucose_min'] as num?)?.toDouble() ?? 70,
      targetGlucoseMax: (json['target_glucose_max'] as num?)?.toDouble() ?? 95,
      weightKg: (json['weight_kg'] as num?)?.toDouble() ?? 70,
      heightCm: (json['height_cm'] as num?)?.toDouble() ?? 170,
      diabetesType: (json['diabetes_type'] as String?) ?? 'Type 2',
      treatment: (json['treatment'] as String?) ?? 'Diet',
      updateFrequency: (json['update_frequency'] as String?) ?? 'weekly',
      dietaryPreference: (json['dietary_preference'] as String?) ?? 'none',
      lowGIPreference: json['low_gi_preference'] as bool? ?? false,
      lowSodiumPreference: json['low_sodium_preference'] as bool? ?? false,
      lastUpdatedAt:
          updatedAtRaw is String ? DateTime.tryParse(updatedAtRaw) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'diabetes': diabetes,
      'glucose_range': glucoseRange,
      'cholesterol_concern': cholesterolConcern,
      'glucose_unit': glucoseUnit,
      'target_glucose_min': targetGlucoseMin,
      'target_glucose_max': targetGlucoseMax,
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'diabetes_type': diabetesType,
      'treatment': treatment,
      'update_frequency': updateFrequency,
      'dietary_preference': dietaryPreference,
      'low_gi_preference': lowGIPreference,
      'low_sodium_preference': lowSodiumPreference,
      'last_updated_at':
          (lastUpdatedAt ?? DateTime.now()).toUtc().toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? id,
    String? username,
    bool? diabetes,
    String? glucoseRange,
    bool? cholesterolConcern,
    String? glucoseUnit,
    double? targetGlucoseMin,
    double? targetGlucoseMax,
    double? weightKg,
    double? heightCm,
    String? diabetesType,
    String? treatment,
    String? updateFrequency,
    String? dietaryPreference,
    bool? lowGIPreference,
    bool? lowSodiumPreference,
    DateTime? lastUpdatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username,
      diabetes: diabetes ?? this.diabetes,
      glucoseRange: glucoseRange ?? this.glucoseRange,
      cholesterolConcern: cholesterolConcern ?? this.cholesterolConcern,
      glucoseUnit: glucoseUnit ?? this.glucoseUnit,
      targetGlucoseMin: targetGlucoseMin ?? this.targetGlucoseMin,
      targetGlucoseMax: targetGlucoseMax ?? this.targetGlucoseMax,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm ?? this.heightCm,
      diabetesType: diabetesType ?? this.diabetesType,
      treatment: treatment ?? this.treatment,
      updateFrequency: updateFrequency ?? this.updateFrequency,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
      lowGIPreference: lowGIPreference ?? this.lowGIPreference,
      lowSodiumPreference: lowSodiumPreference ?? this.lowSodiumPreference,
      lastUpdatedAt: lastUpdatedAt ?? this.lastUpdatedAt,
    );
  }
}
