import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/informed_consent.dart';
import '../../providers/auth_provider.dart';
import '../../services/supabase_service.dart';

class InformedConsentScreen extends StatefulWidget {
  const InformedConsentScreen({super.key});

  @override
  State<InformedConsentScreen> createState() => _InformedConsentScreenState();
}

class _InformedConsentScreenState extends State<InformedConsentScreen> {
  final SupabaseService _supabaseService = SupabaseService();
  final TextEditingController _signatureController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  InformedConsent? _existingConsent;

  bool _agreedToParticipate = false;
  bool _agreedToDataCollection = false;
  bool _agreedToHealthDataSharing = false;
  bool _understoodVoluntaryParticipation = false;
  bool _understoodDataConfidentiality = false;
  bool _understoodRightToWithdraw = false;

  @override
  void initState() {
    super.initState();
    _loadConsent();
  }

  @override
  void dispose() {
    _signatureController.dispose();
    super.dispose();
  }

  Future<void> _loadConsent() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userId = authProvider.user?.id;
      if (userId == null) return;

      final consent = await _supabaseService.getInformedConsent(userId);
      if (consent != null) {
        _applyConsent(consent);
      }

      if (!mounted) return;
      setState(() {
        _existingConsent = consent;
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyConsent(InformedConsent consent) {
    _agreedToParticipate = consent.agreedToParticipate;
    _agreedToDataCollection = consent.agreedToDataCollection;
    _agreedToHealthDataSharing = consent.agreedToHealthDataSharing;
    _understoodVoluntaryParticipation =
        consent.understoodVoluntaryParticipation;
    _understoodDataConfidentiality = consent.understoodDataConfidentiality;
    _understoodRightToWithdraw = consent.understoodRightToWithdraw;
    _signatureController.text = consent.signature ?? '';
  }

  Future<void> _saveConsent() async {
    if (_isSaving) return;

    if (!_agreedToParticipate ||
        !_agreedToDataCollection ||
        !_understoodVoluntaryParticipation ||
        !_understoodDataConfidentiality ||
        !_understoodRightToWithdraw) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please check all required consent items to proceed.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userId = authProvider.user?.id;
    if (userId == null) return;

    setState(() => _isSaving = true);
    try {
      final consent = InformedConsent(
        id: userId,
        userId: userId,
        consentDate: DateTime.now(),
        agreedToParticipate: _agreedToParticipate,
        agreedToDataCollection: _agreedToDataCollection,
        agreedToHealthDataSharing: _agreedToHealthDataSharing,
        understoodVoluntaryParticipation: _understoodVoluntaryParticipation,
        understoodDataConfidentiality: _understoodDataConfidentiality,
        understoodRightToWithdraw: _understoodRightToWithdraw,
        signature: _signatureController.text.trim().isEmpty
            ? null
            : _signatureController.text.trim(),
        withdrawalDate: null,
      );

      await _supabaseService.upsertInformedConsent(consent);
      if (!mounted) return;
      setState(() {
        _existingConsent = consent;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Consent saved successfully.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save consent: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final consented = _existingConsent?.isFullyConsented == true;
    final withdrawn = _existingConsent?.hasWithdrawn == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Informed Consent'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        InformedConsent.getConsentText(),
                        style: const TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCheckbox(
                    label: 'I agree to participate in the study.',
                    value: _agreedToParticipate,
                    onChanged: (value) {
                      setState(() => _agreedToParticipate = value);
                    },
                  ),
                  _buildCheckbox(
                    label: 'I agree to data collection for research purposes.',
                    value: _agreedToDataCollection,
                    onChanged: (value) {
                      setState(() => _agreedToDataCollection = value);
                    },
                  ),
                  _buildCheckbox(
                    label:
                        'I agree to share health data (glucose, meals, profile).',
                    value: _agreedToHealthDataSharing,
                    onChanged: (value) {
                      setState(() => _agreedToHealthDataSharing = value);
                    },
                  ),
                  _buildCheckbox(
                    label: 'I understand participation is voluntary.',
                    value: _understoodVoluntaryParticipation,
                    onChanged: (value) {
                      setState(() => _understoodVoluntaryParticipation = value);
                    },
                  ),
                  _buildCheckbox(
                    label: 'I understand data confidentiality measures.',
                    value: _understoodDataConfidentiality,
                    onChanged: (value) {
                      setState(() => _understoodDataConfidentiality = value);
                    },
                  ),
                  _buildCheckbox(
                    label: 'I understand I can withdraw at any time.',
                    value: _understoodRightToWithdraw,
                    onChanged: (value) {
                      setState(() => _understoodRightToWithdraw = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _signatureController,
                    decoration: const InputDecoration(
                      labelText: 'Signature (optional)',
                      hintText: 'Type your name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _isSaving ? null : _saveConsent,
                    child: Text(_isSaving ? 'Saving...' : 'Save Consent'),
                  ),
                  if (consented && !withdrawn) ...[
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () async {
                        final authProvider =
                            Provider.of<AuthProvider>(context, listen: false);
                        final userId = authProvider.user?.id;
                        if (userId == null) return;
                        await _supabaseService.withdrawConsent(userId);
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('You have withdrawn from the study.'),
                          ),
                        );
                        _loadConsent();
                      },
                      child: const Text('Withdraw from Study'),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return CheckboxListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      value: value,
      onChanged: (value) => onChanged(value ?? false),
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}
