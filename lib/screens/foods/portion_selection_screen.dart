import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/food.dart';
import '../../models/portion.dart';
import '../../services/supabase_service.dart';
import '../../services/health_recommendation_service.dart';
import '../../providers/meal_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../widgets/loading_indicator.dart';
import '../ar/ar_portion_viewer.dart';

/// Portion Selection Screen
class PortionSelectionScreen extends StatefulWidget {
  final Food food;

  const PortionSelectionScreen({super.key, required this.food});

  @override
  State<PortionSelectionScreen> createState() => _PortionSelectionScreenState();
}

class _PortionSelectionScreenState extends State<PortionSelectionScreen> {
  final SupabaseService _supabaseService = SupabaseService();

  List<Portion> _portions = [];
  Portion? _selectedPortion;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPortions();
  }

  Future<void> _loadPortions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final portions =
          await _supabaseService.getPortionsForFood(widget.food.id);

      if (mounted) {
        setState(() {
          _portions = portions;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _addToMeal() {
    if (_selectedPortion != null) {
      final mealProvider = Provider.of<MealProvider>(context, listen: false);
      mealProvider.addFood(widget.food);
      mealProvider.updateGrams(widget.food.id, _selectedPortion!.grams);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.food.name} added to meal'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a portion'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<UserProfileProvider>(context);
    final healthService = HealthRecommendationService();

    // Get health recommendation for this food
    final foodRecommendation = healthService.getFoodRecommendation(
      widget.food,
      profileProvider.userProfile,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.food.name),
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _errorMessage != null
              ? Center(child: Text('Error: $_errorMessage'))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.food.name,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text('Category: ${widget.food.category}'),
                              const SizedBox(height: 8),
                              const Text('Per 100g:'),
                              Text(
                                  'Carbs: ${widget.food.carbs100g.toStringAsFixed(1)}g'),
                              Text(
                                  'Protein: ${widget.food.protein100g.toStringAsFixed(1)}g'),
                              Text(
                                  'Fat: ${widget.food.fat100g.toStringAsFixed(1)}g'),
                              Text(
                                  'Calories: ${widget.food.energyKcal.toStringAsFixed(0)} kcal'),
                              if (widget.food.glycemicIndex != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  'Glycemic Index: ${widget.food.glycemicIndex!.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    color: widget.food.glycemicIndex! > 70
                                        ? Colors.red
                                        : widget.food.glycemicIndex! < 55
                                            ? Colors.green
                                            : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Health Recommendation Card
                    if (profileProvider.userProfile != null) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Card(
                          color: foodRecommendation.contains('⚠️')
                              ? Colors.orange.shade50
                              : Colors.green.shade50,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  foodRecommendation.contains('⚠️')
                                      ? Icons.warning_amber
                                      : Icons.check_circle,
                                  color: foodRecommendation.contains('⚠️')
                                      ? Colors.orange
                                      : Colors.green,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    foodRecommendation,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Select Portion:',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      child: _portions.isEmpty
                          ? const Center(child: Text('No portions available'))
                          : ListView.builder(
                              itemCount: _portions.length,
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemBuilder: (context, index) {
                                final portion = _portions[index];
                                final isSelected = _selectedPortion == portion;

                                // Calculate nutritional values for this portion
                                final portionCarbs = (widget.food.carbs100g *
                                    portion.grams /
                                    100);
                                final portionCalories =
                                    (widget.food.energyKcal *
                                        portion.grams /
                                        100);

                                return Card(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  elevation: isSelected ? 4 : 1,
                                  color: isSelected
                                      ? Colors.teal.shade50
                                      : Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    side: BorderSide(
                                      color: isSelected
                                          ? Colors.teal
                                          : Colors.grey.shade300,
                                      width: isSelected ? 2 : 1,
                                    ),
                                  ),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(12),
                                    onTap: () {
                                      setState(() {
                                        _selectedPortion = portion;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          // Radio button
                                          Radio<Portion>(
                                            value: portion,
                                            groupValue: _selectedPortion,
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedPortion = value;
                                              });
                                            },
                                            activeColor: Colors.teal,
                                          ),
                                          const SizedBox(width: 12),

                                          // Portion info
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                // Portion label (e.g., "1 cup", "1/2 cup")
                                                Text(
                                                  portion.label,
                                                  style: TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.bold,
                                                    color: isSelected
                                                        ? Colors.teal.shade800
                                                        : Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),

                                                // Grams
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.scale,
                                                      size: 16,
                                                      color:
                                                          Colors.grey.shade600,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${portion.grams.toStringAsFixed(0)}g',
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color: Colors
                                                            .grey.shade700,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 16),

                                                    // Carbs
                                                    Icon(
                                                      Icons.grain,
                                                      size: 16,
                                                      color: Colors
                                                          .orange.shade700,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      '${portionCarbs.toStringAsFixed(1)}g carbs',
                                                      style: TextStyle(
                                                        fontSize: 14,
                                                        color: Colors
                                                            .grey.shade700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 2),

                                                // Calories
                                                Text(
                                                  '${portionCalories.toStringAsFixed(0)} kcal',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),

                                          // Checkmark for selected
                                          if (isSelected)
                                            const Icon(
                                              Icons.check_circle,
                                              color: Colors.teal,
                                              size: 28,
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),

                    // Bottom action buttons - always visible
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, -2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(16.0),
                      child: SafeArea(
                        top: false,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Info message when no portion selected
                            if (_selectedPortion == null)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                margin: const EdgeInsets.only(bottom: 12),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                  border:
                                      Border.all(color: Colors.blue.shade200),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.info_outline,
                                        color: Colors.blue.shade700, size: 20),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Select a portion above to continue',
                                        style: TextStyle(
                                          color: Colors.blue.shade700,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                            // AR Viewer Button - ALWAYS VISIBLE
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _selectedPortion != null
                                    ? () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                ARPortionViewer(
                                              foodName: widget.food.name,
                                              portionGrams:
                                                  _selectedPortion!.grams,
                                            ),
                                          ),
                                        );
                                      }
                                    : null,
                                icon: const Icon(Icons.view_in_ar),
                                label: const Text('View Portion in AR'),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  side: BorderSide(
                                    color: _selectedPortion != null
                                        ? Colors.purple.shade400
                                        : Colors.grey.shade300,
                                    width: 2,
                                  ),
                                  foregroundColor: _selectedPortion != null
                                      ? Colors.purple.shade700
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Add to Meal Button - ALWAYS VISIBLE
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                onPressed: _selectedPortion != null
                                    ? _addToMeal
                                    : null,
                                icon: const Icon(Icons.add_circle),
                                label: const Text('Add to Meal'),
                                style: ElevatedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  backgroundColor: _selectedPortion != null
                                      ? null
                                      : Colors.grey.shade300,
                                  foregroundColor: _selectedPortion != null
                                      ? Colors.white
                                      : Colors.grey.shade500,
                                ),
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
}
