import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/food.dart';
import '../models/portion.dart';
import '../models/user_profile.dart';
import '../models/glucose_reading.dart';

/// Supabase Service
class SupabaseService {
  final SupabaseClient client = Supabase.instance.client;

  // Auth Methods
  Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  User? get currentUser => client.auth.currentUser;

  Stream<AuthState> get authStateChanges => client.auth.onAuthStateChange;

  // User Profile Methods
  Future<UserProfile?> getUserProfile(String userId) async {
    final response = await client
        .from('user_profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    if (response == null) return null;
    return UserProfile.fromJson(response);
  }

  Future<void> upsertUserProfile(UserProfile profile) async {
    final payload = Map<String, dynamic>.from(profile.toJson());

    // Support both legacy and extended schemas by stripping unknown columns
    // and retrying until the write is accepted by PostgREST.
    while (true) {
      try {
        final existing = await client
            .from('user_profiles')
            .select('id')
            .eq('id', profile.id)
            .maybeSingle();

        if (existing == null) {
          await client.from('user_profiles').insert(payload);
        } else {
          await client
              .from('user_profiles')
              .update(payload)
              .eq('id', profile.id);
        }
        return;
      } catch (e) {
        final missingColumn = _extractMissingColumn(e.toString());
        if (missingColumn == null || !payload.containsKey(missingColumn)) {
          rethrow;
        }
        payload.remove(missingColumn);
      }
    }
  }

  String? _extractMissingColumn(String message) {
    final patterns = [
      RegExp("column ['\\\"]?([a-zA-Z0-9_]+)['\\\"]? does not exist",
          caseSensitive: false),
      RegExp("Could not find the '([a-zA-Z0-9_]+)' column",
          caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(message);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  // Food Methods - Enhanced for Sri Lankan Food Database

  /// Search foods with multilingual support (English, Sinhala, Tamil)
  Future<List<Food>> searchFoods({
    String? searchQuery,
    String? category,
    String? subCategory,
    bool? isLocal,
  }) async {
    try {
      var query = client.from('foods').select();

      // Search by name (English, Sinhala, or Tamil)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$searchQuery%,'
            'name_sinhala.ilike.%$searchQuery%,'
            'name_tamil.ilike.%$searchQuery%');
      }

      // Filter by category
      if (category != null && category.isNotEmpty && category != 'All') {
        query = query.eq('category', category);
      }

      // Filter by sub-category
      if (subCategory != null &&
          subCategory.isNotEmpty &&
          subCategory != 'All') {
        query = query.eq('sub_category', subCategory);
      }

      // Filter local foods
      if (isLocal != null) {
        query = query.eq('is_local', isLocal);
      }

      final response = await query.order('name');
      return (response as List).map((json) => Food.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error searching foods: $e');
      return [];
    }
  }

  /// Get all food categories
  Future<List<String>> getCategories() async {
    try {
      final response =
          await client.from('foods').select('category').order('category');

      final Set<String> categories = {};
      for (var item in response as List) {
        final cat = item['category'] as String?;
        if (cat != null) categories.add(cat);
      }

      return ['All', ...categories];
    } catch (e) {
      debugPrint('Error getting categories: $e');
      return ['All'];
    }
  }

  /// Get sub-categories for a given category
  Future<List<String>> getSubCategories(String category) async {
    try {
      var query = client.from('foods').select('sub_category');

      if (category != 'All') {
        query = query.eq('category', category);
      }

      final response = await query.order('sub_category');

      final Set<String> subCategories = {};
      for (var item in response as List) {
        final subCat = item['sub_category'] as String?;
        if (subCat != null) subCategories.add(subCat);
      }

      return ['All', ...subCategories];
    } catch (e) {
      debugPrint('Error getting sub-categories: $e');
      return ['All'];
    }
  }

  /// Get detailed food information by ID
  Future<Food?> getFoodById(String foodId) async {
    try {
      final response =
          await client.from('foods').select().eq('id', foodId).maybeSingle();

      if (response == null) return null;
      return Food.fromJson(response);
    } catch (e) {
      debugPrint('Error getting food by ID: $e');
      return null;
    }
  }

  /// Get foods by glycemic index range (for diabetes management)
  Future<List<Food>> getFoodsByGlycemicIndex({
    double? minGI,
    double? maxGI,
  }) async {
    try {
      var query = client.from('foods').select();

      if (minGI != null) {
        query = query.gte('glycemic_index', minGI);
      }

      if (maxGI != null) {
        query = query.lte('glycemic_index', maxGI);
      }

      final response =
          await query.not('glycemic_index', 'is', null).order('glycemic_index');

      return (response as List).map((json) => Food.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting foods by GI: $e');
      return [];
    }
  }

  /// Get recommended foods based on user profile
  Future<List<Food>> getRecommendedFoods({
    required bool diabetes,
    required bool cholesterolConcern,
    required String glucoseRange,
  }) async {
    try {
      var query = client.from('foods').select();

      // For diabetes, recommend low GI foods
      if (diabetes) {
        query = query.lte('glycemic_index', 55);
      }

      // For cholesterol concern, recommend low cholesterol foods
      if (cholesterolConcern) {
        query = query.lte('cholesterol_mg', 50);
      }

      final response = await query
          .not('glycemic_index', 'is', null)
          .order('glycemic_index')
          .limit(20);

      return (response as List).map((json) => Food.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting recommended foods: $e');
      return [];
    }
  }

  /// Get local Sri Lankan foods only
  Future<List<Food>> getLocalFoods() async {
    try {
      final response = await client
          .from('foods')
          .select()
          .eq('is_local', true)
          .order('name');

      return (response as List).map((json) => Food.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting local foods: $e');
      return [];
    }
  }

  // Portion Methods
  Future<List<Portion>> getPortionsForFood(String foodId) async {
    final response =
        await client.from('portions').select().eq('food_id', foodId);

    return (response as List).map((json) => Portion.fromJson(json)).toList();
  }

  // Glucose Reading Methods
  Future<List<GlucoseReading>> getGlucoseReadings(
    String userId, {
    int? limit,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Build filter query
      var filterQuery = client
          .from('glucose_readings')
          .select()
          .eq('user_id', userId);

      if (startDate != null) {
        filterQuery = filterQuery.gte('timestamp', startDate.toIso8601String());
      }

      if (endDate != null) {
        filterQuery = filterQuery.lte('timestamp', endDate.toIso8601String());
      }

      // Apply order and limit
      var finalQuery = filterQuery.order('timestamp', ascending: false);

      if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }

      final response = await finalQuery;
      return (response as List)
          .map((json) => GlucoseReading.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting glucose readings: $e');
      return [];
    }
  }

  Future<void> saveGlucoseReading(GlucoseReading reading) async {
    try {
      await client.from('glucose_readings').insert(reading.toJson());
    } catch (e) {
      debugPrint('Error saving glucose reading: $e');
      rethrow;
    }
  }

  /// Get all foods (for meal recommendations)
  Future<List<Food>> getAllFoods({int? limit}) async {
    try {
      var query = client.from('foods').select().order('name');

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return (response as List).map((json) => Food.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting all foods: $e');
      return [];
    }
  }
}
