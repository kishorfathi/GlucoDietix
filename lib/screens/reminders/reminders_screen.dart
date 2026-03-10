import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/reminder.dart';
import '../../providers/user_profile_provider.dart';

/// Reminders Screen
/// Manages medication, water intake, and meal reminders
class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  List<Reminder> _reminders = [];
  int _todayWaterIntake = 0; // in ml
  final int _waterGoal = 2000; // 2 liters

  @override
  void initState() {
    super.initState();
    _loadReminders();
  }

  void _loadReminders() {
    final profile =
        Provider.of<UserProfileProvider>(context, listen: false).userProfile;
    if (profile != null) {
      setState(() {
        _reminders = ReminderHelper.getDefaultReminders(profile.id);
        _reminders.sort((a, b) => a.time.compareTo(b.time));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders & Tracking'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Water intake tracker
          _buildWaterIntakeCard(),
          const SizedBox(height: 20),

          // Today's reminders
          _buildSectionHeader('📅 Today\'s Reminders'),
          const SizedBox(height: 12),
          ..._reminders
              .where((r) => r.shouldShowToday())
              .map((reminder) => _buildReminderCard(reminder)),

          const SizedBox(height: 20),

          // Quick actions
          _buildQuickActions(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCustomReminder,
        icon: const Icon(Icons.add),
        label: const Text('Add Reminder'),
      ),
    );
  }

  Widget _buildWaterIntakeCard() {
    final remaining = _waterGoal - _todayWaterIntake;
    final progress = (_todayWaterIntake / _waterGoal).clamp(0.0, 1.0);

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.water_drop, color: Colors.blue[700], size: 28),
                    const SizedBox(width: 12),
                    const Text(
                      'Water Intake Today',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${(_todayWaterIntake / 1000).toStringAsFixed(1)}L',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.blue[100],
              valueColor: AlwaysStoppedAnimation(Colors.blue[700]!),
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 8),
            Text(
              remaining > 0
                  ? '${(remaining / 1000).toStringAsFixed(1)}L remaining to reach your ${(_waterGoal / 1000).toStringAsFixed(1)}L goal'
                  : '🎉 Goal achieved! Keep it up!',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),

            // Quick add water buttons
            Wrap(
              spacing: 8,
              children: [
                _buildWaterButton('Glass\n250ml', 250),
                _buildWaterButton('Bottle\n500ml', 500),
                _buildWaterButton('Large\n750ml', 750),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaterButton(String label, int amountMl) {
    return ElevatedButton(
      onPressed: () => _addWater(amountMl),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[100],
        foregroundColor: Colors.blue[900],
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11),
      ),
    );
  }

  void _addWater(int amountMl) {
    setState(() {
      _todayWaterIntake += amountMl;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('💧 Added ${amountMl}ml water!'),
        duration: const Duration(seconds: 1),
      ),
    );

    // Check if goal reached
    if (_todayWaterIntake >= _waterGoal &&
        _todayWaterIntake - amountMl < _waterGoal) {
      _showGoalReachedDialog();
    }
  }

  void _showGoalReachedDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🎉 Congratulations!'),
        content: const Text(
          'You\'ve reached your daily water intake goal!\n\n'
          'Staying hydrated is important for managing diabetes.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Awesome!'),
          ),
        ],
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

  Widget _buildReminderCard(Reminder reminder) {
    final isCompleted = reminder.isCompletedToday();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Color(reminder.getTypeColor()).withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              reminder.getTypeEmoji(),
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ),
        title: Text(
          reminder.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            decoration: isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (reminder.description != null)
              Text(
                reminder.description!,
                style: const TextStyle(fontSize: 12),
              ),
            const SizedBox(height: 4),
            Text(
              '🕐 ${_formatTime(reminder.time)}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        trailing: Checkbox(
          value: isCompleted,
          onChanged: (value) {
            if (value == true) {
              _markAsCompleted(reminder);
            }
          },
        ),
        onTap: () => _showReminderDetails(reminder),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Card(
      color: Colors.green[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '⚡ Quick Actions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionButton(
                  Icons.medication,
                  'Take Med',
                  () => _quickActionMedication(),
                ),
                _buildQuickActionButton(
                  Icons.restaurant,
                  'Log Meal',
                  () => _quickActionMeal(),
                ),
                _buildQuickActionButton(
                  Icons.bloodtype,
                  'Check Glucose',
                  () => _quickActionGlucose(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.green[700]),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour;
    final minute = time.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$hour12:${minute.toString().padLeft(2, '0')} $period';
  }

  void _markAsCompleted(Reminder reminder) {
    setState(() {
      final index = _reminders.indexWhere((r) => r.id == reminder.id);
      if (index != -1) {
        _reminders[index] = reminder.copyWith(
          lastCompleted: DateTime.now(),
          completionCount: reminder.completionCount + 1,
        );
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ ${reminder.title} completed!'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showReminderDetails(Reminder reminder) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${reminder.getTypeEmoji()} ${reminder.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (reminder.description != null) Text(reminder.description!),
            const SizedBox(height: 12),
            Text('Time: ${_formatTime(reminder.time)}'),
            const SizedBox(height: 8),
            Text('Completed: ${reminder.completionCount} times'),
            if (reminder.lastCompleted != null)
              Text(
                  'Last completed: ${reminder.lastCompleted!.month}/${reminder.lastCompleted!.day}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          if (!reminder.isCompletedToday())
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                _markAsCompleted(reminder);
              },
              child: const Text('Mark as Done'),
            ),
        ],
      ),
    );
  }

  void _addCustomReminder() {
    // TODO: Implement custom reminder creation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Custom reminder feature coming soon!'),
      ),
    );
  }

  void _quickActionMedication() {
    final medReminders = _reminders.where(
      (r) => r.type == ReminderType.medication && !r.isCompletedToday(),
    );

    if (medReminders.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ All medications taken for today!'),
        ),
      );
    } else {
      _markAsCompleted(medReminders.first);
    }
  }

  void _quickActionMeal() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigating to meal builder...'),
      ),
    );
  }

  void _quickActionGlucose() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Navigating to glucose tracking...'),
      ),
    );
  }
}
