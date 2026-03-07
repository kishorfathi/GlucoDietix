/// Food Model - Enhanced for Sri Lankan Food Database
class Food {
  final String id;
  final String name;
  final String? nameSinhala;
  final String? nameTamil;
  final String category;
  final String? subCategory;

  // Macronutrients per 100g
  final double carbs100g;
  final double protein100g;
  final double fat100g;
  final double fiber100g;
  final double energyKcal;

  // Micronutrients
  final double? calciumMg;
  final double? ironMg;
  final double? vitaminAMcg;
  final double? vitaminCMg;
  final double? thiaminMg;
  final double? riboflavinMg;
  final double? niacinMg;

  // Health markers
  final double? glycemicIndex;
  final double? glycemicLoad;
  final double? cholesterolMg;
  final double? sodiumMg;
  final double? potassiumMg;

  // Additional info
  final double ediblePortionPercent;
  final double waterContentPercent;
  final double servingSizeG;
  final bool isLocal;
  final String? source;

  Food({
    required this.id,
    required this.name,
    this.nameSinhala,
    this.nameTamil,
    required this.category,
    this.subCategory,
    required this.carbs100g,
    required this.protein100g,
    required this.fat100g,
    required this.fiber100g,
    required this.energyKcal,
    this.calciumMg,
    this.ironMg,
    this.vitaminAMcg,
    this.vitaminCMg,
    this.thiaminMg,
    this.riboflavinMg,
    this.niacinMg,
    this.glycemicIndex,
    this.glycemicLoad,
    this.cholesterolMg,
    this.sodiumMg,
    this.potassiumMg,
    this.ediblePortionPercent = 100,
    this.waterContentPercent = 0,
    this.servingSizeG = 100,
    this.isLocal = true,
    this.source,
  });

  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] as String,
      name: json['name'] as String,
      nameSinhala: json['name_sinhala'] as String?,
      nameTamil: json['name_tamil'] as String?,
      category: json['category'] as String,
      subCategory: json['sub_category'] as String?,
      carbs100g: (json['carbs_100g'] as num).toDouble(),
      protein100g: (json['protein_100g'] as num).toDouble(),
      fat100g: (json['fat_100g'] as num).toDouble(),
      fiber100g: (json['fiber_100g'] as num? ?? 0).toDouble(),
      energyKcal: (json['energy_kcal'] as num).toDouble(),
      calciumMg: json['calcium_mg'] != null
          ? (json['calcium_mg'] as num).toDouble()
          : null,
      ironMg:
          json['iron_mg'] != null ? (json['iron_mg'] as num).toDouble() : null,
      vitaminAMcg: json['vitamin_a_mcg'] != null
          ? (json['vitamin_a_mcg'] as num).toDouble()
          : null,
      vitaminCMg: json['vitamin_c_mg'] != null
          ? (json['vitamin_c_mg'] as num).toDouble()
          : null,
      thiaminMg: json['thiamin_mg'] != null
          ? (json['thiamin_mg'] as num).toDouble()
          : null,
      riboflavinMg: json['riboflavin_mg'] != null
          ? (json['riboflavin_mg'] as num).toDouble()
          : null,
      niacinMg: json['niacin_mg'] != null
          ? (json['niacin_mg'] as num).toDouble()
          : null,
      glycemicIndex: json['glycemic_index'] != null
          ? (json['glycemic_index'] as num).toDouble()
          : null,
      glycemicLoad: json['glycemic_load'] != null
          ? (json['glycemic_load'] as num).toDouble()
          : null,
      cholesterolMg: json['cholesterol_mg'] != null
          ? (json['cholesterol_mg'] as num).toDouble()
          : null,
      sodiumMg: json['sodium_mg'] != null
          ? (json['sodium_mg'] as num).toDouble()
          : null,
      potassiumMg: json['potassium_mg'] != null
          ? (json['potassium_mg'] as num).toDouble()
          : null,
      ediblePortionPercent: json['edible_portion_percent'] != null
          ? (json['edible_portion_percent'] as num).toDouble()
          : 100,
      waterContentPercent: json['water_content_percent'] != null
          ? (json['water_content_percent'] as num).toDouble()
          : 0,
      servingSizeG: json['serving_size_g'] != null
          ? (json['serving_size_g'] as num).toDouble()
          : 100,
      isLocal: json['is_local'] as bool? ?? true,
      source: json['source'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'name_sinhala': nameSinhala,
      'name_tamil': nameTamil,
      'category': category,
      'sub_category': subCategory,
      'carbs_100g': carbs100g,
      'protein_100g': protein100g,
      'fat_100g': fat100g,
      'fiber_100g': fiber100g,
      'energy_kcal': energyKcal,
      'calcium_mg': calciumMg,
      'iron_mg': ironMg,
      'vitamin_a_mcg': vitaminAMcg,
      'vitamin_c_mg': vitaminCMg,
      'thiamin_mg': thiaminMg,
      'riboflavin_mg': riboflavinMg,
      'niacin_mg': niacinMg,
      'glycemic_index': glycemicIndex,
      'glycemic_load': glycemicLoad,
      'cholesterol_mg': cholesterolMg,
      'sodium_mg': sodiumMg,
      'potassium_mg': potassiumMg,
      'edible_portion_percent': ediblePortionPercent,
      'water_content_percent': waterContentPercent,
      'serving_size_g': servingSizeG,
      'is_local': isLocal,
      'source': source,
    };
  }

  // Calculate nutrients for a specific portion size
  Map<String, double> getNutrientsForPortion(double portionGrams) {
    final factor = portionGrams / 100;
    return {
      'carbs': carbs100g * factor,
      'protein': protein100g * factor,
      'fat': fat100g * factor,
      'fiber': fiber100g * factor,
      'energy': energyKcal * factor,
      'calcium': (calciumMg ?? 0) * factor,
      'iron': (ironMg ?? 0) * factor,
    };
  }

  // Get glycemic impact
  String getGlycemicImpact() {
    if (glycemicIndex == null) return 'Unknown';
    if (glycemicIndex! <= 55) return 'Low';
    if (glycemicIndex! <= 69) return 'Medium';
    return 'High';
  }

  // Is suitable for diabetes
  bool isSuitableForDiabetes() {
    return glycemicIndex != null && glycemicIndex! <= 55;
  }

  // Is suitable for cholesterol concern
  bool isSuitableForCholesterol() {
    return cholesterolMg == null || cholesterolMg! < 50;
  }

  // Get display name (with local language if available)
  String getDisplayName({String language = 'en'}) {
    if (language == 'si' && nameSinhala != null) {
      return '$name ($nameSinhala)';
    } else if (language == 'ta' && nameTamil != null) {
      return '$name ($nameTamil)';
    }
    return name;
  }
}
