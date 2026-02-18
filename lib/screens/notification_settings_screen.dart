import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/habit_service.dart';
import '../models/habit.dart';

class NotificationSettingsScreen extends StatefulWidget {
  final HabitService habitService;

  const NotificationSettingsScreen({super.key, required this.habitService});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  late bool _globalEnabled;
  late bool _smartReminder;
  late int _smartReminderMinutes;

  @override
  void initState() {
    super.initState();
    _globalEnabled = StorageService.notifications;
    _smartReminder = StorageService.smartReminder;
    _smartReminderMinutes = StorageService.smartReminderMinutes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(
              child: ListenableBuilder(
                listenable: widget.habitService,
                builder: (context, _) {
                  final habits = widget.habitService.habits;
                  final habitsWithReminder =
                      habits.where((h) => h.hasReminder).toList();
                  final habitsWithout =
                      habits.where((h) => !h.hasReminder).toList();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Global toggle
                        _buildGlobalToggle(),
                        const SizedBox(height: 16),

                        // Smart reminder toggle
                        _buildSmartReminderSection(),
                        const SizedBox(height: 24),

                        // Info banner
                        if (!_globalEnabled) ...[
                          _buildDisabledBanner(),
                          const SizedBox(height: 24),
                        ],

                        // Habits with reminders
                        _buildSectionLabel('Active Reminders'),
                        const SizedBox(height: 12),
                        if (habitsWithReminder.isEmpty)
                          _buildEmptyCard(
                              'No habits with reminders set')
                        else
                          ...habitsWithReminder.map((h) =>
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildReminderCard(h, true),
                              )),
                        const SizedBox(height: 24),

                        // Habits without reminders
                        _buildSectionLabel('No Reminder Set'),
                        const SizedBox(height: 12),
                        if (habitsWithout.isEmpty)
                          _buildEmptyCard('All habits have reminders')
                        else
                          ...habitsWithout.map((h) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _buildReminderCard(h, false),
                              )),
                        const SizedBox(height: 24),

                        // Tips
                        _buildSectionLabel('Tips'),
                        const SizedBox(height: 12),
                        _buildTipsCard(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppTheme.textPrimaryColor(context),
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Text(
            'Notifications',
            style: TextStyle(
              color: AppTheme.textPrimaryColor(context),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlobalToggle() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFFFFB74D).withValues(alpha: 0.12),
            AppTheme.surface(context),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFFFB74D).withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFFFB74D).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _globalEnabled
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: const Color(0xFFFFB74D),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Push Notifications',
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _globalEnabled
                      ? 'You will receive habit reminders'
                      : 'All notifications are disabled',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _globalEnabled,
            onChanged: (val) async {
              setState(() => _globalEnabled = val);
              await StorageService.setNotifications(val);
              if (val) {
                await NotificationService.rescheduleAll(
                    widget.habitService.habits);
              } else {
                await NotificationService.cancelAll();
              }
            },
            activeThumbColor: const Color(0xFFFFB74D),
            activeTrackColor:
                const Color(0xFFFFB74D).withValues(alpha: 0.3),
            inactiveThumbColor: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.textSecondaryColor(context)
                : const Color(0xFF999999),
            inactiveTrackColor: Theme.of(context).brightness == Brightness.dark
                ? AppTheme.textSecondaryColor(context).withValues(alpha: 0.15)
                : const Color(0xFFCCCCCC),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartReminderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.cardBorderColor(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.schedule_send_rounded,
                    color: AppTheme.primaryColor, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smart Reminder',
                      style: TextStyle(
                        color: AppTheme.textPrimaryColor(context),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Get a heads-up before your alarm',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _smartReminder,
                onChanged: _globalEnabled
                    ? (val) async {
                        setState(() => _smartReminder = val);
                        await StorageService.setSmartReminder(val);
                        await NotificationService.rescheduleAll(
                            widget.habitService.habits);
                      }
                    : null,
                activeThumbColor: AppTheme.primaryColor,
                activeTrackColor:
                    AppTheme.primaryColor.withValues(alpha: 0.3),
                inactiveThumbColor:
                    Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.textSecondaryColor(context)
                        : const Color(0xFF999999),
                inactiveTrackColor:
                    Theme.of(context).brightness == Brightness.dark
                        ? AppTheme.textSecondaryColor(context)
                            .withValues(alpha: 0.15)
                        : const Color(0xFFCCCCCC),
              ),
            ],
          ),
          if (_smartReminder && _globalEnabled) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Remind me',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 12),
                _buildMinuteChip(5),
                const SizedBox(width: 8),
                _buildMinuteChip(10),
                const Spacer(),
                Text(
                  'before alarm',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor(context),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMinuteChip(int minutes) {
    final isSelected = _smartReminderMinutes == minutes;
    return GestureDetector(
      onTap: () async {
        setState(() => _smartReminderMinutes = minutes);
        await StorageService.setSmartReminderMinutes(minutes);
        await NotificationService.rescheduleAll(widget.habitService.habits);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : AppTheme.background(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.textSecondaryColor(context).withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          '$minutes min',
          style: TextStyle(
            color: isSelected
                ? AppTheme.primaryColor
                : AppTheme.textSecondaryColor(context),
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }

  Widget _buildDisabledBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.accentColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              color: AppTheme.accentColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Enable notifications to receive daily habit reminders at your scheduled times.',
              style: TextStyle(
                color: AppTheme.accentColor.withValues(alpha: 0.8),
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: AppTheme.textSecondaryColor(context),
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildReminderCard(Habit habit, bool hasReminder) {
    final color = Color(habit.colorValue);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.cardBorderColor(context),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              IconData(habit.iconCodePoint, fontFamily: 'MaterialIcons'),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor(context),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  habit.repeatText,
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor(context),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (hasReminder)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.alarm_rounded, color: color, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    habit.reminderText,
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.background(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'No time set',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.cardBorderColor(context),
        ),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.7),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.cardBorderColor(context),
        ),
      ),
      child: Column(
        children: [
          _buildTipRow(
            Icons.lightbulb_outline_rounded,
            'Set reminders at times when you can act on them',
          ),
          const SizedBox(height: 12),
          _buildTipRow(
            Icons.schedule_rounded,
            'Morning reminders help build consistent routines',
          ),
          const SizedBox(height: 12),
          _buildTipRow(
            Icons.trending_up_rounded,
            'Consistent notifications improve habit completion by 40%',
          ),
        ],
      ),
    );
  }

  Widget _buildTipRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            color: const Color(0xFFFFB74D).withValues(alpha: 0.7),
            size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: AppTheme.textSecondaryColor(context),
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
