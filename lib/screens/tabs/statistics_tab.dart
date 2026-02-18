import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';
import '../../services/habit_service.dart';
class StatisticsTab extends StatelessWidget {
  final HabitService habitService;

  const StatisticsTab({super.key, required this.habitService});

  /// Best streak across all habits (including deleted)
  int _bestStreak() {
    final all = habitService.allHabitsIncludingDeleted;
    if (all.isEmpty) return 0;
    return all.map((h) => h.bestStreak).reduce(math.max);
  }

  /// Current streak (highest among all habits including deleted)
  int _currentStreak() {
    final all = habitService.allHabitsIncludingDeleted;
    if (all.isEmpty) return 0;
    return all.map((h) => h.currentStreak).reduce(math.max);
  }

  /// Total completed entries across all habits (including deleted)
  int _totalCompleted() {
    return habitService.allHabitsIncludingDeleted
        .fold(0, (sum, h) => sum + h.completedDates.length);
  }

  /// Monthly completion % for current month using habitsActiveOnDate
  double _monthlyCompletion() {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    int totalScheduled = 0;
    int totalCompleted = 0;

    for (var day = firstDay;
        day.month == now.month && !day.isAfter(now);
        day = day.add(const Duration(days: 1))) {
      final activeHabits = habitService.habitsActiveOnDate(day);
      for (final habit in activeHabits) {
        if (habit.isScheduledFor(day)) {
          totalScheduled++;
          if (habit.isCompletedOn(day)) {
            totalCompleted++;
          }
        }
      }
    }
    if (totalScheduled == 0) return 0;
    return totalCompleted / totalScheduled;
  }

  /// Weekly data: completion % for each day of the current week (Mon-Sun)
  /// Uses habitsActiveOnDate for each day
  List<double> _weeklyData() {
    final now = DateTime.now();
    // Find Monday of this week
    final monday = now.subtract(Duration(days: now.weekday - 1));

    return List.generate(7, (i) {
      final day = monday.add(Duration(days: i));
      if (day.isAfter(now)) return -1; // future day
      int scheduled = 0;
      int completed = 0;
      final activeHabits = habitService.habitsActiveOnDate(day);
      for (final habit in activeHabits) {
        if (habit.isScheduledFor(day)) {
          scheduled++;
          if (habit.isCompletedOn(day)) {
            completed++;
          }
        }
      }
      if (scheduled == 0) return 0;
      return completed / scheduled;
    });
  }

  /// Heatmap data: last 16 weeks (112 days), returns completion level 0-4.
  /// For past days, uses stored snapshots first; falls back to habitsActiveOnDate.
  /// For today, calculates live from current habits.
  List<List<int>> _heatmapData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Find the most recent Sunday
    final endDay = now;
    // Go back 15 weeks + remaining days to start on a Monday
    final startMonday =
        endDay.subtract(Duration(days: endDay.weekday - 1 + 7 * 15));

    List<List<int>> weeks = [];
    var current = startMonday;

    while (current.isBefore(endDay) || _isSameDay(current, endDay)) {
      // Start a new week
      List<int> week = [];
      for (var d = 0; d < 7; d++) {
        final day = current.add(Duration(days: d));
        if (day.isAfter(now)) {
          week.add(-1); // future
        } else if (_isSameDay(day, today)) {
          // Today: calculate live from current active habits
          week.add(_calculateLevelLive(day));
        } else {
          // Past day: try snapshot first, fall back to habitsActiveOnDate
          final snapshot = habitService.getSnapshotForDate(day);
          if (snapshot != null) {
            final percentage = (snapshot['percentage'] as num).toDouble();
            week.add(_percentageToLevel(percentage));
          } else {
            // No snapshot — fall back to calculating from habitsActiveOnDate
            week.add(_calculateLevelFromActiveHabits(day));
          }
        }
      }
      weeks.add(week);
      current = current.add(const Duration(days: 7));
    }
    return weeks;
  }

  /// Convert a percentage (0-100) to a heatmap level (0-4)
  int _percentageToLevel(double percentage) {
    if (percentage <= 0) return 0;
    if (percentage < 25) return 1;
    if (percentage < 50) return 2;
    if (percentage < 100) return 3;
    return 4;
  }

  /// Calculate heatmap level live for a given day (used for today)
  int _calculateLevelLive(DateTime day) {
    int scheduled = 0;
    int completed = 0;
    final activeHabits = habitService.habitsActiveOnDate(day);
    for (final habit in activeHabits) {
      if (habit.isScheduledFor(day)) {
        scheduled++;
        if (habit.isCompletedOn(day)) {
          completed++;
        }
      }
    }
    if (scheduled == 0) return 0;
    final ratio = completed / scheduled;
    if (ratio == 0) return 0;
    if (ratio < 0.25) return 1;
    if (ratio < 0.5) return 2;
    if (ratio < 1.0) return 3;
    return 4;
  }

  /// Calculate heatmap level from habitsActiveOnDate (fallback for past days without snapshot)
  int _calculateLevelFromActiveHabits(DateTime day) {
    int scheduled = 0;
    int completed = 0;
    final activeHabits = habitService.habitsActiveOnDate(day);
    for (final habit in activeHabits) {
      if (habit.isScheduledFor(day)) {
        scheduled++;
        if (habit.isCompletedOn(day)) {
          completed++;
        }
      }
    }
    if (scheduled == 0) return 0;
    final ratio = completed / scheduled;
    if (ratio == 0) return 0;
    if (ratio < 0.25) return 1;
    if (ratio < 0.5) return 2;
    if (ratio < 1.0) return 3;
    return 4;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: habitService,
      builder: (context, _) {
        final currentStreak = _currentStreak();
        final bestStreak = _bestStreak();
        final totalCompleted = _totalCompleted();
        final monthlyPct = _monthlyCompletion();
        final weeklyData = _weeklyData();

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Statistics',
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor(context),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your habit performance overview',
                  style: AppTheme.taglineStyle.copyWith(
                    color: AppTheme.textSecondaryColor(context),
                  ),
                ),
                const SizedBox(height: 24),

                // Stats cards
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Current\nStreak',
                        '$currentStreak',
                        Icons.local_fire_department_rounded,
                        AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Best\nStreak',
                        '$bestStreak',
                        Icons.emoji_events_rounded,
                        const Color(0xFFFFB74D),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Total\nCompleted',
                        '$totalCompleted',
                        Icons.check_circle_rounded,
                        const Color(0xFF00C9A7),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        context,
                        'Monthly\nRate',
                        '${(monthlyPct * 100).toInt()}%',
                        Icons.pie_chart_rounded,
                        const Color(0xFF6C63FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                // Weekly chart
                Text(
                  'This Week',
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                _buildWeeklyChart(context, weeklyData),
                const SizedBox(height: 28),

                // Heatmap
                Text(
                  'Activity Heatmap',
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Last 16 weeks',
                  style: TextStyle(
                    color: AppTheme.textSecondaryColor(context),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 14),
                _buildHeatmap(context),
                const SizedBox(height: 10),
                _buildHeatmapLegend(context),
                const SizedBox(height: 28),

                // Monthly breakdown
                Text(
                  'Monthly Breakdown',
                  style: TextStyle(
                    color: AppTheme.textPrimaryColor(context),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                _buildMonthlyBreakdown(context),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(BuildContext context,
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.cardBorderColor(context),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimaryColor(context),
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondaryColor(context),
              fontSize: 12,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(BuildContext context, List<double> data) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final today = DateTime.now().weekday;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.cardBorderColor(context),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (index) {
          final isToday = index + 1 == today;
          final value = data[index];
          final isFuture = value < 0;
          final barHeight = isFuture ? 0.0 : (value * 80).clamp(0.0, 80.0);
          final pct = isFuture ? '' : '${(value * 100).toInt()}%';

          return Expanded(
            child: Column(
              children: [
                // Percentage label
                SizedBox(
                  height: 18,
                  child: Text(
                    pct,
                    style: TextStyle(
                      color: isToday
                          ? AppTheme.primaryColor
                          : AppTheme.textSecondaryColor(context),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // Bar
                Container(
                  width: 28,
                  height: 80,
                  decoration: BoxDecoration(
                    color: isFuture
                        ? AppTheme.background(context).withValues(alpha: 0.5)
                        : AppTheme.background(context),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.bottomCenter,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutCubic,
                    width: 28,
                    height: barHeight,
                    decoration: BoxDecoration(
                      gradient: isFuture
                          ? null
                          : LinearGradient(
                              colors: [
                                AppTheme.primaryColor,
                                AppTheme.primaryColor.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                      color: isFuture
                          ? AppTheme.textSecondaryColor(context).withValues(alpha: 0.05)
                          : null,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  days[index],
                  style: TextStyle(
                    color:
                        isToday ? AppTheme.primaryColor : AppTheme.textSecondaryColor(context),
                    fontSize: 11,
                    fontWeight: isToday ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildHeatmap(BuildContext context) {
    final weeks = _heatmapData();
    const cellSize = 14.0;
    const cellGap = 3.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.cardBorderColor(context),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day labels + grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day labels
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Column(
                  children: [
                    SizedBox(
                        height: cellSize,
                        child: Text('M',
                            style: TextStyle(
                                color: AppTheme.textSecondaryColor(context), fontSize: 9))),
                    SizedBox(height: cellGap),
                    SizedBox(height: cellSize),
                    SizedBox(height: cellGap),
                    SizedBox(
                        height: cellSize,
                        child: Text('W',
                            style: TextStyle(
                                color: AppTheme.textSecondaryColor(context), fontSize: 9))),
                    SizedBox(height: cellGap),
                    SizedBox(height: cellSize),
                    SizedBox(height: cellGap),
                    SizedBox(
                        height: cellSize,
                        child: Text('F',
                            style: TextStyle(
                                color: AppTheme.textSecondaryColor(context), fontSize: 9))),
                    SizedBox(height: cellGap),
                    SizedBox(height: cellSize),
                    SizedBox(height: cellGap),
                    SizedBox(
                        height: cellSize,
                        child: Text('S',
                            style: TextStyle(
                                color: AppTheme.textSecondaryColor(context), fontSize: 9))),
                  ],
                ),
              ),
              // Grid
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    children: weeks.map((week) {
                      return Padding(
                        padding: const EdgeInsets.only(right: cellGap),
                        child: Column(
                          children: week.map((level) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(bottom: cellGap),
                              child: Container(
                                width: cellSize,
                                height: cellSize,
                                decoration: BoxDecoration(
                                  color: _heatmapColor(context, level),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _heatmapColor(BuildContext context, int level) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (level) {
      case -1:
        return isDark
            ? AppTheme.background(context).withValues(alpha: 0.3)
            : const Color(0xFFE8E8ED);
      case 0:
        return isDark
            ? AppTheme.background(context)
            : const Color(0xFFE0E0E5);
      case 1:
        return const Color(0xFF4CAF50).withValues(alpha: 0.25);
      case 2:
        return const Color(0xFF4CAF50).withValues(alpha: 0.45);
      case 3:
        return const Color(0xFF4CAF50).withValues(alpha: 0.7);
      case 4:
        return const Color(0xFF4CAF50);
      default:
        return isDark
            ? AppTheme.background(context)
            : const Color(0xFFE0E0E5);
    }
  }

  Widget _buildHeatmapLegend(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          'Less',
          style: TextStyle(
            color: AppTheme.textSecondaryColor(context),
            fontSize: 10,
          ),
        ),
        const SizedBox(width: 4),
        for (var i = 0; i <= 4; i++) ...[
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: _heatmapColor(context, i),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
        const SizedBox(width: 4),
        Text(
          'More',
          style: TextStyle(
            color: AppTheme.textSecondaryColor(context),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildMonthlyBreakdown(BuildContext context) {
    final habits = habitService.allHabitsIncludingDeleted;
    if (habits.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.cardBorderColor(context),
          ),
          boxShadow: AppTheme.cardShadow(context),
        ),
        child: Center(
          child: Text(
            'Add habits to see per-habit stats',
            style: TextStyle(
              color: AppTheme.textSecondaryColor(context),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysElapsed = now.day;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.cardBorderColor(context),
        ),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        children: habits.map((habit) {
          int scheduled = 0;
          int completed = 0;
          for (var d = 0; d < daysElapsed; d++) {
            final day = firstDay.add(Duration(days: d));
            if (habit.isScheduledFor(day)) {
              scheduled++;
              if (habit.isCompletedOn(day)) {
                completed++;
              }
            }
          }
          final pct = scheduled == 0 ? 0.0 : completed / scheduled;
          final color = Color(habit.colorValue);
          final isDeleted = habit.isDeleted;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Opacity(
              opacity: isDeleted ? 0.5 : 1.0,
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      IconData(habit.iconCodePoint,
                          fontFamily: 'MaterialIcons'),
                      color: color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                habit.name,
                                style: TextStyle(
                                  color: AppTheme.textPrimaryColor(context),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isDeleted) ...[
                              const SizedBox(width: 6),
                              Text(
                                '(deleted)',
                                style: TextStyle(
                                  color: AppTheme.textSecondaryColor(context),
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 6),
                        // Progress bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: AppTheme.background(context),
                            valueColor: AlwaysStoppedAnimation(color),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${(pct * 100).toInt()}%',
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
