import '../models/glucose_reading.dart';
import '../models/user_profile.dart';

/// Smart Glucose Alert System
/// Monitors glucose readings and provides alerts with recommended actions
class GlucoseAlertService {
  /// Analyze glucose reading and generate alert if needed
  GlucoseAlert? checkGlucoseLevel(
    double glucoseLevel,
    UserProfile profile, {
    String readingType = 'random',
  }) {
    final minTarget = profile.targetGlucoseMin;
    final maxTarget = profile.targetGlucoseMax;

    // Determine severity and alert type
    if (glucoseLevel < 54) {
      return GlucoseAlert(
        level: glucoseLevel,
        severity: AlertSeverity.critical,
        type: AlertType.hypoglycemia,
        title: '🚨 CRITICAL: Very Low Blood Sugar',
        message:
            'Your glucose is dangerously low at ${glucoseLevel.toStringAsFixed(1)} mg/dL',
        recommendations: [
          '1. Eat 15-20g of fast-acting carbs immediately (glucose tablets, honey, or juice)',
          '2. Recheck glucose in 15 minutes',
          '3. If still low, repeat step 1',
          '4. Seek medical help if symptoms persist',
          '5. Do NOT exercise or drive',
        ],
        urgency: 'IMMEDIATE ACTION REQUIRED',
        color: 0xFFD32F2F, // Dark red
      );
    } else if (glucoseLevel < 70) {
      return GlucoseAlert(
        level: glucoseLevel,
        severity: AlertSeverity.high,
        type: AlertType.hypoglycemia,
        title: '⚠️ WARNING: Low Blood Sugar',
        message:
            'Your glucose is low at ${glucoseLevel.toStringAsFixed(1)} mg/dL',
        recommendations: [
          '1. Consume 15g of fast-acting carbs (4 glucose tablets, 1/2 cup juice)',
          '2. Rest for 15 minutes',
          '3. Recheck your glucose level',
          '4. Have a small snack if next meal is more than 1 hour away',
        ],
        urgency: 'Take action now',
        color: 0xFFF57C00, // Orange
      );
    } else if (glucoseLevel > 250) {
      return GlucoseAlert(
        level: glucoseLevel,
        severity: AlertSeverity.critical,
        type: AlertType.hyperglycemia,
        title: '🚨 CRITICAL: Very High Blood Sugar',
        message:
            'Your glucose is dangerously high at ${glucoseLevel.toStringAsFixed(1)} mg/dL',
        recommendations: [
          '1. Drink plenty of water to stay hydrated',
          '2. Check for ketones if you have Type 1 diabetes',
          '3. Contact your healthcare provider immediately',
          '4. Do NOT exercise if glucose is above 240 mg/dL',
          '5. Review recent meals and medication timing',
        ],
        urgency: 'CONTACT DOCTOR IMMEDIATELY',
        color: 0xFFD32F2F, // Dark red
      );
    } else if (glucoseLevel > 180) {
      return GlucoseAlert(
        level: glucoseLevel,
        severity: AlertSeverity.high,
        type: AlertType.hyperglycemia,
        title: '⚠️ WARNING: High Blood Sugar',
        message:
            'Your glucose is elevated at ${glucoseLevel.toStringAsFixed(1)} mg/dL',
        recommendations: [
          '1. Drink water to help flush excess sugar',
          '2. Consider light physical activity (10-15 min walk)',
          '3. Avoid additional carbohydrates',
          '4. Review what you ate recently',
          '5. Monitor closely over the next few hours',
        ],
        urgency: 'Take preventive action',
        color: 0xFFF57C00, // Orange
      );
    } else if (glucoseLevel < minTarget) {
      return GlucoseAlert(
        level: glucoseLevel,
        severity: AlertSeverity.moderate,
        type: AlertType.belowTarget,
        title: '📊 Below Target Range',
        message:
            'Glucose at ${glucoseLevel.toStringAsFixed(1)} mg/dL is below your target of $minTarget',
        recommendations: [
          '1. Have a small healthy snack',
          '2. Monitor for symptoms of low blood sugar',
          '3. Recheck in 30 minutes if you feel unwell',
        ],
        urgency: 'Monitor closely',
        color: 0xFFFFA726, // Light orange
      );
    } else if (glucoseLevel > maxTarget) {
      return GlucoseAlert(
        level: glucoseLevel,
        severity: AlertSeverity.moderate,
        type: AlertType.aboveTarget,
        title: '📊 Above Target Range',
        message:
            'Glucose at ${glucoseLevel.toStringAsFixed(1)} mg/dL is above your target of $maxTarget',
        recommendations: [
          '1. Take a 10-minute walk',
          '2. Drink a glass of water',
          '3. Avoid snacks until next meal',
          '4. Monitor your levels',
        ],
        urgency: 'Recommended action',
        color: 0xFFFFA726, // Light orange
      );
    }

    // In target range - no alert
    return null;
  }

  /// Get trend analysis from recent readings
  GlucoseTrend analyzeTrend(List<GlucoseReading> recentReadings) {
    if (recentReadings.length < 3) {
      return GlucoseTrend(
        direction: TrendDirection.stable,
        message: 'Not enough data to determine trend',
        recommendation: 'Continue monitoring regularly',
      );
    }

    // Get last 3 readings (most recent first)
    final recent = recentReadings.take(3).toList();
    final levels = recent.map((r) => r.glucoseLevel).toList();

    // Calculate average change
    double totalChange = 0;
    for (int i = 0; i < levels.length - 1; i++) {
      totalChange += levels[i] - levels[i + 1];
    }
    final avgChange = totalChange / (levels.length - 1);

    TrendDirection direction;
    String message;
    String recommendation;

    if (avgChange > 15) {
      direction = TrendDirection.risingFast;
      message = 'Blood sugar rising rapidly (↑↑)';
      recommendation =
          'Avoid carbs, drink water, consider light exercise if safe';
    } else if (avgChange > 5) {
      direction = TrendDirection.rising;
      message = 'Blood sugar trending upward (↑)';
      recommendation = 'Monitor closely, reduce carb intake';
    } else if (avgChange < -15) {
      direction = TrendDirection.fallingFast;
      message = 'Blood sugar dropping rapidly (↓↓)';
      recommendation = 'Have a snack ready, avoid exercise, monitor closely';
    } else if (avgChange < -5) {
      direction = TrendDirection.falling;
      message = 'Blood sugar trending downward (↓)';
      recommendation = 'Be prepared with fast-acting carbs';
    } else {
      direction = TrendDirection.stable;
      message = 'Blood sugar stable (→)';
      recommendation = 'Continue current management plan';
    }

    return GlucoseTrend(
      direction: direction,
      message: message,
      recommendation: recommendation,
      averageChange: avgChange,
    );
  }

  /// Get insights from glucose patterns
  String getPatternInsight(List<GlucoseReading> readings) {
    if (readings.isEmpty) return 'No data available';

    final levels = readings.map((r) => r.glucoseLevel).toList();
    final avg = levels.reduce((a, b) => a + b) / levels.length;
    final highCount = levels.where((l) => l > 180).length;
    final lowCount = levels.where((l) => l < 70).length;

    if (lowCount > readings.length * 0.3) {
      return '⚠️ Frequent low readings detected. Consider adjusting medication or meal timing with your doctor.';
    } else if (highCount > readings.length * 0.3) {
      return '⚠️ Frequent high readings detected. Review diet and medication adherence.';
    } else if (avg > 140) {
      return '📊 Average glucose is elevated. Focus on portion control and regular activity.';
    } else if (avg < 90) {
      return '📊 Average glucose is on the lower side. Ensure regular meals and snacks.';
    } else {
      return '✅ Good glucose control! Keep up with your current management plan.';
    }
  }
}

/// Glucose Alert Model
class GlucoseAlert {
  final double level;
  final AlertSeverity severity;
  final AlertType type;
  final String title;
  final String message;
  final List<String> recommendations;
  final String urgency;
  final int color;

  GlucoseAlert({
    required this.level,
    required this.severity,
    required this.type,
    required this.title,
    required this.message,
    required this.recommendations,
    required this.urgency,
    required this.color,
  });
}

enum AlertSeverity {
  critical, // Requires immediate action
  high, // Requires prompt action
  moderate, // Recommendation only
  info, // Informational
}

enum AlertType {
  hypoglycemia, // Low blood sugar
  hyperglycemia, // High blood sugar
  belowTarget, // Below personal target
  aboveTarget, // Above personal target
}

/// Glucose Trend Analysis
class GlucoseTrend {
  final TrendDirection direction;
  final String message;
  final String recommendation;
  final double? averageChange;

  GlucoseTrend({
    required this.direction,
    required this.message,
    required this.recommendation,
    this.averageChange,
  });
}

enum TrendDirection {
  risingFast,
  rising,
  stable,
  falling,
  fallingFast,
}
