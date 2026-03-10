import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/exercise_recommendation_service.dart';
import '../../services/supabase_service.dart';

/// Exercise Recommendation Screen
/// Provides personalized exercise suggestions based on health and glucose levels
class ExerciseRecommendationScreen extends StatefulWidget {
  const ExerciseRecommendationScreen({super.key});

  @override
  State<ExerciseRecommendationScreen> createState() =>
      _ExerciseRecommendationScreenState();
}

class _ExerciseRecommendationScreenState
    extends State<ExerciseRecommendationScreen> {
  final _exerciseService = ExerciseRecommendationService();
  final _supabaseService = SupabaseService();
  bool _isLoading = true;
  List<ExerciseRecommendation> _recommendations = [];
  double? _currentGlucose;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() => _isLoading = true);

    try {
      final profile =
          Provider.of<UserProfileProvider>(context, listen: false).userProfile;

      if (profile != null) {
        // Get latest glucose reading
        final readings =
            await _supabaseService.getGlucoseReadings(profile.id, limit: 1);
        if (readings.isNotEmpty) {
          _currentGlucose = readings.first.glucoseLevel;
        }

        // Get recommendations
        final recommendations = _exerciseService.getDailyRecommendations(
          profile,
          currentGlucose: _currentGlucose,
        );

        setState(() {
          _recommendations = recommendations;
        });
      }
    } catch (e) {
      debugPrint('Error loading exercise recommendations: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exercise Recommendations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRecommendations,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadRecommendations,
              child: _recommendations.isEmpty
                  ? const Center(
                      child: Text('No recommendations available'),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Current status card
                        _buildStatusCard(),
                        const SizedBox(height: 20),

                        // Section header
                        const Text(
                          '🏃 Today\'s Exercise Plan',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Exercise recommendations
                        ..._recommendations
                            .asMap()
                            .entries
                            .map((entry) => Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildExerciseCard(
                                    entry.value,
                                    entry.key + 1,
                                  ),
                                )),

                        const SizedBox(height: 20),

                        // General tips
                        _buildGeneralTips(),
                      ],
                    ),
            ),
    );
  }

  Widget _buildStatusCard() {
    final profile = Provider.of<UserProfileProvider>(context).userProfile;
    if (profile == null) return const SizedBox.shrink();

    final bmi = (profile.weightKg /
        ((profile.heightCm / 100) * (profile.heightCm / 100)));
    final isSafeToExercise = _currentGlucose == null ||
        (_currentGlucose! >= 70 && _currentGlucose! <= 240);

    return Card(
      color: isSafeToExercise ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isSafeToExercise ? Icons.check_circle : Icons.warning,
                  color: isSafeToExercise ? Colors.green : Colors.orange,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    isSafeToExercise
                        ? 'Safe to Exercise'
                        : 'Exercise with Caution',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusMetric(
                  'BMI',
                  bmi.toStringAsFixed(1),
                ),
                _buildStatusMetric(
                  'Glucose',
                  _currentGlucose?.toStringAsFixed(0) ?? '--',
                ),
                _buildStatusMetric(
                  'Status',
                  isSafeToExercise ? '✅ Good' : '⚠️ Check',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMetric(String label, String value) {
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

  Widget _buildExerciseCard(ExerciseRecommendation exercise, int number) {
    return Card(
      elevation: 2,
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: Color(exercise.getIntensityColor()),
          child: Text(
            '$number',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          exercise.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(exercise.description),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildInfoChip(
                  Icons.schedule,
                  '${exercise.duration} min',
                ),
                _buildInfoChip(
                  Icons.whatshot,
                  '~${exercise.caloriesBurn} cal',
                ),
                _buildInfoChip(
                  Icons.speed,
                  exercise.getIntensityLabel(),
                ),
              ],
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Best time
                if (exercise.bestTime != null) ...[
                  Row(
                    children: [
                      const Icon(Icons.access_time,
                          size: 18, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Best Time: ${exercise.bestTime}',
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Safety note
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.health_and_safety,
                          size: 18, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          exercise.safetyNote,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Benefits
                if (exercise.benefits.isNotEmpty) ...[
                  const Text(
                    '✅ Benefits:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...exercise.benefits.map(
                    (benefit) => Padding(
                      padding: const EdgeInsets.only(left: 16, bottom: 4),
                      child: Text(
                        '• $benefit',
                        style: const TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Instructions
                if (exercise.instructions.isNotEmpty) ...[
                  const Text(
                    '📋 How to Do It:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...exercise.instructions.asMap().entries.map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(left: 16, bottom: 4),
                          child: Text(
                            '${entry.key + 1}. ${entry.value}',
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ),
                      ),
                  const SizedBox(height: 12),
                ],

                // Action button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => _startExercise(exercise),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Start Exercise'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[700]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGeneralTips() {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tips_and_updates, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'General Exercise Tips',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              '• Always check your blood glucose before exercising\n'
              '• Carry fast-acting carbs (glucose tablets, juice) with you\n'
              '• Stay well hydrated - drink water before, during, and after\n'
              '• Wear proper footwear to prevent foot injuries\n'
              '• Start slowly and gradually increase intensity\n'
              '• Stop immediately if you feel dizzy, shaky, or unwell\n'
              '• Wear a medical ID bracelet when exercising\n'
              '• Exercise with a friend when possible for safety',
              style: TextStyle(fontSize: 13, height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  void _startExercise(ExerciseRecommendation exercise) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(exercise.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Duration: ${exercise.duration} minutes'),
            const SizedBox(height: 8),
            Text('Estimated calories: ~${exercise.caloriesBurn} cal'),
            const SizedBox(height: 16),
            const Text(
              'Before you start:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const Text('✓ Have you checked your glucose?'),
            const Text('✓ Do you have fast-acting carbs with you?'),
            const Text('✓ Are you well hydrated?'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Starting ${exercise.title}! Stay safe! 💪'),
                ),
              );
            },
            child: const Text('Start Now'),
          ),
        ],
      ),
    );
  }
}
