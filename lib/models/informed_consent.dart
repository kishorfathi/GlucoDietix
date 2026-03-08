/// Informed Consent Model - Ethical Research Compliance
class InformedConsent {
  final String id;
  final String userId;
  final DateTime consentDate;
  final bool agreedToParticipate;
  final bool agreedToDataCollection;
  final bool agreedToHealthDataSharing;
  final bool understoodVoluntaryParticipation;
  final bool understoodDataConfidentiality;
  final bool understoodRightToWithdraw;
  final String? signature; // Digital signature or name
  final String? withdrawalDate; // If participant withdraws

  InformedConsent({
    required this.id,
    required this.userId,
    required this.consentDate,
    required this.agreedToParticipate,
    required this.agreedToDataCollection,
    required this.agreedToHealthDataSharing,
    required this.understoodVoluntaryParticipation,
    required this.understoodDataConfidentiality,
    required this.understoodRightToWithdraw,
    this.signature,
    this.withdrawalDate,
  });

  factory InformedConsent.fromJson(Map<String, dynamic> json) {
    return InformedConsent(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      consentDate: DateTime.parse(json['consent_date'] as String),
      agreedToParticipate: json['agreed_to_participate'] as bool,
      agreedToDataCollection: json['agreed_to_data_collection'] as bool,
      agreedToHealthDataSharing: json['agreed_to_health_data_sharing'] as bool,
      understoodVoluntaryParticipation:
          json['understood_voluntary_participation'] as bool,
      understoodDataConfidentiality:
          json['understood_data_confidentiality'] as bool,
      understoodRightToWithdraw: json['understood_right_to_withdraw'] as bool,
      signature: json['signature'] as String?,
      withdrawalDate: json['withdrawal_date'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'consent_date': consentDate.toIso8601String(),
      'agreed_to_participate': agreedToParticipate,
      'agreed_to_data_collection': agreedToDataCollection,
      'agreed_to_health_data_sharing': agreedToHealthDataSharing,
      'understood_voluntary_participation': understoodVoluntaryParticipation,
      'understood_data_confidentiality': understoodDataConfidentiality,
      'understood_right_to_withdraw': understoodRightToWithdraw,
      'signature': signature,
      'withdrawal_date': withdrawalDate,
    };
  }

  /// Check if all required consents are given
  bool get isFullyConsented {
    return agreedToParticipate &&
        agreedToDataCollection &&
        understoodVoluntaryParticipation &&
        understoodDataConfidentiality &&
        understoodRightToWithdraw;
  }

  /// Check if participant has withdrawn
  bool get hasWithdrawn {
    return withdrawalDate != null;
  }

  /// Get consent text for display
  static String getConsentText() {
    return '''
# Research Study Informed Consent

## Study Title
Machine Learning-Based Mobile Application for Personalized Dietary Management of Diabetes in Sri Lanka

## Purpose of the Study
This research evaluates the effectiveness of a mobile application for helping individuals with diabetes make better dietary choices using personalized recommendations based on Sri Lankan foods.

## What You Will Do
1. Use the GlucoDietix mobile application for meal planning and portion control
2. Log your meals and blood glucose readings
3. Complete pre-intervention and post-intervention assessments
4. Optionally provide feedback through questionnaires

## What Data Will Be Collected
- Your health profile (diabetes type, glucose targets, weight, height)
- Meal selections and portion sizes
- Blood glucose readings
- Self-reported dietary adherence scores
- Usability and satisfaction feedback
- Anonymous usage statistics

## Voluntary Participation
Your participation is completely voluntary. You may:
- Choose not to participate without any consequences
- Withdraw from the study at any time
- Skip any questions you're uncomfortable answering
- Request deletion of your data

## Data Confidentiality
- All data will be kept strictly confidential
- Personal information will be anonymized for research analysis
- Data will be stored securely with encryption
- Only aggregated, de-identified data will be published
- Your identity will never be revealed in research reports

## Benefits
- Personalized dietary recommendations for diabetes management
- Better understanding of portion control
- Health tracking tools
- Contributing to diabetes research in Sri Lanka

## Risks
- Minimal risk
- Time commitment for logging meals and completing surveys
- No medical diagnosis or treatment provided (app is educational only)

## Contact Information
If you have questions about this research, please contact:
[Researcher contact information]

## Your Rights
- You have the right to ask questions about this research
- You have the right to withdraw at any time
- You have the right to request your data be deleted
- You have the right to know how your data will be used

By proceeding, you acknowledge that:
✓ You have read and understood this consent form
✓ You voluntarily agree to participate in this research
✓ You consent to the collection and use of your data as described
✓ You understand you can withdraw at any time
✓ You understand your data will be kept confidential
''';
  }
}
