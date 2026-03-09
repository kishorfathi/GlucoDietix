import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/meal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../models/meal_item.dart';
import '../../services/health_recommendation_service.dart';

/// Results Screen
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);

    if (authProvider.user != null &&
        !profileProvider.isLoadedFor(authProvider.user!.id)) {
      await profileProvider.loadUserProfile(authProvider.user!.id);
    }
  }

  String _slugify(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
  }

  Future<void> _openAR(String foodName, double grams) async {
    final slug = _slugify(foodName);
    final url =
        'https://YOUR_HOST/ar.html?food=$slug&grams=${grams.toStringAsFixed(0)}';

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not open AR view'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = Provider.of<MealProvider>(context);
    final profileProvider = Provider.of<UserProfileProvider>(context);
    final healthService = HealthRecommendationService();

    // Get health analysis
    final analysis = healthService.analyzeMeal(
      mealProvider.mealItems,
      profileProvider.userProfile,
    );

    // Calculate totals
    final totalKcal = mealProvider.totalKcal;
    final totalCarbs = mealProvider.totalCarbs;
    final totalProtein = mealProvider.totalProtein;
    final totalFat = mealProvider.totalFat;
    final totalFiber = mealProvider.totalFiber;

    // Determine target carbs based on glucose range
    double targetCarbs = 60;
    if (profileProvider.userProfile != null) {
      if (profileProvider.userProfile!.glucoseRange == 'high') {
        targetCarbs = 45;
      }
    }

    // Check if meal is OK
    final isOk = totalCarbs <= targetCarbs;

    // Find recommendation
    MealItem? highestCarbItem;
    double recommendedGrams = 0;

    if (!isOk && mealProvider.mealItems.isNotEmpty) {
      // Find item with highest carbs
      highestCarbItem = mealProvider.mealItems.reduce(
        (a, b) => a.carbs > b.carbs ? a : b,
      );

      // Calculate how much to reduce
      final excessCarbs = totalCarbs - targetCarbs;
      final carbsPer100g = highestCarbItem.food.carbs100g;
      final gramsToReduce = (excessCarbs / carbsPer100g) * 100;
      recommendedGrams = (highestCarbItem.grams - gramsToReduce)
          .clamp(0, highestCarbItem.grams);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Analysis'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // Health Score Card
          Card(
            color: _getHealthScoreColor(analysis.healthScore),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Health Score',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          Text(
                            '${analysis.healthScore}/100',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        _getHealthScoreIcon(analysis.overallRating),
                        size: 64,
                        color: Colors.white,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getHealthScoreLabel(analysis.overallRating),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Warnings
          if (analysis.warnings.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.warning_amber, color: Colors.orange),
                        SizedBox(width: 8),
                        Text(
                          'Important Warnings',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...analysis.warnings.map((warning) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Text(
                            warning,
                            style: const TextStyle(fontSize: 15),
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ],

          // Portion Suggestions
          if (analysis.portionSuggestions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.food_bank, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Portion Adjustments',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...analysis.portionSuggestions.map((suggestion) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.0),
                          child: Row(
                            children: [
                              const Icon(Icons.arrow_right,
                                  size: 20, color: Colors.blue),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  suggestion,
                                  style: const TextStyle(fontSize: 15),
                                ),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ),
          ],

          // Recommendations
          const SizedBox(height: 16),
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.lightbulb, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Health Recommendations',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...analysis.recommendations.map((rec) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          rec,
                          style: const TextStyle(fontSize: 15),
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Nutrient Totals',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildNutrientRow('Calories', totalKcal, 'kcal'),
                  _buildNutrientRow('Carbs', totalCarbs, 'g'),
                  _buildNutrientRow('Protein', totalProtein, 'g'),
                  _buildNutrientRow('Fat', totalFat, 'g'),
                  _buildNutrientRow('Fiber', totalFiber, 'g'),
                ],
              ),
            ),
          ),
          if (!isOk && highestCarbItem != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Recommendation',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Card(
              color: Colors.orange.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reduce ${highestCarbItem.food.name}:',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Current: ${highestCarbItem.grams.toStringAsFixed(0)}g',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Recommended: ${recommendedGrams.toStringAsFixed(0)}g',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _openAR(
                          highestCarbItem!.food.name,
                          recommendedGrams,
                        ),
                        icon: const Icon(Icons.view_in_ar),
                        label: const Text('View in AR'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurple,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Meal Items',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ...mealProvider.mealItems.map((item) {
            return Card(
              child: ListTile(
                title: Text(item.food.name),
                subtitle: Text(
                  '${item.grams.toStringAsFixed(0)}g • ${item.carbs.toStringAsFixed(1)}g carbs • ${item.kcal.toStringAsFixed(0)} kcal',
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _getHealthScoreColor(int score) {
    if (score >= 80) return Colors.green.shade600;
    if (score >= 60) return Colors.lightGreen.shade600;
    if (score >= 40) return Colors.orange.shade600;
    return Colors.red.shade600;
  }

  IconData _getHealthScoreIcon(String rating) {
    switch (rating) {
      case 'excellent':
        return Icons.sentiment_very_satisfied;
      case 'good':
        return Icons.sentiment_satisfied;
      case 'moderate':
        return Icons.sentiment_neutral;
      case 'caution':
        return Icons.sentiment_dissatisfied;
      default:
        return Icons.help_outline;
    }
  }

  String _getHealthScoreLabel(String rating) {
    switch (rating) {
      case 'excellent':
        return 'Excellent Choice!';
      case 'good':
        return 'Good Choice';
      case 'moderate':
        return 'Moderate - Can Improve';
      case 'caution':
        return 'Needs Adjustment';
      default:
        return 'Unknown';
    }
  }

  Widget _buildNutrientRow(String label, double value, String unit) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            '${value.toStringAsFixed(1)} $unit',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
