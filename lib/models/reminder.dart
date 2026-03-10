/// Reminder Model - For medication, water intake, and meal reminders
class Reminder {
  final String id;
  final String userId;
  final ReminderType type;
  final String title;
  final String? description;
  final DateTime time;
  final List<int> repeatDays; // 1=Monday, 7=Sunday
  final bool isActive;
  final DateTime? lastCompleted;
  final int completionCount;
  final DateTime createdAt;

  Reminder({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.description,
    required this.time,
    this.repeatDays = const [1, 2, 3, 4, 5, 6, 7], // Daily by default
    this.isActive = true,
    this.lastCompleted,
    this.completionCount = 0,
    required this.createdAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: ReminderType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReminderType.other,
      ),
      title: json['title'] as String,
      description: json['description'] as String?,
      time: DateTime.parse(json['time'] as String),
      repeatDays: json['repeat_days'] != null
          ? List<int>.from(json['repeat_days'] as List)
          : [1, 2, 3, 4, 5, 6, 7],
      isActive: json['is_active'] as bool? ?? true,
      lastCompleted: json['last_completed'] != null
          ? DateTime.parse(json['last_completed'] as String)
          : null,
      completionCount: json['completion_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.name,
      'title': title,
      'description': description,
      'time': time.toIso8601String(),
      'repeat_days': repeatDays,
      'is_active': isActive,
      'last_completed': lastCompleted?.toIso8601String(),
      'completion_count': completionCount,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Reminder copyWith({
    String? id,
    String? userId,
    ReminderType? type,
    String? title,
    String? description,
    DateTime? time,
    List<int>? repeatDays,
    bool? isActive,
    DateTime? lastCompleted,
    int? completionCount,
    DateTime? createdAt,
  }) {
    return Reminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      time: time ?? this.time,
      repeatDays: repeatDays ?? this.repeatDays,
      isActive: isActive ?? this.isActive,
      lastCompleted: lastCompleted ?? this.lastCompleted,
      completionCount: completionCount ?? this.completionCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String getTypeEmoji() {
    switch (type) {
      case ReminderType.medication:
        return '💊';
      case ReminderType.water:
        return '💧';
      case ReminderType.breakfast:
      case ReminderType.lunch:
      case ReminderType.dinner:
      case ReminderType.snack:
        return '🍽️';
      case ReminderType.exercise:
        return '🏃';
      case ReminderType.glucoseCheck:
        return '🩸';
      case ReminderType.other:
        return '⏰';
    }
  }

  int getTypeColor() {
    switch (type) {
      case ReminderType.medication:
        return 0xFFEF5350; // Red
      case ReminderType.water:
        return 0xFF42A5F5; // Blue
      case ReminderType.breakfast:
      case ReminderType.lunch:
      case ReminderType.dinner:
      case ReminderType.snack:
        return 0xFF66BB6A; // Green
      case ReminderType.exercise:
        return 0xFFFF9800; // Orange
      case ReminderType.glucoseCheck:
        return 0xFFEC407A; // Pink
      case ReminderType.other:
        return 0xFF9E9E9E; // Gray
    }
  }

  bool shouldShowToday() {
    if (!isActive) return false;
    final today = DateTime.now().weekday;
    return repeatDays.contains(today);
  }

  bool isCompletedToday() {
    if (lastCompleted == null) return false;
    final now = DateTime.now();
    return lastCompleted!.year == now.year &&
        lastCompleted!.month == now.month &&
        lastCompleted!.day == now.day;
  }
}

enum ReminderType {
  medication,
  water,
  breakfast,
  lunch,
  dinner,
  snack,
  exercise,
  glucoseCheck,
  other,
}

/// Water Intake Tracking
class WaterIntake {
  final String id;
  final String userId;
  final DateTime timestamp;
  final int amountMl;
  final String? note;

  WaterIntake({
    required this.id,
    required this.userId,
    required this.timestamp,
    required this.amountMl,
    this.note,
  });

  factory WaterIntake.fromJson(Map<String, dynamic> json) {
    return WaterIntake(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      amountMl: json['amount_ml'] as int,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'timestamp': timestamp.toIso8601String(),
      'amount_ml': amountMl,
      'note': note,
    };
  }
}

/// Helper to generate default reminders
class ReminderHelper {
  static List<Reminder> getDefaultReminders(String userId) {
    final now = DateTime.now();

    return [
      // Morning medication
      Reminder(
        id: 'med_morning',
        userId: userId,
        type: ReminderType.medication,
        title: 'Morning Medication',
        description: 'Take your morning diabetes medication',
        time: DateTime(now.year, now.month, now.day, 8, 0),
        createdAt: now,
      ),

      // Evening medication
      Reminder(
        id: 'med_evening',
        userId: userId,
        type: ReminderType.medication,
        title: 'Evening Medication',
        description: 'Take your evening diabetes medication',
        time: DateTime(now.year, now.month, now.day, 20, 0),
        createdAt: now,
      ),

      // Breakfast
      Reminder(
        id: 'meal_breakfast',
        userId: userId,
        type: ReminderType.breakfast,
        title: 'Breakfast Time',
        description: 'Time for a healthy breakfast',
        time: DateTime(now.year, now.month, now.day, 7, 30),
        createdAt: now,
      ),

      // Lunch
      Reminder(
        id: 'meal_lunch',
        userId: userId,
        type: ReminderType.lunch,
        title: 'Lunch Time',
        description: 'Time for lunch',
        time: DateTime(now.year, now.month, now.day, 12, 30),
        createdAt: now,
      ),

      // Dinner
      Reminder(
        id: 'meal_dinner',
        userId: userId,
        type: ReminderType.dinner,
        title: 'Dinner Time',
        description: 'Time for dinner',
        time: DateTime(now.year, now.month, now.day, 19, 0),
        createdAt: now,
      ),

      // Water - Morning
      Reminder(
        id: 'water_morning',
        userId: userId,
        type: ReminderType.water,
        title: 'Morning Hydration',
        description: 'Drink a glass of water',
        time: DateTime(now.year, now.month, now.day, 9, 0),
        createdAt: now,
      ),

      // Water - Afternoon
      Reminder(
        id: 'water_afternoon',
        userId: userId,
        type: ReminderType.water,
        title: 'Afternoon Hydration',
        description: 'Stay hydrated! Drink water',
        time: DateTime(now.year, now.month, now.day, 15, 0),
        createdAt: now,
      ),

      // Water - Evening
      Reminder(
        id: 'water_evening',
        userId: userId,
        type: ReminderType.water,
        title: 'Evening Hydration',
        description: 'Drink water before dinner',
        time: DateTime(now.year, now.month, now.day, 18, 0),
        createdAt: now,
      ),

      // Glucose check - Fasting
      Reminder(
        id: 'glucose_fasting',
        userId: userId,
        type: ReminderType.glucoseCheck,
        title: 'Fasting Glucose Check',
        description: 'Check your fasting blood sugar',
        time: DateTime(now.year, now.month, now.day, 7, 0),
        createdAt: now,
      ),

      // Glucose check - Before bed
      Reminder(
        id: 'glucose_bedtime',
        userId: userId,
        type: ReminderType.glucoseCheck,
        title: 'Bedtime Glucose Check',
        description: 'Check blood sugar before bed',
        time: DateTime(now.year, now.month, now.day, 22, 0),
        createdAt: now,
      ),

      // Exercise
      Reminder(
        id: 'exercise_morning',
        userId: userId,
        type: ReminderType.exercise,
        title: 'Morning Exercise',
        description: 'Time for your daily walk or exercise',
        time: DateTime(now.year, now.month, now.day, 6, 30),
        createdAt: now,
      ),
    ];
  }
}
