import 'package:supabase_flutter/supabase_flutter.dart';

/// GlucoDietix Nutrition Service
/// Queries Supabase database for nutrition information
class GlucoDietixNutritionService {
  final SupabaseClient _supabase;

  GlucoDietixNutritionService({SupabaseClient? supabase})
      : _supabase = supabase ?? Supabase.instance.client;

  /// Get nutrition data for a single food item by name
  Future<FoodNutrition?> getNutritionByName(String foodName) async {
    try {
      print('🔍 Querying nutrition for: $foodName');

      final response = await _supabase
          .from('foods')
          .select()
          .ilike('name', foodName)
          .maybeSingle();

      if (response == null) {
        print('⚠️  No nutrition data found for: $foodName');
        return null;
      }

      return FoodNutrition.fromJson(response);
    } catch (e) {
      print('❌ Error fetching nutrition: $e');
      return null;
    }
  }

  /// Get nutrition data for multiple food items
  Future<List<FoodNutrition>> getNutritionForMultipleFoods(
      List<String> foodNames) async {
    try {
      print('🔍 Querying nutrition for ${foodNames.length} foods');

      final response =
          await _supabase.from('foods').select().in_('name', foodNames);

      if (response.isEmpty) {
        print('⚠️  No nutrition data found');
        return [];
      }

      return (response as List)
          .map((item) => FoodNutrition.fromJson(item))
          .toList();
    } catch (e) {
      print('❌ Error fetching nutrition: $e');
      return [];
    }
  }

  /// Search foods by partial name match
  Future<List<FoodNutrition>> searchFoods(String query) async {
    try {
      final response = await _supabase
          .from('foods')
          .select()
          .ilike('name', '%$query%')
          .limit(10);

      return (response as List)
          .map((item) => FoodNutrition.fromJson(item))
          .toList();
    } catch (e) {
      print('❌ Error searching foods: $e');
      return [];
    }
  }

  /// Get all foods from database
  Future<List<FoodNutrition>> getAllFoods() async {
    try {
      final response = await _supabase.from('foods').select();

      return (response as List)
          .map((item) => FoodNutrition.fromJson(item))
          .toList();
    } catch (e) {
      print('❌ Error fetching all foods: $e');
      return [];
    }
  }
}

/// Food Nutrition Data Model
class FoodNutrition {
  final int id;
  final String name;
  final double portionG;
  final double energyKcal;
  final double proteinG;
  final double fatG;
  final double carbohydrateG;
  final String diabeticGuideline;

  FoodNutrition({
    required this.id,
    required this.name,
    required this.portionG,
    required this.energyKcal,
    required this.proteinG,
    required this.fatG,
    required this.carbohydrateG,
    required this.diabeticGuideline,
  });

  factory FoodNutrition.fromJson(Map<String, dynamic> json) {
    return FoodNutrition(
      id: json['id'] as int,
      name: json['name'] as String,
      portionG: (json['portion_g'] as num).toDouble(),
      energyKcal: (json['energy_kcal'] as num).toDouble(),
      proteinG: (json['protein_g'] as num).toDouble(),
      fatG: (json['fat_g'] as num).toDouble(),
      carbohydrateG: (json['carbohydrate_g'] as num).toDouble(),
      diabeticGuideline: json['diabetic_guideline'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'portion_g': portionG,
      'energy_kcal': energyKcal,
      'protein_g': proteinG,
      'fat_g': fatG,
      'carbohydrate_g': carbohydrateG,
      'diabetic_guideline': diabeticGuideline,
    };
  }
}
