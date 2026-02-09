/// User Profile Model
class UserProfile {
  final String id;
  final bool diabetes;
  final String glucoseRange; // "low", "normal", "high"
  final bool cholesterolConcern;

  UserProfile({
    required this.id,
    required this.diabetes,
    required this.glucoseRange,
    required this.cholesterolConcern,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      diabetes: json['diabetes'] as bool,
      glucoseRange: json['glucose_range'] as String,
      cholesterolConcern: json['cholesterol_concern'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'diabetes': diabetes,
      'glucose_range': glucoseRange,
      'cholesterol_concern': cholesterolConcern,
    };
  }

  UserProfile copyWith({
    String? id,
    bool? diabetes,
    String? glucoseRange,
    bool? cholesterolConcern,
  }) {
    return UserProfile(
      id: id ?? this.id,
      diabetes: diabetes ?? this.diabetes,
      glucoseRange: glucoseRange ?? this.glucoseRange,
      cholesterolConcern: cholesterolConcern ?? this.cholesterolConcern,
    );
  }
}
