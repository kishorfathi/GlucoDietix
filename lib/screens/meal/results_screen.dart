import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/meal_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../models/meal_item.dart';
import '../../services/health_recommendation_service.dart';
import '../../services/plate_method_service.dart';
import '../../services/research_logging_service.dart';
import '../../services/supabase_service.dart';
import '../ar/ar_portion_viewer.dart';
import '../research/informed_consent_screen.dart';

/// Results Screen
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final ResearchLoggingService _researchLoggingService =
      ResearchLoggingService();
  bool _isSavingLog = false;

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

  void _openAR(String foodName, double grams) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ARPortionViewer(
          foodName: foodName,
          portionGrams: grams,
        ),
      ),
    );
  }

  Future<void> _saveMealToResearchLog() async {
    if (_isSavingLog) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);
    final mealProvider = Provider.of<MealProvider>(context, listen: false);

    final userId = authProvider.user?.id;
    if (userId == null) return;

    if (mealProvider.mealItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add foods before saving a research log.'),
        ),
      );
      return;
    }

    setState(() => _isSavingLog = true);

    try {
      final consent = await _supabaseService.getInformedConsent(userId);
      final isConsented =
          consent != null && consent.isFullyConsented && !consent.hasWithdrawn;

      if (!isConsented) {
        if (!mounted) return;
        final goToConsent = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Consent Required'),
            content: const Text(
              'Please review and sign the informed consent before '
              'logging research data.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Review Consent'),
              ),
            ],
          ),
        );

        if (goToConsent == true && mounted) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const InformedConsentScreen(),
            ),
          );
        }
        return;
      }

      final analysis = HealthRecommendationService().analyzeMeal(
        mealProvider.mealItems,
        profileProvider.userProfile,
      );

      await _researchLoggingService.logMealForResearch(
        userId: userId,
        items: mealProvider.mealItems,
        analysis: analysis,
        profile: profileProvider.userProfile,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Meal saved to research log.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save research log: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSavingLog = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = Provider.of<MealProvider>(context);
    final profileProvider = Provider.of<UserProfileProvider>(context);
    final healthService = HealthRecommendationService();
    final plateService = PlateMethodService();

    // Get health analysis
    final analysis = healthService.analyzeMeal(
      mealProvider.mealItems,
      profileProvider.userProfile,
    );

    // Get plate method recommendations
    final plateRecommendation =
        plateService.getPlateRecommendations(mealProvider.mealItems);

    // Calculate totals
    final totalKcal = mealProvider.totalKcal;
    final totalCarbs = mealProvider.totalCarbs;
    final totalProtein = mealProvider.totalProtein;
    final totalFat = mealProvider.totalFat;
    final totalFiber = mealProvider.totalFiber;

    final profile = profileProvider.userProfile;

    // Determine diabetes-specific carb target.
    double targetCarbs = 60;
    if (profile != null) {
      switch (profile.glucoseRange) {
        case 'high':
          targetCarbs = 45;
          break;
        case 'low':
          targetCarbs = 70;
          break;
        default:
          targetCarbs = profile.diabetes ? 50 : 60;
      }
    }

    final diabetesFocus =
        profile?.diabetes == true || profile?.glucoseRange == 'high';
    final giValues = mealProvider.mealItems
        .map((item) => item.food.glycemicIndex)
        .whereType<double>()
        .toList();
    final avgGi = giValues.isEmpty
        ? null
        : giValues.reduce((a, b) => a + b) / giValues.length;
    final hasHighGiFood = mealProvider.mealItems
        .any((item) => (item.food.glycemicIndex ?? 0) >= 70);

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

          if (diabetesFocus) ...[
            const SizedBox(height: 16),
            _buildDiabetesVerdictCard(
              totalCarbs: totalCarbs,
              targetCarbs: targetCarbs,
              avgGi: avgGi,
              hasHighGiFood: hasHighGiFood,
              analysis: analysis,
            ),
          ],

          // Plate Method Recommendations
          if (plateRecommendation.portions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Card(
              color: const Color(0xFFE8F5F3),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.restaurant, color: Color(0xFF0B8F87)),
                        const SizedBox(width: 8),
                        const Text(
                          '🍽️ Healthy Plate Method',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        if (plateRecommendation.isBalanced)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Balanced',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Recommended portions for diabetes management:',
                      style: TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 12),

                    // Plate visualization
                    _buildPlateVisualization(plateRecommendation),

                    const SizedBox(height: 16),

                    // Detailed portions by category
                    ...plateRecommendation.portionsByCategory.entries
                        .map((entry) {
                      return _buildCategorySection(
                        entry.key,
                        entry.value,
                        mealProvider,
                      );
                    }),

                    // Missing food groups warning
                    if (!plateRecommendation.isBalanced &&
                        plateRecommendation.missingGroups.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline,
                                    size: 18, color: Colors.orange),
                                SizedBox(width: 6),
                                Text(
                                  'Consider adding:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            ...plateRecommendation.missingGroups
                                .map((group) => Padding(
                                      padding: const EdgeInsets.only(left: 24),
                                      child: Text(
                                        '• $group',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    )),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        _showPlateMethodGuide(context, plateService);
                      },
                      icon: const Icon(Icons.help_outline),
                      label: const Text('Learn about the Plate Method'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0B8F87),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

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
                        label: const Text('View Recommended Portion in AR'),
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
            'Research Log',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Save this meal to the study log. This records meal history '
                    'and dietary adherence metrics for analysis.',
                    style: TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _isSavingLog ? null : _saveMealToResearchLog,
                      icon: const Icon(Icons.save),
                      label: Text(_isSavingLog
                          ? 'Saving...'
                          : 'Save Meal to Research Log'),
                    ),
                  ),
                ],
              ),
            ),
          ),
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

  Widget _buildPlateVisualization(PlateRecommendation recommendation) {
    final categoryColors = {
      FoodCategory.rice: const Color(0xFFFFF9E6),
      FoodCategory.vegetable: const Color(0xFFE8F5E9),
      FoodCategory.protein: const Color(0xFFFFEBEE),
      FoodCategory.dhal: const Color(0xFFFFF3E0),
      FoodCategory.other: Colors.grey.shade100,
    };

    return Column(
      children: [
        // Visual portion guide
        _buildVisualPortionGuide(recommendation),

        const SizedBox(height: 12),

        // Legend
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: recommendation.portionsByCategory.keys.map((category) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: categoryColors[category],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 4),
                  Text(
                    category.displayName,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildVisualPortionGuide(PlateRecommendation recommendation) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📏 Visual Portion Sizes',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Show visual size indicators for each category
          ...recommendation.portionsByCategory.entries.map((entry) {
            final portions = entry.value;
            if (portions.isEmpty) return const SizedBox.shrink();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildPortionSizeIndicator(entry.key, portions),
            );
          }),

          const SizedBox(height: 8),

          // Hand measurement guide
          _buildHandMeasurementGuide(),
        ],
      ),
    );
  }

  Widget _buildHandMeasurementGuide() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF0B8F87).withOpacity(0.1),
            const Color(0xFF47BAC1).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF0B8F87).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pan_tool, color: Color(0xFF0B8F87), size: 18),
              SizedBox(width: 6),
              Text(
                'Quick Hand Measurement Guide',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0B8F87),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildHandMeasurement(
              '👊', 'Fist', 'Carbs (Rice/Grains)', '~1 cup / 150g'),
          _buildHandMeasurement('✋', 'Palm', 'Protein', '~100g'),
          _buildHandMeasurement('🤏', 'Cupped Hand', 'Dhal', '~½ cup / 120g'),
          _buildHandMeasurement(
              '👐', 'Two Hands', 'Vegetables', '~2 cups / 300g'),
        ],
      ),
    );
  }

  Widget _buildHandMeasurement(
      String emoji, String handType, String foodType, String amount) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: Colors.black87),
                children: [
                  TextSpan(
                    text: '$handType: ',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: '$foodType '),
                  TextSpan(
                    text: amount,
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortionSizeIndicator(
    FoodCategory category,
    List<PlatePortion> portions,
  ) {
    final totalGrams = portions.fold<double>(
      0,
      (sum, p) => sum + p.recommendedGrams,
    );

    // Visual representation of portion size
    String sizeIndicator;
    String visualGuide;
    IconData icon;

    switch (category) {
      case FoodCategory.rice:
        sizeIndicator = '1 Cup';
        visualGuide = 'Fill to fist size';
        icon = Icons.rice_bowl;
        break;
      case FoodCategory.vegetable:
        sizeIndicator = '2 Cups';
        visualGuide = 'Two handfuls or half plate';
        icon = Icons.eco;
        break;
      case FoodCategory.protein:
        sizeIndicator = '3-4 Tbsp';
        visualGuide = 'Palm-sized portion';
        icon = Icons.set_meal;
        break;
      case FoodCategory.dhal:
        sizeIndicator = '½ Cup';
        visualGuide = 'Half fist size';
        icon = Icons.soup_kitchen;
        break;
      case FoodCategory.other:
        sizeIndicator = 'Small';
        visualGuide = 'Side portion';
        icon = Icons.food_bank;
        break;
    }

    return Row(
      children: [
        // Icon
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: _getCategoryColor(category).withOpacity(0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: _getCategoryColor(category), size: 24),
        ),
        const SizedBox(width: 12),

        // Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    category.emoji,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    category.displayName,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0B8F87),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      sizeIndicator,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${totalGrams.toStringAsFixed(0)}g',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(Icons.pan_tool, size: 12, color: Colors.grey.shade600),
                  const SizedBox(width: 4),
                  Text(
                    visualGuide,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              _buildObjectComparison(category),
            ],
          ),
        ),

        // Visual portion bar
        SizedBox(
          width: 60,
          child: Column(
            children: [
              LinearProgressIndicator(
                value:
                    portions.fold<double>(0, (sum, p) => sum + p.portionCount) /
                        4,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation(_getCategoryColor(category)),
                minHeight: 8,
              ),
              const SizedBox(height: 2),
              Text(
                '${(portions.fold<double>(0, (sum, p) => sum + p.portionCount) * 25).toStringAsFixed(0)}%',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getCategoryColor(FoodCategory category) {
    switch (category) {
      case FoodCategory.rice:
        return const Color(0xFFFFB347);
      case FoodCategory.vegetable:
        return const Color(0xFF4CAF50);
      case FoodCategory.protein:
        return const Color(0xFFE57373);
      case FoodCategory.dhal:
        return const Color(0xFFFFD54F);
      case FoodCategory.other:
        return Colors.grey.shade600;
    }
  }

  Widget _buildObjectComparison(FoodCategory category) {
    String comparison;
    switch (category) {
      case FoodCategory.rice:
        comparison = '≈ Tennis ball size';
        break;
      case FoodCategory.vegetable:
        comparison = '≈ 2 Baseballs';
        break;
      case FoodCategory.protein:
        comparison = '≈ Deck of cards';
        break;
      case FoodCategory.dhal:
        comparison = '≈ Light bulb size';
        break;
      case FoodCategory.other:
        comparison = '≈ Golf ball';
        break;
    }

    return Row(
      children: [
        Icon(Icons.circle, size: 8, color: Colors.grey.shade400),
        const SizedBox(width: 4),
        Text(
          comparison,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySection(
    FoodCategory category,
    List<PlatePortion> portions,
    MealProvider mealProvider,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                category.emoji,
                style: const TextStyle(fontSize: 24),
              ),
              const SizedBox(width: 8),
              Text(
                category.displayName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B8F87).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${portions.fold<double>(0, (sum, p) => sum + p.portionCount)} portion${portions.fold<double>(0, (sum, p) => sum + p.portionCount) == 1 ? '' : 's'}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0B8F87),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...portions.map((portion) {
            final currentGrams = mealProvider.mealItems
                .firstWhere(
                  (item) => item.food.id == portion.food.id,
                  orElse: () => MealItem(
                    food: portion.food,
                    grams: 0,
                  ),
                )
                .grams;

            final isCorrectPortion =
                (currentGrams - portion.recommendedGrams).abs() <
                    20; // Within 20g tolerance

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isCorrectPortion ? Icons.check_circle : Icons.adjust,
                    size: 16,
                    color: isCorrectPortion ? Colors.green : Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          portion.food.name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${portion.measurement} (${portion.recommendedGrams.toStringAsFixed(0)}g)',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          portion.recommendation,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        if (!isCorrectPortion) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Text(
                                'Current: ${currentGrams.toStringAsFixed(0)}g',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  mealProvider.updateGrams(
                                    portion.food.id,
                                    portion.recommendedGrams,
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade100,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: const Text(
                                    'Apply',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  void _showPlateMethodGuide(BuildContext context, PlateMethodService service) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🍽️ Healthy Plate Method'),
        content: SingleChildScrollView(
          child: Text(service.getPortionGuide()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it!'),
          ),
        ],
      ),
    );
  }

  Widget _buildDiabetesVerdictCard({
    required double totalCarbs,
    required double targetCarbs,
    required double? avgGi,
    required bool hasHighGiFood,
    required MealAnalysis analysis,
  }) {
    final carbsOk = totalCarbs <= targetCarbs;
    final giOk = !hasHighGiFood;
    final scoreOk = analysis.healthScore >= 60;
    final isGoodForDiabetes = carbsOk && giOk && scoreOk;

    final verdictColor = isGoodForDiabetes ? Colors.green : Colors.orange;
    final verdictIcon =
        isGoodForDiabetes ? Icons.check_circle : Icons.warning_amber;
    final verdictText = isGoodForDiabetes
        ? 'Good for your diabetes profile'
        : 'Needs adjustment for better glucose control';

    final reasons = <String>[
      'Carbs: ${totalCarbs.toStringAsFixed(1)}g (target <= ${targetCarbs.toStringAsFixed(0)}g)',
      if (avgGi != null) 'Average GI: ${avgGi.toStringAsFixed(0)}',
      if (hasHighGiFood) 'High-GI items detected in this meal',
      if (!scoreOk) 'Health score is below recommended range for diabetes',
    ];

    return Card(
      color: verdictColor.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(verdictIcon, color: verdictColor.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    verdictText,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: verdictColor.shade800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...reasons.map(
              (reason) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(reason, style: const TextStyle(fontSize: 14)),
              ),
            ),
          ],
        ),
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
