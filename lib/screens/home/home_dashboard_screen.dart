import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/glucose_reading.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/glucose_alert_service.dart';
import '../../services/supabase_service.dart';
import '../recommendations/meal_recommendations_screen.dart';
import '../recommendations/exercise_recommendation_screen.dart';
import '../reminders/reminders_screen.dart';
import '../reports/progress_tracking_screen.dart';
import '../research/research_hub_screen.dart';
import '../scan/scan_plate_screen.dart';
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
  String? _loadedProfileId;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).userProfile;
    if (profile != null && profile.id != _loadedProfileId) {
      _loadedProfileId = profile.id;
      _loadDashboardData();
    }
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final profile =
          Provider.of<UserProfileProvider>(context, listen: false).userProfile;

      if (profile != null) {
        debugPrint('Loading glucose readings for user: ${profile.id}');

        // Load recent glucose readings
        final readings =
            await _supabaseService.getGlucoseReadings(profile.id, limit: 10);

        debugPrint('Loaded ${readings.length} glucose readings');
        for (var reading in readings) {
          debugPrint(
              '  - ${reading.glucoseLevel} mg/dL at ${reading.timestamp}');
        }

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
      } else {
        debugPrint('No user profile found');
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.person),
            onSelected: (value) async {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              } else if (value == 'logout') {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Logout'),
                    content: const Text('Are you sure you want to logout?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context, true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        child: const Text('Logout'),
                      ),
                    ],
                  ),
                );

                if (confirm == true && mounted) {
                  final authProvider =
                      Provider.of<AuthProvider>(context, listen: false);
                  await authProvider.signOut();
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Row(
                  children: [
                    Icon(Icons.person_outline),
                    SizedBox(width: 8),
                    Text('Profile'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome header
                    _buildWelcomeHeader(profile),
                    const SizedBox(height: 12),

                    // Glucose alert (if any)
                    if (_currentAlert != null) ...[
                      _buildGlucoseAlert(_currentAlert!),
                      const SizedBox(height: 10),
                    ],

                    // Core feature: Scan Plate
                    _buildCoreScanPlateCard(),
                    const SizedBox(height: 14),

                    // Glucose readings in horizontal cards
                    if (_recentReadings.isNotEmpty) _buildGlucoseReadingsRow(),

                    const SizedBox(height: 12),

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
                      icon: Icons.view_in_ar,
                      title: 'Scan Plate',
                      description:
                          'Capture your plate and get live portion + nutrition insights',
                      color: Colors.teal,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ScanPlateScreen(),
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
                    const SizedBox(height: 12),
                    _buildFeatureCard(
                      icon: Icons.science,
                      title: 'Research Tools',
                      description:
                          'Consent, assessments, and data export for the study',
                      color: Colors.indigo,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ResearchHubScreen(),
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

    // Extract display name from username/email
    String displayName = 'User';
    if (profile?.username != null && profile!.username!.isNotEmpty) {
      final username = profile.username!;
      // If it's an email, get the part before @
      if (username.contains('@')) {
        displayName = username.split('@').first;
      } else {
        displayName = username;
      }
      // Capitalize first letter
      if (displayName.isNotEmpty) {
        displayName = displayName[0].toUpperCase() + displayName.substring(1);
      }
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
          displayName,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGlucoseAlert(GlucoseAlert alert) {
    const darkBlue = Color(0xFF113B69);
    return Card(
      color: darkBlue,
      elevation: 1,
      child: InkWell(
        onTap: () {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              backgroundColor: darkBlue,
              title: Row(
                children: [
                  const Icon(Icons.warning_rounded, color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      alert.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    alert.message,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Recommended Actions:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...alert.recommendations.map(
                    (rec) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('? ',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.white)),
                          Expanded(
                            child: Text(
                              rec,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Got it',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(
                Icons.warning_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      alert.message,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.white70,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right,
                  size: 18, color: Colors.white70),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlucoseReadingsRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '🩸 Glucose Readings',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: _addGlucoseReading,
                    icon: const Icon(Icons.add, size: 14),
                    label: const Text('Add', style: TextStyle(fontSize: 11)),
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ProgressTrackingScreen(),
                        ),
                      );
                    },
                    child:
                        const Text('View All', style: TextStyle(fontSize: 11)),
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _recentReadings.length > 6 ? 6 : _recentReadings.length,
            itemBuilder: (context, index) {
              final reading = _recentReadings[index];
              final statusColor = _getGlucoseStatusColor(reading.glucoseLevel);
              final isLatest = index == 0;

              return Container(
                width: 135,
                margin: EdgeInsets.only(right: 10, left: index == 0 ? 4 : 0),
                child: Card(
                  elevation: isLatest ? 3 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isLatest
                            ? [
                                const Color(0xFF0B8F87).withOpacity(0.15),
                                const Color(0xFF47BAC1).withOpacity(0.15)
                              ]
                            : [Colors.grey.shade50, Colors.grey.shade100],
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isLatest
                            ? const Color(0xFF0B8F87).withOpacity(0.3)
                            : Colors.grey.shade200,
                        width: 1.5,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text(isLatest
                                ? 'Latest Reading'
                                : 'Reading Details'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${reading.glucoseLevel.toStringAsFixed(1)} mg/dL',
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor),
                                ),
                                const SizedBox(height: 8),
                                Text('Status: ${reading.getStatus()}',
                                    style: TextStyle(color: statusColor)),
                                Text(
                                    'Type: ${_capitalize(reading.readingType.replaceAll('_', ' '))}'),
                                Text(
                                    'Time: ${_formatDateTime(reading.timestamp)}'),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (isLatest)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 6, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF0B8F87),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'New',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                const Spacer(),
                                Icon(Icons.bloodtype,
                                    size: 18, color: statusColor),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  reading.glucoseLevel.toStringAsFixed(0),
                                  style: TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: statusColor,
                                    height: 1,
                                  ),
                                ),
                                Text(
                                  'mg/dL',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    reading.getStatus(),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatDateTime(reading.timestamp),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: _buildQuickActionButton(
            Icons.camera_alt,
            'Scan Plate',
            Colors.teal,
            () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ScanPlateScreen()),
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

  Widget _buildCoreScanPlateCard() {
    const darkBlue = Color(0xFF113B69);
    const deepTeal = Color(0xFF0B8F87);
    return Card(
      elevation: 4,
      shadowColor: darkBlue.withOpacity(0.25),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ScanPlateScreen()),
        ),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                deepTeal.withOpacity(0.18),
                darkBlue.withOpacity(0.18),
              ],
            ),
            border: Border.all(
              color: darkBlue.withOpacity(0.12),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: darkBlue,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: darkBlue.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scan Plate',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF113B69),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tap to scan, view portions, and get instant insights',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: deepTeal,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Start Scan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
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
                  final profile = Provider.of<UserProfileProvider>(
                    context,
                    listen: false,
                  ).userProfile;

                  if (profile != null) {
                    try {
                      debugPrint(
                          'Saving glucose reading: $glucose mg/dL, type: $selectedType');

                      // Create glucose reading
                      final reading = GlucoseReading(
                        id: '${profile.id}_${DateTime.now().millisecondsSinceEpoch}',
                        userId: profile.id,
                        glucoseLevel: glucose,
                        timestamp: DateTime.now(),
                        readingType: selectedType,
                      );

                      debugPrint(
                          'Glucose reading created: ${reading.toJson()}');

                      // Save to database
                      await _supabaseService.saveGlucoseReading(reading);

                      debugPrint(
                          'Glucose reading saved successfully to database');

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Glucose reading saved successfully!'),
                          backgroundColor: Colors.green,
                        ),
                      );

                      // Reload dashboard data
                      debugPrint('Reloading dashboard data...');
                      await _loadDashboardData();
                    } catch (e) {
                      debugPrint('ERROR saving glucose reading: $e');
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error saving reading: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } else {
                    debugPrint(
                        'ERROR: No user profile found when trying to save glucose reading');
                  }
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
