import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../meal/meal_builder_screen.dart';
import '../../widgets/loading_indicator.dart';

/// Profile Screen
class ProfileScreen extends StatefulWidget {
  final bool forceInitialSetup;

  const ProfileScreen({super.key, this.forceInitialSetup = false});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const double _fixedTargetMin = 75;
  static const double _fixedTargetMax = 115;

  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _minController = TextEditingController(
    text: _fixedTargetMin.toStringAsFixed(0),
  );
  final _maxController = TextEditingController(
    text: _fixedTargetMax.toStringAsFixed(0),
  );
  final _weightController = TextEditingController(text: '70');
  final _heightController = TextEditingController(text: '170');

  bool _diabetes = false;
  String _glucoseRange = 'normal';
  bool _cholesterolConcern = false;
  String _glucoseUnit = 'mg/dL';
  String _diabetesType = 'Type 2';
  String _treatment = 'Diet';
  String _updateFrequency = 'weekly';
  String _dietaryPreference = 'none';
  bool _lowGIPreference = false;
  bool _lowSodiumPreference = false;

  bool _isSaving = false;
  bool _hasExistingProfile = false;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _usernameController.dispose();
    _minController.dispose();
    _maxController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);

    if (authProvider.user == null) return;
    final userId = authProvider.user!.id;

    if (!profileProvider.isLoadedFor(userId)) {
      await profileProvider.loadUserProfile(userId);
    }

    final profile = profileProvider.userProfile;
    if (profile == null || profile.id != userId || !mounted) return;

    _applyProfileToForm(profile);
    setState(() {
      _hasExistingProfile = true;
    });
  }

  void _applyProfileToForm(UserProfile profile) {
    _diabetes = profile.diabetes;
    _glucoseRange = profile.glucoseRange;
    _cholesterolConcern = profile.cholesterolConcern;
    _glucoseUnit = profile.glucoseUnit;
    _diabetesType = profile.diabetesType;
    _treatment = profile.treatment;
    _updateFrequency = profile.updateFrequency;
    _dietaryPreference = profile.dietaryPreference;
    _lowGIPreference = profile.lowGIPreference;
    _lowSodiumPreference = profile.lowSodiumPreference;

    _usernameController.text = profile.username ?? '';
    _minController.text = _fixedTargetMin.toStringAsFixed(0);
    _maxController.text = _fixedTargetMax.toStringAsFixed(0);
    _weightController.text = profile.weightKg.toStringAsFixed(1);
    _heightController.text = profile.heightCm.toStringAsFixed(1);
  }

  double? _parsePositive(String value) {
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  void _scheduleAutoSave() {
    if (widget.forceInitialSetup || !_hasExistingProfile) return;
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(const Duration(milliseconds: 900), () {
      _saveProfile(auto: true);
    });
  }

  Future<bool> _saveProfile({bool auto = false}) async {
    if (_isSaving) return false;
    if (!_formKey.currentState!.validate()) return false;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final profileProvider =
        Provider.of<UserProfileProvider>(context, listen: false);

    if (authProvider.user == null) return false;

    final targetMin = _fixedTargetMin;
    final targetMax = _fixedTargetMax;
    final weight = _parsePositive(_weightController.text);
    final height = _parsePositive(_heightController.text);

    if (weight == null || height == null) {
      if (!auto && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter valid positive numbers'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    setState(() {
      _isSaving = true;
    });

    final profile = UserProfile(
      id: authProvider.user!.id,
      username: _usernameController.text.trim().isEmpty
          ? null
          : _usernameController.text.trim(),
      diabetes: _diabetes,
      glucoseRange: _glucoseRange,
      cholesterolConcern: _cholesterolConcern,
      glucoseUnit: _glucoseUnit,
      targetGlucoseMin: targetMin,
      targetGlucoseMax: targetMax,
      weightKg: weight,
      heightCm: height,
      diabetesType: _diabetesType,
      treatment: _treatment,
      updateFrequency: _updateFrequency,
      dietaryPreference: _dietaryPreference,
      lowGIPreference: _lowGIPreference,
      lowSodiumPreference: _lowSodiumPreference,
      lastUpdatedAt: DateTime.now(),
    );

    final success = await profileProvider.saveUserProfile(profile);

    if (!mounted) return false;

    setState(() {
      _isSaving = false;
      if (success) {
        _hasExistingProfile = true;
      }
    });

    if (!success) {
      if (!auto) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              profileProvider.errorMessage ?? 'Failed to save profile',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    if (auto) {
      return true;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.forceInitialSetup
              ? 'Clinical data saved. You can now use the app.'
              : 'Profile saved successfully.',
        ),
        backgroundColor: Colors.green,
      ),
    );

    if (widget.forceInitialSetup) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const MealBuilderScreen(),
        ),
      );
    } else {
      Navigator.pop(context);
    }
    return true;
  }

  String _formatDateTime(DateTime? dateTime) {
    if (dateTime == null) return 'Not updated yet';
    final local = dateTime.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<UserProfileProvider>(context);
    final existingProfile = profileProvider.userProfile;
    final lastUpdatedLabel = _formatDateTime(existingProfile?.lastUpdatedAt);

    final saveLabel = widget.forceInitialSetup ? 'Confirm' : 'Save Changes';
    final title =
        widget.forceInitialSetup ? 'Clinical Data' : 'Clinical Data Profile';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: !widget.forceInitialSetup,
        toolbarHeight: 72,
        title: Text(
          title,
          style: const TextStyle(height: 1.2),
        ),
      ),
      body: profileProvider.isLoading && !_hasExistingProfile
          ? const LoadingIndicator()
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      if (!widget.forceInitialSetup) ...[
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Last Updated: $lastUpdatedLabel',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Update Frequency: ${_updateFrequency == 'weekly' ? 'Weekly' : 'Monthly'}',
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tip: Changes here are auto-saved after edits.',
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                      TextFormField(
                        controller: _usernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username (Optional)',
                          border: OutlineInputBorder(),
                          hintText: 'Enter your display name',
                        ),
                        onChanged: (_) => _scheduleAutoSave(),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _glucoseUnit,
                        decoration: const InputDecoration(
                          labelText: 'Glucose Unit',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'mg/dL', child: Text('mg/dL')),
                          DropdownMenuItem(
                              value: 'mmol/L', child: Text('mmol/L')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _glucoseUnit = value);
                          _scheduleAutoSave();
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _minController,
                              decoration: const InputDecoration(
                                labelText: 'Target Min',
                                border: OutlineInputBorder(),
                                helperText: 'Fixed value',
                              ),
                              readOnly: true,
                              enableInteractiveSelection: false,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _maxController,
                              decoration: const InputDecoration(
                                labelText: 'Target Max',
                                border: OutlineInputBorder(),
                                helperText: 'Fixed value',
                              ),
                              readOnly: true,
                              enableInteractiveSelection: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Weight (kg)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  _parsePositive(value ?? '') == null
                                      ? 'Invalid'
                                      : null,
                              onChanged: (_) => _scheduleAutoSave(),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _heightController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                      decimal: true),
                              decoration: const InputDecoration(
                                labelText: 'Height (cm)',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  _parsePositive(value ?? '') == null
                                      ? 'Invalid'
                                      : null,
                              onChanged: (_) => _scheduleAutoSave(),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _diabetesType,
                        decoration: const InputDecoration(
                          labelText: 'Diabetes Type',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'Type 1', child: Text('Type 1')),
                          DropdownMenuItem(
                              value: 'Type 2', child: Text('Type 2')),
                          DropdownMenuItem(
                              value: 'Prediabetes', child: Text('Prediabetes')),
                          DropdownMenuItem(
                              value: 'Gestational', child: Text('Gestational')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _diabetesType = value);
                          _scheduleAutoSave();
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _treatment,
                        decoration: const InputDecoration(
                          labelText: 'Treatment',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Diet', child: Text('Diet')),
                          DropdownMenuItem(
                            value: 'Oral Medication',
                            child: Text('Oral Medication'),
                          ),
                          DropdownMenuItem(
                              value: 'Insulin', child: Text('Insulin')),
                          DropdownMenuItem(
                            value: 'Diet + Insulin',
                            child: Text('Diet + Insulin'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _treatment = value);
                          _scheduleAutoSave();
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _dietaryPreference,
                        decoration: const InputDecoration(
                          labelText: 'Dietary Preference',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'none', child: Text('No Preference')),
                          DropdownMenuItem(
                              value: 'vegetarian', child: Text('Vegetarian')),
                          DropdownMenuItem(
                              value: 'pescatarian', child: Text('Pescatarian')),
                          DropdownMenuItem(
                              value: 'halal', child: Text('Halal')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _dietaryPreference = value);
                          _scheduleAutoSave();
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: _updateFrequency,
                        decoration: const InputDecoration(
                          labelText: 'Health Update Frequency',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'weekly', child: Text('Weekly')),
                          DropdownMenuItem(
                              value: 'monthly', child: Text('Monthly')),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _updateFrequency = value);
                          _scheduleAutoSave();
                        },
                      ),
                      const SizedBox(height: 12),
                      SwitchListTile(
                        title: const Text('Do you have diabetes?'),
                        value: _diabetes,
                        onChanged: (value) {
                          setState(() => _diabetes = value);
                          _scheduleAutoSave();
                        },
                      ),
                      const SizedBox(height: 8),
                      const Text('Glucose Trend'),
                      RadioGroup<String>(
                        groupValue: _glucoseRange,
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _glucoseRange = value);
                          _scheduleAutoSave();
                        },
                        child: const Column(
                          children: [
                            RadioListTile<String>(
                              title: Text('Low'),
                              value: 'low',
                            ),
                            RadioListTile<String>(
                              title: Text('Normal'),
                              value: 'normal',
                            ),
                            RadioListTile<String>(
                              title: Text('High'),
                              value: 'high',
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Cholesterol Concern'),
                        value: _cholesterolConcern,
                        onChanged: (value) {
                          setState(() => _cholesterolConcern = value);
                          _scheduleAutoSave();
                        },
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : () => _saveProfile(),
                          child: Text(_isSaving ? 'Saving...' : saveLabel),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}
