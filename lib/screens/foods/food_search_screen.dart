import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/food.dart';
import '../../providers/meal_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/food_detection_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/loading_indicator.dart';

class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final FoodDetectionService _portionService = FoodDetectionService();
  final TextEditingController _searchController = TextEditingController();

  List<Food> _foods = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = false;
  String? _errorMessage;

  final Map<String, Food> _selectedFoods = {};
  final Map<String, double> _selectedPortions = {};
  bool _useCupMeasurement = true; // Default to cup/spoon measurements;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchFoods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _portionService.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _supabaseService.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
      });
    } catch (_) {}
  }

  Future<void> _searchFoods() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final foods = await _supabaseService.searchFoods(
        searchQuery: _searchController.text,
        category: _selectedCategory,
      );

      if (!mounted) return;
      setState(() {
        _foods = foods;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _toggleFoodSelection(Food food) {
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).userProfile;

    setState(() {
      if (_selectedFoods.containsKey(food.id)) {
        _selectedFoods.remove(food.id);
        _selectedPortions.remove(food.id);
      } else {
        _selectedFoods[food.id] = food;
        _selectedPortions[food.id] =
            _portionService.getSmartPortionFromProfile(food, profile);
      }
    });
  }

  Future<void> _showPortionEditor() async {
    if (_selectedFoods.isEmpty) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        final theme = Theme.of(context);
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Adjust Portions',
                            style: theme.textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        // Measurement toggle
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primaryContainer,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildMeasurementToggle(
                                icon: Icons.restaurant,
                                label: 'Cup/Spoon',
                                isSelected: _useCupMeasurement,
                                onTap: () {
                                  setSheetState(() {
                                    _useCupMeasurement = true;
                                  });
                                  setState(() {
                                    _useCupMeasurement = true;
                                  });
                                },
                                theme: theme,
                              ),
                              const SizedBox(width: 4),
                              _buildMeasurementToggle(
                                icon: Icons.scale,
                                label: 'Grams',
                                isSelected: !_useCupMeasurement,
                                onTap: () {
                                  setSheetState(() {
                                    _useCupMeasurement = false;
                                  });
                                  setState(() {
                                    _useCupMeasurement = false;
                                  });
                                },
                                theme: theme,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.55,
                      child: ListView(
                        shrinkWrap: true,
                        children: _selectedFoods.values.map((food) {
                          final grams = (_selectedPortions[food.id] ?? 100)
                              .clamp(20.0, 400.0)
                              .toDouble();
                          final cupSpoon = _gramsToCupSpoon(grams, food);

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      food.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Slider(
                                            value: grams,
                                            min: 20,
                                            max: 400,
                                            divisions: 76,
                                            label: _useCupMeasurement
                                                ? cupSpoon
                                                : '${grams.toStringAsFixed(0)} g',
                                            onChanged: (value) {
                                              setSheetState(() {
                                                _selectedPortions[food.id] =
                                                    value;
                                              });
                                              setState(() {
                                                _selectedPortions[food.id] =
                                                    value;
                                              });
                                            },
                                          ),
                                        ),
                                        SizedBox(
                                          width: 90,
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                _useCupMeasurement
                                                    ? cupSpoon
                                                    : '${grams.toStringAsFixed(0)} g',
                                                textAlign: TextAlign.right,
                                                style: theme
                                                    .textTheme.titleSmall
                                                    ?.copyWith(
                                                  fontWeight: FontWeight.bold,
                                                  color:
                                                      theme.colorScheme.primary,
                                                ),
                                              ),
                                              if (_useCupMeasurement)
                                                Text(
                                                  '${grams.toStringAsFixed(0)} g',
                                                  textAlign: TextAlign.right,
                                                  style: theme
                                                      .textTheme.bodySmall
                                                      ?.copyWith(
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _addSelectedFoods();
                        },
                        icon: const Icon(Icons.done_all),
                        label:
                            Text('Add ${_selectedFoods.length} Foods to Meal'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildMeasurementToggle({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSelectedFoods() {
    final mealProvider = Provider.of<MealProvider>(context, listen: false);

    for (final food in _selectedFoods.values) {
      mealProvider.addFood(food);
      mealProvider.updateGrams(food.id, _selectedPortions[food.id] ?? 100);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedFoods.length} food item(s) added to meal'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context);
  }

  // Convert grams to cup/spoon measurement
  String _gramsToCupSpoon(double grams, Food food) {
    final category = food.category.toLowerCase();
    final name = food.name.toLowerCase();

    // Rice and grains
    if (category.contains('rice') ||
        category.contains('grain') ||
        name.contains('rice') ||
        name.contains('bread')) {
      final cups = grams / 150; // 1 cup ≈ 150g cooked rice
      if (cups < 0.25) {
        return '${(grams / 37.5).toStringAsFixed(1)} tbsp';
      } else if (cups < 1) {
        return '${(cups * 4).toStringAsFixed(1)}/4 cup';
      } else {
        return '${cups.toStringAsFixed(1)} cup${cups > 1 ? 's' : ''}';
      }
    }

    // Vegetables
    if (category.contains('vegetable') ||
        category.contains('salad') ||
        name.contains('vegetable') ||
        name.contains('beetroot') ||
        name.contains('carrot')) {
      final cups = grams / 150; // 1 cup ≈ 150g vegetables
      if (cups < 1) {
        return '${(cups * 4).toStringAsFixed(1)}/4 cup';
      } else {
        return '${cups.toStringAsFixed(1)} cup${cups > 1 ? 's' : ''}';
      }
    }

    // Dhal/Lentils (liquid curry)
    if (category.contains('lentil') ||
        category.contains('dhal') ||
        name.contains('dhal') ||
        name.contains('dal') ||
        name.contains('parippu')) {
      final cups = grams / 240; // 1 cup ≈ 240g liquid
      if (cups < 0.25) {
        return '${(grams / 15).toStringAsFixed(0)} tbsp';
      } else if (cups < 1) {
        return '${(cups * 4).toStringAsFixed(1)}/4 cup';
      } else {
        return '${cups.toStringAsFixed(1)} cup${cups > 1 ? 's' : ''}';
      }
    }

    // Protein/Curry (use tablespoons for smaller amounts)
    if (category.contains('meat') ||
        category.contains('fish') ||
        category.contains('curry') ||
        name.contains('curry') ||
        name.contains('chicken') ||
        name.contains('beef') ||
        name.contains('fish')) {
      final tbsp = grams / 15; // 1 tbsp ≈ 15g
      if (tbsp < 4) {
        return '${tbsp.toStringAsFixed(1)} tbsp';
      } else if (tbsp < 16) {
        return '${(tbsp / 4).toStringAsFixed(1)}/4 cup';
      } else {
        return '${(grams / 240).toStringAsFixed(1)} cup';
      }
    }

    // Default: use tablespoons
    final tbsp = grams / 15;
    if (tbsp < 4) {
      return '${tbsp.toStringAsFixed(1)} tbsp';
    } else {
      return '${(grams / 240).toStringAsFixed(1)} cup';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = Provider.of<MealProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Manual Food Selection')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Search food',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: _searchFoods,
                    ),
                  ),
                  onSubmitted: (_) => _searchFoods(),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: _selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category (optional)',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ..._categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category,
                        child: Text(category),
                      );
                    }),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _selectedCategory = value;
                    });
                    _searchFoods();
                  },
                ),
              ],
            ),
          ),
          if (_selectedFoods.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Chip(
                      avatar: const Icon(Icons.checklist, size: 18),
                      label: Text('${_selectedFoods.length} selected'),
                    ),
                    ActionChip(
                      avatar: const Icon(Icons.tune, size: 18),
                      label: const Text('Set portions'),
                      onPressed: _showPortionEditor,
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _isLoading
                ? const LoadingIndicator()
                : _errorMessage != null
                    ? Center(child: Text('Error: $_errorMessage'))
                    : _foods.isEmpty
                        ? const Center(child: Text('No foods found'))
                        : ListView.builder(
                            itemCount: _foods.length,
                            itemBuilder: (context, index) {
                              final food = _foods[index];
                              final isSelected =
                                  _selectedFoods.containsKey(food.id);
                              final alreadyInMeal = mealProvider.mealItems
                                  .any((item) => item.food.id == food.id);

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                child: ListTile(
                                  onTap: () => _toggleFoodSelection(food),
                                  leading: Checkbox(
                                    value: isSelected,
                                    onChanged: (_) =>
                                        _toggleFoodSelection(food),
                                  ),
                                  title: Text(food.name),
                                  subtitle: Text(
                                    '${food.category} | ${food.carbs100g.toStringAsFixed(1)}g carbs /100g',
                                  ),
                                  trailing: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      if (isSelected)
                                        Text(
                                          '${(_selectedPortions[food.id] ?? 100).toStringAsFixed(0)} g',
                                          style: theme.textTheme.labelLarge
                                              ?.copyWith(
                                            color: theme.colorScheme.primary,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      if (alreadyInMeal)
                                        const Icon(Icons.check_circle,
                                            color: Colors.green, size: 18),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
        ],
      ),
      bottomNavigationBar: _selectedFoods.isEmpty
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                child: FilledButton.icon(
                  onPressed: _showPortionEditor,
                  icon: const Icon(Icons.add_chart),
                  label: Text('Review and Add ${_selectedFoods.length} Foods'),
                ),
              ),
            ),
    );
  }
}
