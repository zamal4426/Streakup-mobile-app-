import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../services/habit_service.dart';
import '../../models/habit.dart';

class CalendarTab extends StatefulWidget {
  final HabitService habitService;

  const CalendarTab({super.key, required this.habitService});

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _selectedDate = DateTime.now();
  late DateTime _focusedMonth;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime(_selectedDate.year, _selectedDate.month);
  }

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get habits active on a given date (includes deleted habits that were active then)
  List<Habit> _habitsForDate(DateTime date) {
    return widget.habitService.habitsActiveOnDate(date)
        .where((h) => h.isScheduledFor(date))
        .toList();
  }

  /// Count completed out of scheduled
  int _completedCount(DateTime date) {
    final key = _dateKey(date);
    return _habitsForDate(date)
        .where((h) => h.completedDates.contains(key))
        .length;
  }

  /// Check if any habit was completed on a date
  bool _hasCompletions(DateTime date) {
    final key = _dateKey(date);
    return widget.habitService.habitsActiveOnDate(date)
        .any((h) => h.completedDates.contains(key));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.habitService,
      builder: (context, _) {
        if (widget.habitService.isLoading) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: AppTheme.primaryColor),
                const SizedBox(height: 16),
                Text(
                  'Loading calendar...',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor(context),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          );
        }

        final scheduled = _habitsForDate(_selectedDate);
        final completedCount = _completedCount(_selectedDate);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Calendar',
                style: TextStyle(
                  color: AppTheme.textPrimaryColor(context),
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Track your daily habit completion',
                style: AppTheme.taglineStyle.copyWith(
                  color: AppTheme.textSecondaryColor(context),
                ),
              ),
              const SizedBox(height: 24),

              // Month navigator
              _buildMonthNavigator(),
              const SizedBox(height: 20),

              // Weekday headers
              _buildWeekdayHeaders(),
              const SizedBox(height: 8),

              // Calendar grid
              _buildCalendarGrid(),
              const SizedBox(height: 20),

              // Selected date details
              _buildDateHeader(completedCount, scheduled.length),
              const SizedBox(height: 12),

              // ALL scheduled habits list with toggle
              Expanded(
                child: scheduled.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: scheduled.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) =>
                            _buildHabitItem(scheduled[index]),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMonthNavigator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Semantics(
          label: 'Previous month',
          button: true,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month - 1,
                );
              });
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorderColor(context)),
                boxShadow: AppTheme.cardShadow(context),
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: AppTheme.textPrimaryColor(context),
                size: 22,
              ),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            setState(() {
              final now = DateTime.now();
              _focusedMonth = DateTime(now.year, now.month);
              _selectedDate = now;
            });
          },
          child: Text(
            _formatMonth(_focusedMonth),
            style: TextStyle(
              color: AppTheme.textPrimaryColor(context),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Semantics(
          label: 'Next month',
          button: true,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _focusedMonth = DateTime(
                  _focusedMonth.year,
                  _focusedMonth.month + 1,
                );
              });
            },
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.surface(context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.cardBorderColor(context)),
                boxShadow: AppTheme.cardShadow(context),
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: AppTheme.textPrimaryColor(context),
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeekdayHeaders() {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      children: days
          .map((d) => Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: TextStyle(
                      color: AppTheme.textSecondaryColor(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDay = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startOffset = firstDay.weekday - 1;
    final totalCells = startOffset + lastDay.day;
    final rows = (totalCells / 7).ceil();

    final today = DateTime.now();

    return Column(
      children: List.generate(rows, (row) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: List.generate(7, (col) {
              final index = row * 7 + col;
              final dayNum = index - startOffset + 1;

              if (dayNum < 1 || dayNum > lastDay.day) {
                return const Expanded(child: SizedBox(height: 44));
              }

              final date = DateTime(
                  _focusedMonth.year, _focusedMonth.month, dayNum);
              final isToday = date.year == today.year &&
                  date.month == today.month &&
                  date.day == today.day;
              final isSelected = date.year == _selectedDate.year &&
                  date.month == _selectedDate.month &&
                  date.day == _selectedDate.day;
              final hasCompleted = _hasCompletions(date);
              final isFuture = date.isAfter(today);

              final scheduled = _habitsForDate(date);
              final dayCompleted = _completedCount(date);
              final completionLabel = scheduled.isEmpty
                  ? 'No habits scheduled'
                  : '$dayCompleted of ${scheduled.length} completed';

              return Expanded(
                child: Semantics(
                  label: '${_formatDate(date)}, ${isToday ? "today, " : ""}$completionLabel${isSelected ? ", selected" : ""}',
                  button: true,
                  child: GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: SizedBox(
                    height: 44,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primaryColor
                                : isToday
                                    ? AppTheme.primaryColor
                                        .withValues(alpha: 0.15)
                                    : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Center(
                            child: Text(
                              '$dayNum',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : isFuture
                                        ? AppTheme.textSecondaryColor(context)
                                            .withValues(alpha: 0.45)
                                        : isToday
                                            ? AppTheme.primaryColor
                                            : AppTheme.textPrimaryColor(context),
                                fontSize: 14,
                                fontWeight: isSelected || isToday
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        // Green dot indicator
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: hasCompleted
                                ? const Color(0xFF4CAF50)
                                : Colors.transparent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _buildDateHeader(int completedCount, int scheduledCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.cardBorderColor(context)),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Row(
        children: [
          Icon(
            Icons.calendar_today_rounded,
            color: AppTheme.primaryColor,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _formatDate(_selectedDate),
              style: TextStyle(
                color: AppTheme.textPrimaryColor(context),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: completedCount > 0
                  ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                  : AppTheme.background(context),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$completedCount / $scheduledCount',
              style: TextStyle(
                color: completedCount > 0
                    ? const Color(0xFF4CAF50)
                    : AppTheme.textSecondaryColor(context),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final isFuture = _selectedDate.isAfter(DateTime.now());
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFuture
                ? Icons.upcoming_rounded
                : Icons.event_busy_rounded,
            size: 48,
            color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.25),
          ),
          const SizedBox(height: 12),
          Text(
            isFuture ? 'Upcoming day' : 'No habits scheduled',
            style: TextStyle(
              color: AppTheme.textSecondaryColor(context),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            isFuture
                ? 'Check back on this day'
                : 'No habits were scheduled for this day',
            style: TextStyle(
              color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHabitItem(Habit habit) {
    final color = Color(habit.colorValue);
    final isCompleted = habit.isCompletedOn(_selectedDate);
    final isSkipped = habit.isSkippedOn(_selectedDate);
    final isFuture = _selectedDate.isAfter(DateTime.now());
    final isDeletedHabit = habit.isDeleted;

    final statusLabel = isCompleted
        ? 'completed'
        : isSkipped
            ? 'skipped'
            : 'not completed';
    return Semantics(
      label: '${habit.name}, ${habit.category}, $statusLabel${isDeletedHabit ? ", deleted habit" : ""}',
      button: !isFuture && !isDeletedHabit,
      child: GestureDetector(
      onTap: isFuture
          ? null
          : () => widget.habitService.toggleHabitOnDate(habit.id, _selectedDate),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isCompleted
              ? color.withValues(alpha: 0.08)
              : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCompleted
                ? color.withValues(alpha: 0.3)
                : AppTheme.cardBorderColor(context),
          ),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isCompleted ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                IconData(habit.iconCodePoint, fontFamily: 'MaterialIcons'),
                color: isCompleted ? color : color.withValues(alpha: 0.6),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: TextStyle(
                      color: isCompleted
                          ? AppTheme.textPrimaryColor(context)
                          : AppTheme.textPrimaryColor(context).withValues(alpha: 0.8),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: AppTheme.textSecondaryColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        habit.category,
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor(context),
                          fontSize: 12,
                        ),
                      ),
                      if (isSkipped) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFB74D).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Skipped',
                            style: TextStyle(
                              color: Color(0xFFFFB74D),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                      if (isDeletedHabit) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Deleted',
                            style: TextStyle(
                              color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.7),
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // Toggle button
            if (!isFuture && !isDeletedHabit)
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF4CAF50)
                      : Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isCompleted
                        ? const Color(0xFF4CAF50)
                        : AppTheme.textSecondaryColor(context).withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: isCompleted
                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 18)
                    : null,
              )
            else if (isDeletedHabit)
              Icon(
                isCompleted ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isCompleted
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.5)
                    : AppTheme.textSecondaryColor(context).withValues(alpha: 0.3),
                size: 24,
              )
            else
              Icon(
                Icons.schedule_rounded,
                color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.4),
                size: 22,
              ),
          ],
        ),
      ),
    ),
    );
  }

  String _formatMonth(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }

  String _formatDate(DateTime date) {
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }
}
