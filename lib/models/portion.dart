/// Portion Model
class Portion {
  final String id;
  final String foodId;
  final String label;
  final double grams;

  Portion({
    required this.id,
    required this.foodId,
    required this.label,
    required this.grams,
  });

  factory Portion.fromJson(Map<String, dynamic> json) {
    return Portion(
      id: json['id'] as String,
      foodId: json['food_id'] as String,
      label: json['label'] as String,
      grams: (json['grams'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'food_id': foodId,
      'label': label,
      'grams': grams,
    };
  }
}
