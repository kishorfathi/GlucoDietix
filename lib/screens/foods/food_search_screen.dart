import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/food.dart';
import '../../services/supabase_service.dart';
import '../../providers/meal_provider.dart';
import '../../widgets/loading_indicator.dart';
import 'portion_selection_screen.dart';

/// Food Search Screen
class FoodSearchScreen extends StatefulWidget {
  const FoodSearchScreen({super.key});

  @override
  State<FoodSearchScreen> createState() => _FoodSearchScreenState();
}

class _FoodSearchScreenState extends State<FoodSearchScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _searchController = TextEditingController();

  List<Food> _foods = [];
  List<String> _categories = [];
  String? _selectedCategory;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _searchFoods();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _supabaseService.getCategories();
      if (mounted) {
        setState(() {
          _categories = categories;
        });
      }
    } catch (e) {
      // Ignore error silently
    }
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

      if (mounted) {
        setState(() {
          _foods = foods;
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

  void _addFood(Food food) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PortionSelectionScreen(food: food),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mealProvider = Provider.of<MealProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Foods'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
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
                  value: _selectedCategory,
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
                              final isAdded = mealProvider.mealItems
                                  .any((item) => item.food.id == food.id);

                              return ListTile(
                                title: Text(food.name),
                                subtitle: Text(
                                  '${food.category} • ${food.carbs100g.toStringAsFixed(1)}g carbs per 100g',
                                ),
                                trailing: isAdded
                                    ? const Icon(Icons.check,
                                        color: Colors.green)
                                    : IconButton(
                                        icon: const Icon(Icons.add),
                                        onPressed: () => _addFood(food),
                                      ),
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
