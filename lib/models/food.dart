/// Food Model
class Food {
  final String id;
  final String name;
  final String category;
  final double kcal100g;
  final double carbs100g;
  final double protein100g;
  final double fat100g;
  final double? fiber100g;
  final double? sugar100g;

  Food({
    required this.id,
    required this.name,
    required this.category,
    required this.kcal100g,
    required this.carbs100g,
    required this.protein100g,
    required this.fat100g,
    this.fiber100g,
    this.sugar100g,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      kcal100g: (json['kcal_100g'] as num).toDouble(),
      carbs100g: (json['carbs_100g'] as num).toDouble(),
      protein100g: (json['protein_100g'] as num).toDouble(),
      fat100g: (json['fat_100g'] as num).toDouble(),
      fiber100g: json['fiber_100g'] != null ? (json['fiber_100g'] as num).toDouble() : null,
      sugar100g: json['sugar_100g'] != null ? (json['sugar_100g'] as num).toDouble() : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'kcal_100g': kcal100g,
      'carbs_100g': carbs100g,
      'protein_100g': protein100g,
      'fat_100g': fat100g,
      'fiber_100g': fiber100g,
      'sugar_100g': sugar100g,
    };
  }
}
