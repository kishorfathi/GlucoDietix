import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../models/dietary_adherence.dart';
import '../../models/glucose_reading.dart';
import '../../models/research_assessment.dart';
import '../../models/user_profile.dart';
import '../../providers/auth_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../services/research_data_export_service.dart';
import '../../services/supabase_service.dart';

class ResearchExportScreen extends StatefulWidget {
  const ResearchExportScreen({super.key});

  @override
  State<ResearchExportScreen> createState() => _ResearchExportScreenState();
}

class _ResearchExportScreenState extends State<ResearchExportScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final ResearchDataExportService _exportService = ResearchDataExportService();

  bool _isLoading = true;
  String _exportTitle = 'Export Output';
  String _exportText = '';

  UserProfile? _profile;
  List<GlucoseReading> _glucoseReadings = [];
  List<ResearchAssessment> _assessments = [];
  List<DietaryAdherenceRecord> _adherenceRecords = [];
  List<WeeklyAdherenceSummary> _weeklySummaries = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      if (userId == null) return;

      _profile =
          Provider.of<UserProfileProvider>(context, listen: false).userProfile;

      final glucose =
          await _supabaseService.getGlucoseReadings(userId, limit: 1000);
      final assessments = await _supabaseService.getResearchAssessments(userId);
      final adherence =
          await _supabaseService.getDietaryAdherenceRecords(userId);

      _weeklySummaries = _buildWeeklySummaries(adherence);

      if (!mounted) return;
      setState(() {
        _glucoseReadings = glucose;
        _assessments = assessments;
        _adherenceRecords = adherence;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Research Export'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildExportButtons(),
                const SizedBox(height: 16),
                _buildOutputPreview(),
              ],
            ),
    );
  }

  Widget _buildExportButtons() {
    final hasData = _glucoseReadings.isNotEmpty ||
        _assessments.isNotEmpty ||
        _adherenceRecords.isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Export Options',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: hasData ? _exportGlucoseCSV : null,
              icon: const Icon(Icons.table_view),
              label: const Text('Glucose CSV'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: hasData ? _exportAssessmentsCSV : null,
              icon: const Icon(Icons.table_chart),
              label: const Text('Assessments CSV'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: hasData ? _exportAdherenceCSV : null,
              icon: const Icon(Icons.table_rows),
              label: const Text('Adherence CSV'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: hasData ? _exportPrePostCSV : null,
              icon: const Icon(Icons.compare),
              label: const Text('Pre/Post Comparison CSV'),
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: hasData ? _exportFullJson : null,
              icon: const Icon(Icons.data_object),
              label: const Text('Full JSON Export'),
            ),
            if (!hasData) ...[
              const SizedBox(height: 8),
              const Text('No data available to export yet.'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOutputPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _exportTitle,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              constraints: const BoxConstraints(minHeight: 120),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: SelectableText(
                _exportText.isEmpty
                    ? 'Choose an export option above to preview and copy data.'
                    : _exportText,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _exportText.isEmpty ? null : _copyToClipboard,
              icon: const Icon(Icons.copy),
              label: const Text('Copy to Clipboard'),
            ),
          ],
        ),
      ),
    );
  }

  void _exportGlucoseCSV() {
    final csv = _exportService.exportGlucoseReadingsToCSV(_glucoseReadings);
    _setExport('Glucose CSV', csv);
  }

  void _exportAssessmentsCSV() {
    final csv = _exportService.exportAssessmentsToCSV(_assessments);
    _setExport('Assessments CSV', csv);
  }

  void _exportAdherenceCSV() {
    final csv = _exportService.exportDietaryAdherenceToCSV(_adherenceRecords);
    _setExport('Adherence CSV', csv);
  }

  void _exportPrePostCSV() {
    final pre = _assessments
        .where((a) => a.assessmentType == 'pre_intervention')
        .toList();
    final post = _assessments
        .where((a) => a.assessmentType == 'post_intervention')
        .toList();
    final csv = _exportService.exportPrePostComparisonToCSV(pre, post);
    _setExport('Pre/Post Comparison CSV', csv);
  }

  void _exportFullJson() {
    final profileList = _profile == null ? <UserProfile>[] : [_profile!];
    final data = _exportService.exportAllDataToJSON(
      participants: profileList,
      glucoseReadings: _glucoseReadings,
      assessments: _assessments,
      adherenceRecords: _adherenceRecords,
      weeklySummaries: _weeklySummaries,
    );
    final jsonText = const JsonEncoder.withIndent('  ').convert(data);
    _setExport('Full JSON Export', jsonText);
  }

  void _setExport(String title, String text) {
    setState(() {
      _exportTitle = title;
      _exportText = text;
    });
  }

  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _exportText));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Export copied to clipboard.')),
    );
  }

  List<WeeklyAdherenceSummary> _buildWeeklySummaries(
    List<DietaryAdherenceRecord> records,
  ) {
    if (records.isEmpty) return [];

    final Map<DateTime, List<DietaryAdherenceRecord>> grouped = {};
    for (final record in records) {
      final date =
          DateTime(record.date.year, record.date.month, record.date.day);
      final weekStart = date.subtract(Duration(days: date.weekday - 1));
      grouped.putIfAbsent(weekStart, () => []).add(record);
    }

    return grouped.entries
        .map(
          (entry) => WeeklyAdherenceSummary.fromRecords(
            entry.value.first.userId,
            entry.key,
            entry.value,
          ),
        )
        .toList();
  }
}
