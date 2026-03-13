import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/food.dart';
import '../../models/user_profile.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/meal_recommendation_service.dart';
import '../../services/supabase_service.dart';

/// ML-Based Meal Recommendation Screen
/// Shows personalized meal recommendations based on user profile
class MealRecommendationsScreen extends StatefulWidget {
  const MealRecommendationsScreen({super.key});

  @override
  State<MealRecommendationsScreen> createState() =>
      _MealRecommendationsScreenState();
}

class _MealRecommendationsScreenState extends State<MealRecommendationsScreen> {
  final _recommendationService = MealRecommendationService();
  final _supabaseService = SupabaseService();
  bool _isLoading = true;
  MealRecommendations? _recommendations;
  List<Food> _availableFoods = [];
  double? _currentGlucose;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);

    try {
      // Load available foods
      _availableFoods = await _supabaseService.getAllFoods();

      // Get user profile
      final profile =
          Provider.of<UserProfileProvider>(context, listen: false).userProfile;

      if (profile != null) {
        // Get latest glucose reading if available
        final readings =
            await _supabaseService.getGlucoseReadings(profile.id, limit: 1);
        if (readings.isNotEmpty) {
          _currentGlucose = readings.first.glucoseLevel;
        }

        // Generate recommendations
        final recommendations =
            _recommendationService.getPersonalizedRecommendations(
          profile,
          _availableFoods,
          currentGlucose: _currentGlucose,
        );

        setState(() {
          _recommendations = recommendations;
        });
      }
    } catch (e) {
      debugPrint('Error loading recommendations: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<UserProfileProvider>(context).userProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Recommendations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: _loadRecommendations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _recommendations == null
              ? const Center(child: Text('Unable to load recommendations'))
              : RefreshIndicator(
                  onRefresh: _loadRecommendations,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Health Summary Card
                        _buildHealthSummaryCard(profile),
                        const SizedBox(height: 24),

                        // Breakfast
                        _buildMealSection(
                          '🌅 Breakfast',
                          _recommendations!.breakfast,
                          Icons.wb_sunny,
                          const Color(0xFFFFA726),
                        ),
                        const SizedBox(height: 20),

                        // Lunch
                        _buildMealSection(
                          '☀️ Lunch',
                          _recommendations!.lunch,
                          Icons.lunch_dining,
                          const Color(0xFF66BB6A),
                        ),
                        const SizedBox(height: 20),

                        // Dinner
                        _buildMealSection(
                          '🌙 Dinner',
                          _recommendations!.dinner,
                          Icons.dinner_dining,
                          const Color(0xFF42A5F5),
                        ),
                        const SizedBox(height: 24),

                        // Daily Summary
                        _buildDailySummary(),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildHealthSummaryCard(UserProfile? profile) {
    if (_recommendations == null || profile == null) {
      return const SizedBox.shrink();
    }

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🎯 Your Health Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildHealthMetric(
                  'BMI',
                  _recommendations!.bmi.toStringAsFixed(1),
                  _recommendations!.getBMICategory(),
                ),
                _buildHealthMetric(
                  'Daily Target',
                  _recommendations!.targetDailyCalories.toStringAsFixed(0),
                  'calories',
                ),
                _buildHealthMetric(
                  'Glucose',
                  _currentGlucose?.toStringAsFixed(0) ?? '--',
                  _recommendations!.glucoseStatus,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              _buildPreferenceLabel(profile),
              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetric(String label, String value, String subtitle) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  String _buildPreferenceLabel(UserProfile profile) {
    final parts = <String>[];
    if (profile.dietaryPreference != 'none') {
      parts.add('Preference: ${_formatPreference(profile.dietaryPreference)}');
    }
    if (profile.lowGIPreference) {
      parts.add('Low GI');
    }
    if (profile.lowSodiumPreference) {
      parts.add('Low sodium');
    }
    return parts.isEmpty ? 'Preferences: none' : parts.join(' • ');
  }

  String _formatPreference(String value) {
    switch (value) {
      case 'vegetarian':
        return 'Vegetarian';
      case 'pescatarian':
        return 'Pescatarian';
      case 'halal':
        return 'Halal';
      default:
        return 'None';
    }
  }

  Widget _buildMealSection(
    String title,
    MealRecommendation meal,
    IconData icon,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Health tip
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Text(
            meal.healthTip,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[800],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Food recommendations
        if (meal.foods.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No recommendations available for this meal'),
            ),
          )
        else
          ...meal.foods.map((recommendedFood) => _buildFoodCard(
                recommendedFood,
                color,
              )),

        const SizedBox(height: 8),

        // Meal totals
        Card(
          color: color.withOpacity(0.05),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMealTotal(
                  'Total Calories',
                  '${meal.totalCalories.toStringAsFixed(0)} kcal',
                ),
                _buildMealTotal(
                  'Total Carbs',
                  '${meal.totalCarbs.toStringAsFixed(1)}g',
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodCard(RecommendedFood recommendedFood, Color accentColor) {
    final food = recommendedFood.food;
    final portion = recommendedFood.portionGrams;
    final calories = (food.energyKcal * portion / 100);
    final carbs = (food.carbs100g * portion / 100);
    final protein = (food.protein100g * portion / 100);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        food.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${portion.toStringAsFixed(0)}g portion',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${calories.toStringAsFixed(0)} cal',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: accentColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Reason
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lightbulb, size: 16, color: Colors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      recommendedFood.reason,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Nutrition info
            Row(
              children: [
                _buildNutrientBadge('Carbs', '${carbs.toStringAsFixed(1)}g'),
                const SizedBox(width: 8),
                _buildNutrientBadge(
                    'Protein', '${protein.toStringAsFixed(1)}g'),
                const SizedBox(width: 8),
                if (food.glycemicIndex != null)
                  _buildNutrientBadge('GI', '${food.glycemicIndex}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientBadge(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  Widget _buildMealTotal(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildDailySummary() {
    if (_recommendations == null) return const SizedBox.shrink();

    final totalCalories = _recommendations!.breakfast.totalCalories +
        _recommendations!.lunch.totalCalories +
        _recommendations!.dinner.totalCalories;

    final totalCarbs = _recommendations!.breakfast.totalCarbs +
        _recommendations!.lunch.totalCarbs +
        _recommendations!.dinner.totalCarbs;

    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📊 Daily Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total Calories',
                  totalCalories.toStringAsFixed(0),
                  '/ ${_recommendations!.targetDailyCalories.toStringAsFixed(0)}',
                ),
                _buildSummaryItem(
                  'Total Carbs',
                  '${totalCarbs.toStringAsFixed(1)}g',
                  'distributed',
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              '💡 Tips for Success:',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Follow portion sizes for better glucose control\n'
              '• Spread carbs evenly across meals\n'
              '• Include protein and fiber in every meal\n'
              '• Monitor your glucose before and after meals\n'
              '• Stay hydrated throughout the day',
              style: TextStyle(fontSize: 13, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, String subtitle) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
