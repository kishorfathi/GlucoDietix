import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/informed_consent.dart';
import '../../models/research_assessment.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';
import 'informed_consent_screen.dart';
import 'research_assessment_screen.dart';
import 'research_export_screen.dart';

class ResearchHubScreen extends StatefulWidget {
  const ResearchHubScreen({super.key});

  @override
  State<ResearchHubScreen> createState() => _ResearchHubScreenState();
}

class _ResearchHubScreenState extends State<ResearchHubScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  bool _isLoading = true;
  InformedConsent? _consent;
  Map<String, ResearchAssessment> _latestAssessments = {};

  @override
  void initState() {
    super.initState();
    _loadResearchData();
  }

  Future<void> _loadResearchData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      if (userId == null) return;

      final consent = await _supabaseService.getInformedConsent(userId);
      final assessments = await _supabaseService.getResearchAssessments(userId);

      final latest = <String, ResearchAssessment>{};
      for (final assessment in assessments) {
        if (!latest.containsKey(assessment.assessmentType)) {
          latest[assessment.assessmentType] = assessment;
        }
      }

      if (!mounted) return;
      setState(() {
        _consent = consent;
        _latestAssessments = latest;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Research Tools'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadResearchData,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildConsentCard(),
                  const SizedBox(height: 16),
                  _buildAssessmentCard(),
                  const SizedBox(height: 16),
                  _buildExportCard(),
                ],
              ),
            ),
    );
  }

  Widget _buildConsentCard() {
    final consented = _consent?.isFullyConsented == true;
    final withdrawn = _consent?.hasWithdrawn == true;
    final statusText = withdrawn
        ? 'Withdrawn'
        : consented
            ? 'Consent provided'
            : 'Not provided';

    final consentDate = _consent?.consentDate;
    final subtitle = consentDate == null
        ? statusText
        : '$statusText on ${_formatDate(consentDate)}';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informed Consent',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(subtitle),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const InformedConsentScreen(),
                        ),
                      );
                      _loadResearchData();
                    },
                    child:
                        Text(consented ? 'Review Consent' : 'Review and Sign'),
                  ),
                ),
                if (consented && !withdrawn) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await _confirmWithdraw();
                      },
                      child: const Text('Withdraw'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Assessments',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildAssessmentTile(
              label: 'Pre-Intervention',
              type: 'pre_intervention',
            ),
            _buildAssessmentTile(
              label: 'Weekly Follow-up',
              type: 'weekly_followup',
            ),
            _buildAssessmentTile(
              label: 'Post-Intervention',
              type: 'post_intervention',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssessmentTile({
    required String label,
    required String type,
  }) {
    final latest = _latestAssessments[type];
    final subtitle = latest == null
        ? 'Not completed'
        : 'Last completed on ${_formatDate(latest.completedAt)}';

    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ResearchAssessmentScreen(assessmentType: type),
          ),
        );
        _loadResearchData();
      },
    );
  }

  Widget _buildExportCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Data Export',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Export your research data as CSV or JSON for analysis.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ResearchExportScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.download),
              label: const Text('Open Export Tools'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmWithdraw() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Withdraw from Study'),
        content: const Text(
          'You can withdraw at any time. This will stop future research '
          'logging and mark your consent as withdrawn.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Withdraw'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _supabaseService.withdrawConsent(userId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You have withdrawn from the study.')),
      );
      _loadResearchData();
    }
  }

  String _formatDate(DateTime date) {
    final local = date.toLocal();
    return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }
}
