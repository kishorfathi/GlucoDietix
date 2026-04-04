import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/research_assessment.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import '../../utils/uuid.dart';

class ResearchAssessmentScreen extends StatefulWidget {
  final String assessmentType;

  const ResearchAssessmentScreen({
    super.key,
    required this.assessmentType,
  });

  @override
  State<ResearchAssessmentScreen> createState() =>
      _ResearchAssessmentScreenState();
}

class _ResearchAssessmentScreenState extends State<ResearchAssessmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final SupabaseService _supabaseService = SupabaseService();

  bool _isSaving = false;

  int _dietaryAdherenceScore = 5;
  int _portionControlScore = 5;
  int _mealSelectionAccuracy = 5;

  int _usabilityScore = 3;
  int _engagementScore = 3;
  int _perceivedUsefulnessScore = 3;
  int _arFeatureUsefulnessScore = 3;

  final _averageGlucoseController = TextEditingController();
  final _weightController = TextEditingController();
  final _hba1cController = TextEditingController();

  final _challengesController = TextEditingController();
  final _suggestionsController = TextEditingController();
  final _commentsController = TextEditingController();

  @override
  void dispose() {
    _averageGlucoseController.dispose();
    _weightController.dispose();
    _hba1cController.dispose();
    _challengesController.dispose();
    _suggestionsController.dispose();
    _commentsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _assessmentTitle(widget.assessmentType);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Text(
                'Quantitative Scores (1 to 10)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildScoreField(
                label: 'Dietary adherence',
                value: _dietaryAdherenceScore,
                max: 10,
                onChanged: (value) {
                  setState(() => _dietaryAdherenceScore = value);
                },
              ),
              _buildScoreField(
                label: 'Portion control',
                value: _portionControlScore,
                max: 10,
                onChanged: (value) {
                  setState(() => _portionControlScore = value);
                },
              ),
              _buildScoreField(
                label: 'Meal selection accuracy',
                value: _mealSelectionAccuracy,
                max: 10,
                onChanged: (value) {
                  setState(() => _mealSelectionAccuracy = value);
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Health Metrics (optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _averageGlucoseController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Average glucose (mg/dL)',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _hba1cController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'HbA1c (%)',
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Experience Ratings (1 to 5)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildScoreField(
                label: 'Usability',
                value: _usabilityScore,
                max: 5,
                onChanged: (value) {
                  setState(() => _usabilityScore = value);
                },
              ),
              _buildScoreField(
                label: 'Engagement',
                value: _engagementScore,
                max: 5,
                onChanged: (value) {
                  setState(() => _engagementScore = value);
                },
              ),
              _buildScoreField(
                label: 'Perceived usefulness',
                value: _perceivedUsefulnessScore,
                max: 5,
                onChanged: (value) {
                  setState(() => _perceivedUsefulnessScore = value);
                },
              ),
              _buildScoreField(
                label: 'AR feature usefulness',
                value: _arFeatureUsefulnessScore,
                max: 5,
                onChanged: (value) {
                  setState(() => _arFeatureUsefulnessScore = value);
                },
              ),
              const SizedBox(height: 16),
              const Text(
                'Open-Ended Feedback (optional)',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _challengesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Challenges faced',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _suggestionsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Suggestions for improvement',
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _commentsController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Additional comments',
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _isSaving ? null : _saveAssessment,
                child: Text(_isSaving ? 'Saving...' : 'Submit Assessment'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreField({
    required String label,
    required int value,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Row(
      children: [
        Expanded(child: Text(label)),
        DropdownButton<int>(
          value: value,
          items: List.generate(
            max,
            (index) => DropdownMenuItem<int>(
              value: index + 1,
              child: Text('${index + 1}'),
            ),
          ),
          onChanged: (value) {
            if (value == null) return;
            onChanged(value);
          },
        ),
      ],
    );
  }

  Future<void> _saveAssessment() async {
    if (_isSaving) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);

    try {
      final assessment = ResearchAssessment(
        id: generateUuidV4(),
        userId: userId,
        assessmentType: widget.assessmentType,
        completedAt: DateTime.now(),
        dietaryAdherenceScore: _dietaryAdherenceScore,
        portionControlScore: _portionControlScore,
        mealSelectionAccuracy: _mealSelectionAccuracy,
        averageGlucose: _parseDouble(_averageGlucoseController.text),
        weight: _parseDouble(_weightController.text),
        hba1c: _parseDouble(_hba1cController.text),
        usabilityScore: _usabilityScore,
        engagementScore: _engagementScore,
        perceivedUsefulnessScore: _perceivedUsefulnessScore,
        arFeatureUsefulnessScore: _arFeatureUsefulnessScore,
        challengesFaced: _emptyToNull(_challengesController.text),
        suggestionsForImprovement: _emptyToNull(_suggestionsController.text),
        additionalComments: _emptyToNull(_commentsController.text),
      );

      await _supabaseService.saveResearchAssessment(assessment);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Assessment submitted successfully.'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit assessment: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  double? _parseDouble(String value) {
    final cleaned = value.trim();
    if (cleaned.isEmpty) return null;
    return double.tryParse(cleaned);
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _assessmentTitle(String type) {
    switch (type) {
      case 'pre_intervention':
        return 'Pre-Intervention Assessment';
      case 'post_intervention':
        return 'Post-Intervention Assessment';
      case 'weekly_followup':
        return 'Weekly Follow-up';
      default:
        return 'Assessment';
    }
  }
}
