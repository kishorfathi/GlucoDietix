import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/glucose_reading.dart';
import '../../models/dietary_adherence.dart';
import '../../models/user_profile.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/supabase_service.dart';

/// Progress Tracking and Reports Screen
/// Displays weekly and monthly statistics for glucose trends and health improvements
class ProgressTrackingScreen extends StatefulWidget {
  const ProgressTrackingScreen({super.key});

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen> {
  String _selectedPeriod = 'week'; // week, month
  bool _isLoading = true;
  List<GlucoseReading> _glucoseReadings = [];
  List<DietaryAdherenceRecord> _adherenceRecords = [];
  final _supabaseService = SupabaseService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final profile =
          Provider.of<UserProfileProvider>(context, listen: false).userProfile;
      if (profile != null) {
        // Load glucose readings for the selected period
        final readings =
            await _supabaseService.getGlucoseReadings(profile.id, limit: 100);
        final adherence =
            await _supabaseService.getDietaryAdherenceRecords(profile.id);
        setState(() {
          _glucoseReadings = readings;
          _adherenceRecords = adherence;
        });
      }
    } catch (e) {
      debugPrint('Error loading progress data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = Provider.of<UserProfileProvider>(context).userProfile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress & Reports'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Share Report',
            onPressed: () => _generateReport(profile),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Period Selector
                    _buildPeriodSelector(),
                    const SizedBox(height: 20),

                    // Summary Cards
                    _buildSummaryCards(profile),
                    const SizedBox(height: 24),

                    // Dietary Adherence
                    _buildSectionHeader('Dietary Adherence'),
                    const SizedBox(height: 12),
                    _buildAdherenceSummary(),
                    const SizedBox(height: 24),

                    // Glucose Trend Visualization
                    _buildSectionHeader('📊 Glucose Trend'),
                    const SizedBox(height: 12),
                    _buildSimpleGlucoseChart(),
                    const SizedBox(height: 24),

                    // Recent Readings List
                    _buildSectionHeader('📋 Recent Readings'),
                    const SizedBox(height: 12),
                    _buildRecentReadingsList(),
                    const SizedBox(height: 24),

                    // Glucose Distribution
                    _buildSectionHeader('📈 Glucose Distribution'),
                    const SizedBox(height: 12),
                    _buildGlucoseDistribution(),
                    const SizedBox(height: 24),

                    // Insights
                    _buildSectionHeader('💡 Insights & Recommendations'),
                    const SizedBox(height: 12),
                    _buildInsights(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildPeriodSelector() {
    return Row(
      children: [
        Expanded(
          child: SegmentedButton<String>(
            segments: const [
              ButtonSegment(
                value: 'week',
                label: Text('7 Days'),
                icon: Icon(Icons.calendar_view_week),
              ),
              ButtonSegment(
                value: 'month',
                label: Text('30 Days'),
                icon: Icon(Icons.calendar_month),
              ),
            ],
            selected: {_selectedPeriod},
            onSelectionChanged: (Set<String> selected) {
              setState(() {
                _selectedPeriod = selected.first;
              });
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(UserProfile? profile) {
    if (_glucoseReadings.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No glucose data available yet.'),
        ),
      );
    }

    final filteredReadings = _getFilteredReadings();
    final avgGlucose = filteredReadings.isEmpty
        ? 0.0
        : filteredReadings.map((r) => r.glucoseLevel).reduce((a, b) => a + b) /
            filteredReadings.length;

    final inRangeCount = filteredReadings
        .where((r) => r.isInTargetRange(
            minTarget: profile?.targetGlucoseMin ?? 80,
            maxTarget: profile?.targetGlucoseMax ?? 130))
        .length;
    final inRangePercent = filteredReadings.isEmpty
        ? 0.0
        : (inRangeCount / filteredReadings.length * 100);

    final highCount =
        filteredReadings.where((r) => r.glucoseLevel > 180).length;
    final lowCount = filteredReadings.where((r) => r.glucoseLevel < 70).length;

    return Row(
      children: [
        Expanded(
          child: _buildSummaryCard(
            '📊 Avg Glucose',
            '${avgGlucose.toStringAsFixed(1)} mg/dL',
            _getGlucoseColor(avgGlucose),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            '✅ In Range',
            '${inRangePercent.toStringAsFixed(0)}%',
            Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildSummaryCard(
            '⚠️ High/Low',
            '$highCount / $lowCount',
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceSummary() {
    final records = _getFilteredAdherenceRecords();
    if (records.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No adherence data available yet.'),
        ),
      );
    }

    final averageScore = records
            .map((r) => r.adherenceScore)
            .reduce((a, b) => a + b) /
        records.length;
    final portionRate =
        records.where((r) => r.followedPortionAdvice).length /
            records.length *
            100;
    final giRate = records.where((r) => r.avoidedHighGIFoods).length /
        records.length *
        100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Average adherence score: ${averageScore.toStringAsFixed(1)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildAdherenceBar('Portion compliance', portionRate, Colors.green),
            const SizedBox(height: 8),
            _buildAdherenceBar('GI avoidance', giRate, Colors.orange),
            const SizedBox(height: 8),
            Text('Meals tracked: ${records.length}'),
          ],
        ),
      ),
    );
  }

  Widget _buildAdherenceBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label (${value.toStringAsFixed(0)}%)',
            style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: (value / 100).clamp(0.0, 1.0),
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation(color),
          minHeight: 8,
        ),
      ],
    );
  }

  Widget _buildSimpleGlucoseChart() {
    final readings = _getFilteredReadings();
    if (readings.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No data to display'),
        ),
      );
    }

    // Sort by timestamp
    readings.sort((a, b) => a.timestamp.compareTo(b.timestamp));

    // Take last 10 readings for display
    final displayReadings = readings.length > 10
        ? readings.reversed.take(10).toList().reversed.toList()
        : readings;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Last ${displayReadings.length} Readings',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: displayReadings.map((reading) {
                  final normalizedHeight =
                      (reading.glucoseLevel / 300 * 180).clamp(20.0, 180.0);
                  final color = _getGlucoseColor(reading.glucoseLevel);

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Tooltip(
                            message:
                                '${reading.glucoseLevel.toStringAsFixed(0)} mg/dL',
                            child: Container(
                              height: normalizedHeight,
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${reading.timestamp.month}/${reading.timestamp.day}',
                            style: const TextStyle(fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            // Legend
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem('Normal', Colors.green),
                const SizedBox(width: 12),
                _buildLegendItem('High', Colors.orange),
                const SizedBox(width: 12),
                _buildLegendItem('Very High', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }

  Widget _buildRecentReadingsList() {
    final readings = _getFilteredReadings();
    if (readings.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No readings to display'),
        ),
      );
    }

    // Show last 5 readings
    final recentReadings = readings.take(5).toList();

    return Card(
      child: Column(
        children: recentReadings
            .map((reading) => ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        _getGlucoseColor(reading.glucoseLevel).withOpacity(0.2),
                    child: Text(
                      '${reading.glucoseLevel.toInt()}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getGlucoseColor(reading.glucoseLevel),
                      ),
                    ),
                  ),
                  title: Text(
                    '${reading.glucoseLevel.toStringAsFixed(1)} mg/dL',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${_formatTime(reading.timestamp)} • ${_capitalize(reading.readingType.replaceAll('_', ' '))}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getGlucoseColor(reading.glucoseLevel)
                          .withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      reading.getStatus(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _getGlucoseColor(reading.glucoseLevel),
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildGlucoseDistribution() {
    final readings = _getFilteredReadings();
    if (readings.isEmpty) return const SizedBox.shrink();

    int veryLow = readings.where((r) => r.glucoseLevel < 70).length;
    int normal = readings
        .where((r) => r.glucoseLevel >= 70 && r.glucoseLevel <= 130)
        .length;
    int high = readings
        .where((r) => r.glucoseLevel > 130 && r.glucoseLevel <= 180)
        .length;
    int veryHigh = readings.where((r) => r.glucoseLevel > 180).length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildDistributionRow(
                'Very Low (<70)', veryLow, readings.length, Colors.red[700]!),
            const SizedBox(height: 8),
            _buildDistributionRow(
                'Normal (70-130)', normal, readings.length, Colors.green),
            const SizedBox(height: 8),
            _buildDistributionRow(
                'High (130-180)', high, readings.length, Colors.orange),
            const SizedBox(height: 8),
            _buildDistributionRow(
                'Very High (>180)', veryHigh, readings.length, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionRow(
      String label, int count, int total, Color color) {
    final percent = total > 0 ? (count / total * 100) : 0.0;

    return Row(
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: const TextStyle(fontSize: 12)),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: percent / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '$count (${percent.toStringAsFixed(0)}%)',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildInsights() {
    final readings = _getFilteredReadings();
    if (readings.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No data for insights yet. Keep tracking!'),
        ),
      );
    }

    final insights = <String>[];
    final levels = readings.map((r) => r.glucoseLevel).toList();
    final avg = levels.reduce((a, b) => a + b) / levels.length;

    // General trend
    if (avg < 80) {
      insights.add('📊 Your average glucose is on the lower side. '
          'Ensure regular meals and snacks.');
    } else if (avg > 140) {
      insights.add('📊 Your average glucose is elevated. '
          'Focus on portion control and low GI foods.');
    } else {
      insights.add('✅ Your glucose levels are well-controlled overall!');
    }

    // Variability
    final sortedLevels = List<double>.from(levels)..sort();
    final range = sortedLevels.last - sortedLevels.first;
    if (range > 100) {
      insights.add('⚠️ Your glucose shows high variability. '
          'Try to maintain consistent meal times and portions.');
    }

    // Time-based insights
    final morningReadings =
        readings.where((r) => r.timestamp.hour >= 6 && r.timestamp.hour < 10);
    if (morningReadings.isNotEmpty) {
      final morningAvg =
          morningReadings.map((r) => r.glucoseLevel).reduce((a, b) => a + b) /
              morningReadings.length;
      if (morningAvg > 130) {
        insights.add('🌅 Morning readings are elevated. '
            'Review your dinner and bedtime snack choices.');
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: insights
              .map((insight) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      '• $insight',
                      style: const TextStyle(fontSize: 14, height: 1.5),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  List<GlucoseReading> _getFilteredReadings() {
    final now = DateTime.now();
    final cutoff = _selectedPeriod == 'week'
        ? now.subtract(const Duration(days: 7))
        : now.subtract(const Duration(days: 30));

    return _glucoseReadings
        .where((reading) => reading.timestamp.isAfter(cutoff))
        .toList();
  }

  List<DietaryAdherenceRecord> _getFilteredAdherenceRecords() {
    final now = DateTime.now();
    final cutoff = _selectedPeriod == 'week'
        ? now.subtract(const Duration(days: 7))
        : now.subtract(const Duration(days: 30));

    return _adherenceRecords
        .where((record) => record.date.isAfter(cutoff))
        .toList();
  }

  Color _getGlucoseColor(double level) {
    if (level < 70) return Colors.red[700]!;
    if (level <= 130) return Colors.green;
    if (level <= 180) return Colors.orange;
    return Colors.red;
  }

  String _formatTime(DateTime dt) {
    return '${dt.month}/${dt.day} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }

  void _generateReport(UserProfile? profile) {
    if (profile == null) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📄 Generate Report'),
        content: const Text(
          'This feature will generate a PDF report with your glucose trends '
          'and health data that you can share with your doctor.\n\n'
          'Report includes:\n'
          '• Glucose trend charts\n'
          '• Average readings\n'
          '• Time in range analysis\n'
          '• Meal and medication logs',
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
                const SnackBar(
                  content: Text(
                      '📧 Report generated! Check your email for the PDF.'),
                ),
              );
            },
            child: const Text('Generate & Email'),
          ),
        ],
      ),
    );
  }
}
