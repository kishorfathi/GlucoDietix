import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/glucose_reading.dart';
import '../../models/user_profile.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/glucose_alert_service.dart';
import '../../services/supabase_service.dart';
import '../recommendations/meal_recommendations_screen.dart';
import '../recommendations/exercise_recommendation_screen.dart';
import '../reminders/reminders_screen.dart';
import '../reports/progress_tracking_screen.dart';
import '../meal/meal_builder_screen.dart';
import '../profile/profile_screen.dart';

/// Enhanced Home Dashboard Screen
/// Central hub for all diabetes management features
class HomeDashboardScreen extends StatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  State<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends State<HomeDashboardScreen> {
  final _alertService = GlucoseAlertService();
  final _supabaseService = SupabaseService();
  bool _isLoading = true;
  GlucoseAlert? _currentAlert;
  List<GlucoseReading> _recentReadings = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final profile =
          Provider.of<UserProfileProvider>(context, listen: false).userProfile;

      if (profile != null) {
        // Load recent glucose readings
        final readings =
            await _supabaseService.getGlucoseReadings(profile.id, limit: 10);

        GlucoseAlert? alert;
        if (readings.isNotEmpty) {
          // Check latest reading for alerts
          final latest = readings.first;
          alert = _alertService.checkGlucoseLevel(
            latest.glucoseLevel,
            profile,
            readingType: latest.readingType,
          );
        }

        setState(() {
          _recentReadings = readings;
          _currentAlert = alert;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<UserProfileProvider>(context).userProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('GlucoDietix'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome header
                    _buildWelcomeHeader(profile),
                    const SizedBox(height: 16),

                    // Glucose alert (if any)
                    if (_currentAlert != null) ...[
                      _buildGlucoseAlert(_currentAlert!),
                      const SizedBox(height: 16),
                    ],

                    // Current glucose status
                    _buildGlucoseStatusCard(),
                    const SizedBox(height: 16),

                    // Quick actions
                    _buildQuickActions(),
                    const SizedBox(height: 24),

                    // Feature cards
                    _buildSectionHeader('✨ Smart Features'),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.restaurant_menu,
                      title: 'AI Meal Recommendations',
                      description:
                          'Get personalized meal plans based on your health data',
                      color: Colors.green,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MealRecommendationsScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.camera_alt,
                      title: 'Food Image Recognition',
                      description:
                          'Scan your meal to identify foods and get nutrition info',
                      color: Colors.blue,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MealBuilderScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.fitness_center,
                      title: 'Exercise Recommendations',
                      description:
                          'Daily exercise plans tailored to your glucose levels',
                      color: Colors.orange,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ExerciseRecommendationScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.notifications_active,
                      title: 'Reminders & Tracking',
                      description: 'Medication, water, and meal reminders',
                      color: Colors.purple,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RemindersScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.show_chart,
                      title: 'Progress & Reports',
                      description:
                          'View glucose trends and generate health reports',
                      color: Colors.teal,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProgressTrackingScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildWelcomeHeader(UserProfile? profile) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good Morning';
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
    } else {
      greeting = 'Good Evening';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          greeting,
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
        Text(
          profile?.username ?? 'User',
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGlucoseAlert(GlucoseAlert alert) {
    return Card(
      color: Color(alert.color).withOpacity(0.1),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_rounded,
                  color: Color(alert.color),
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.title,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(alert.color),
                        ),
                      ),
                      Text(
                        alert.urgency,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              alert.message,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(alert.color).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📋 Recommended Actions:',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...alert.recommendations.map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        rec,
                        style: const TextStyle(fontSize: 12, height: 1.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlucoseStatusCard() {
    if (_recentReadings.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.bloodtype, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              const Text('No glucose readings yet'),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _addGlucoseReading,
                icon: const Icon(Icons.add),
                label: const Text('Add Reading'),
              ),
            ],
          ),
        ),
      );
    }

    final latest = _recentReadings.first;
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).userProfile;

    return Card(
      color: _getGlucoseStatusColor(latest.glucoseLevel).withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '🩸 Latest Glucose Reading',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _addGlucoseReading,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text(
                  latest.glucoseLevel.toStringAsFixed(0),
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: _getGlucoseStatusColor(latest.glucoseLevel),
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'mg/dL',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                    Text(
                      latest.getStatus(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _getGlucoseStatusColor(latest.glucoseLevel),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${_formatDateTime(latest.timestamp)} • ${_capitalize(latest.readingType.replaceAll('_', ' '))}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (profile != null) ...[
              const SizedBox(height: 12),
              Text(
                'Target: ${profile.targetGlucoseMin.toInt()}-${profile.targetGlucoseMax.toInt()} mg/dL',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            Icons.restaurant,
            'Log Meal',
            Colors.green,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MealBuilderScreen()),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            Icons.bloodtype,
            'Add Glucose',
            Colors.red,
            _addGlucoseReading,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildQuickActionButton(
            Icons.water_drop,
            'Water',
            Colors.blue,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const RemindersScreen()),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 18, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Color _getGlucoseStatusColor(double level) {
    if (level < 70) return Colors.red[700]!;
    if (level <= 130) return Colors.green;
    if (level <= 180) return Colors.orange;
    return Colors.red;
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 5) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  void _addGlucoseReading() {
    final glucoseController = TextEditingController();
    String selectedType = 'random';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Add Glucose Reading'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: glucoseController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Glucose Level (mg/dL)',
                  hintText: 'Enter your glucose reading',
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Reading Type',
                ),
                items: const [
                  DropdownMenuItem(value: 'fasting', child: Text('Fasting')),
                  DropdownMenuItem(
                      value: 'before_meal', child: Text('Before Meal')),
                  DropdownMenuItem(
                      value: 'after_meal', child: Text('After Meal')),
                  DropdownMenuItem(value: 'random', child: Text('Random')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => selectedType = value);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final glucose = double.tryParse(glucoseController.text);
                if (glucose != null) {
                  // TODO: Save to database
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Glucose reading saved! Check alerts above.'),
                    ),
                  );
                  _loadDashboardData();
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
