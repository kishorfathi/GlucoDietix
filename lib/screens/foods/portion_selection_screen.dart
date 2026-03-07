import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/food.dart';
import '../../models/portion.dart';
import '../../services/supabase_service.dart';
import '../../providers/meal_provider.dart';
import '../../widgets/loading_indicator.dart';

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
                            ],
                          ),
                        ),
                      ),
                    ),
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
                              itemBuilder: (context, index) {
                                final portion = _portions[index];
                                return RadioListTile<Portion>(
                                  title: Text(portion.label),
                                  subtitle: Text(
                                      '${portion.grams.toStringAsFixed(0)}g'),
                                  value: portion,
                                  groupValue: _selectedPortion,
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedPortion = value;
                                    });
                                  },
                                );
                              },
                            ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _addToMeal,
                          child: const Text('Add to Meal'),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
