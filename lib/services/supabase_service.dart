import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food.dart';
import '../models/portion.dart';
import '../models/user_profile.dart';

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
    await client.from('user_profiles').upsert(profile.toJson());
  }

  // Food Methods
  Future<List<Food>> searchFoods({String? searchQuery, String? category}) async {
    var query = client.from('foods').select();

    if (searchQuery != null && searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$searchQuery%');
    }

    if (category != null && category.isNotEmpty) {
      query = query.eq('category', category);
    }

    final response = await query;
    return (response as List).map((json) => Food.fromJson(json)).toList();
  }

  Future<List<String>> getCategories() async {
    final response = await client.from('foods').select('category').order('category');
    final Set<String> categories = {};
    for (var item in response as List) {
      categories.add(item['category'] as String);
    }
    return categories.toList();
  }

  // Portion Methods
  Future<List<Portion>> getPortionsForFood(String foodId) async {
    final response = await client
        .from('portions')
        .select()
        .eq('food_id', foodId);

    return (response as List).map((json) => Portion.fromJson(json)).toList();
  }
}
