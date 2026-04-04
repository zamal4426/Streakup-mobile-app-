import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import '../services/timer_service.dart';

class HabitDetailScreen extends StatelessWidget {
  final Habit habit;
  final HabitService habitService;
  final VoidCallback onEdit;

  const HabitDetailScreen({
    super.key,
    required this.habit,
    required this.habitService,
    required this.onEdit,
  });

  double _monthCompletion(Habit h) {
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, 1);
    int scheduled = 0;
    int completed = 0;
    for (var day = first;
        day.month == now.month && !day.isAfter(now);
        day = day.add(const Duration(days: 1))) {
      if (h.isScheduledFor(day)) {
        scheduled++;
        if (h.isCompletedOn(day)) {
          completed++;
        }
      }
    }
    if (scheduled == 0) return 0;
    return completed / scheduled;
  }

  static IconData _difficultyIcon(int difficulty) {
    switch (difficulty) {
      case 2: return Icons.local_fire_department_rounded;
      case 3: return Icons.bolt_rounded;
      default: return Icons.eco_rounded;
    }
  }

  static Color _difficultyColor(int difficulty) {
    switch (difficulty) {
      case 2: return const Color(0xFFFFB74D);
      case 3: return const Color(0xFFE94560);
      default: return const Color(0xFF4CAF50);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: habitService,
      builder: (context, _) {
        if (habitService.isLoading) {
          return Scaffold(
            backgroundColor: AppTheme.background(context),
            body: SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: AppTheme.primaryColor),
                    const SizedBox(height: 16),
                    Text(
                      'Loading habit details...',
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor(context),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        // Get the latest version of this habit
        final current = habitService.habits.firstWhere(
          (h) => h.id == habit.id,
          orElse: () => habit,
        );
        final color = Color(current.colorValue);
        final isCompleted = current.isCompletedOn(DateTime.now());
        final isSkipped = current.isSkippedOn(DateTime.now());
        final streak = current.currentStreak;
        final best = current.bestStreak;
        final total = current.completedDates.length;
        final monthPct = _monthCompletion(current);

        return Scaffold(
          backgroundColor: AppTheme.background(context),
          body: SafeArea(
            child: Column(
              children: [
                _buildTopBar(context, color),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Hero card
                        _buildHeroCard(context, current, color, isCompleted, isSkipped),
                        const SizedBox(height: 20),

                        // Quick stats
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                context,
                                Icons.local_fire_department_rounded,
                                '$streak',
                                'Current\nStreak',
                                color,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                Icons.emoji_events_rounded,
                                '$best',
                                'Best\nStreak',
                                const Color(0xFFFFB74D),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _buildStatCard(
                                context,
                                Icons.check_circle_rounded,
                                '$total',
                                'Total\nDone',
                                const Color(0xFF00C9A7),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // Monthly progress
                        _buildMonthlyProgress(context, color, monthPct),
                        const SizedBox(height: 20),

                        // Details section
                        _buildSectionLabel(context, 'Details'),
                        const SizedBox(height: 12),
                        _buildDetailsCard(context, current, color),
                        const SizedBox(height: 20),

                        // Notes section
                        if (current.notes.isNotEmpty) ...[
                          _buildSectionLabel(context, 'Notes'),
                          const SizedBox(height: 12),
                          _buildNotesCard(context, current, color),
                          const SizedBox(height: 20),
                        ],

                        // Completion calendar
                        _buildSectionLabel(context, 'This Month'),
                        const SizedBox(height: 12),
                        _buildMiniCalendar(context, current, color),
                        const SizedBox(height: 20),

                        // Recent activity
                        _buildSectionLabel(context, 'Recent Activity'),
                        const SizedBox(height: 12),
                        _buildRecentActivity(context, current, color),
                        const SizedBox(height: 24),

                        // Start timer button (only for incomplete habits)
                        if (!isCompleted) ...[
                          _buildStartButton(context, current, color),
                          const SizedBox(height: 10),
                        ],

                        // Action buttons
                        _buildToggleButton(context, current, color, isCompleted),
                        if (!isCompleted) ...[
                          const SizedBox(height: 10),
                          _buildSkipFreezeButtons(context, current, color, isSkipped),
                        ],
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(BuildContext context, Color color) {
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
          Expanded(
            child: Text(
              'Habit Details',
              style: TextStyle(
                color: AppTheme.textPrimaryColor(context),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              Navigator.of(context).pop();
              onEdit();
            },
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.edit_rounded, color: color, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context, Habit h, Color color, bool isCompleted, bool isSkipped) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.15),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              IconData(h.iconCodePoint, fontFamily: 'MaterialIcons'),
              color: color,
              size: 36,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            h.name,
            style: TextStyle(
              color: AppTheme.textPrimaryColor(context),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              // Category badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  h.category,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Difficulty badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _difficultyColor(h.difficulty).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _difficultyIcon(h.difficulty),
                      color: _difficultyColor(h.difficulty),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      h.difficultyText,
                      style: TextStyle(
                        color: _difficultyColor(h.difficulty),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSkipped
                      ? AppTheme.textSecondaryColor(context).withValues(alpha: 0.1)
                      : isCompleted
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                          : AppTheme.surface(context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSkipped
                          ? Icons.skip_next_rounded
                          : isCompleted
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                      color: isSkipped
                          ? AppTheme.textSecondaryColor(context)
                          : isCompleted
                              ? const Color(0xFF4CAF50)
                              : AppTheme.textSecondaryColor(context),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSkipped
                          ? 'Skipped'
                          : isCompleted ? 'Done today' : 'Not done',
                      style: TextStyle(
                        color: isSkipped
                            ? AppTheme.textSecondaryColor(context)
                            : isCompleted
                                ? const Color(0xFF4CAF50)
                                : AppTheme.textSecondaryColor(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Tags
          if (h.tags.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 6,
              runSpacing: 4,
              children: h.tags.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tag_rounded,
                          color: color.withValues(alpha: 0.7), size: 11),
                      const SizedBox(width: 3),
                      Text(
                        tag,
                        style: TextStyle(
                          color: color.withValues(alpha: 0.8),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          // Streak freeze count
          if (h.streakFreezes > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF42A5F5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.ac_unit_rounded,
                      color: Color(0xFF42A5F5), size: 14),
                  const SizedBox(width: 4),
                  Text(
                    '${h.streakFreezes} streak freeze${h.streakFreezes == 1 ? '' : 's'} left',
                    style: const TextStyle(
                      color: Color(0xFF42A5F5),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatCard(
      BuildContext context, IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.cardBorderColor(context),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimaryColor(context),
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondaryColor(context),
              fontSize: 11,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyProgress(BuildContext context, Color color, double pct) {
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Monthly Progress',
                style: TextStyle(
                  color: AppTheme.textPrimaryColor(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(pct * 100).toInt()}%',
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              backgroundColor: AppTheme.background(context),
              valueColor: AlwaysStoppedAnimation(color),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String text) {
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

  Widget _buildDetailsCard(BuildContext context, Habit h, Color color) {
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
        children: [
          _buildDetailRow(
            context,
            Icons.repeat_rounded,
            'Repeat',
            h.repeatText,
            color,
          ),
          _buildDivider(context),
          _buildDetailRow(
            context,
            Icons.notifications_outlined,
            'Reminder',
            h.reminderText,
            color,
          ),
          _buildDivider(context),
          _buildDetailRow(
            context,
            _difficultyIcon(h.difficulty),
            'Difficulty',
            h.difficultyText,
            _difficultyColor(h.difficulty),
          ),
          _buildDivider(context),
          _buildDetailRow(
            context,
            Icons.calendar_today_rounded,
            'Created',
            _formatDate(h.createdAt),
            color,
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(BuildContext context, Habit h, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.cardBorderColor(context),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.note_alt_outlined, color: color, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              h.notes,
              style: TextStyle(
                color: AppTheme.textPrimaryColor(context),
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondaryColor(context),
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: AppTheme.textPrimaryColor(context),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Divider(
      color: AppTheme.cardBorderColor(context),
      height: 1,
    );
  }

  Widget _buildMiniCalendar(BuildContext context, Habit h, Color color) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final startOffset = firstDay.weekday - 1;
    final totalCells = startOffset + lastDay.day;
    final rows = (totalCells / 7).ceil();

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
        children: [
          // Weekday headers
          Row(
            children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: TextStyle(
                            color: AppTheme.textSecondaryColor(context),
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          // Grid
          ...List.generate(rows, (row) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: List.generate(7, (col) {
                  final index = row * 7 + col;
                  final dayNum = index - startOffset + 1;

                  if (dayNum < 1 || dayNum > lastDay.day) {
                    return const Expanded(child: SizedBox(height: 32));
                  }

                  final date = DateTime(now.year, now.month, dayNum);
                  final isToday = dayNum == now.day;
                  final isDone = h.isCompletedOn(date);
                  final isSkippedDay = h.isSkippedOn(date);
                  final isScheduled = h.isScheduledFor(date);
                  final isFuture = date.isAfter(now);

                  return Expanded(
                    child: Container(
                      height: 32,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: isDone
                            ? color.withValues(alpha: 0.2)
                            : isSkippedDay
                                ? AppTheme.textSecondaryColor(context).withValues(alpha: 0.08)
                                : isToday
                                    ? AppTheme.background(context)
                                    : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: isToday
                            ? Border.all(
                                color: color.withValues(alpha: 0.5), width: 1)
                            : null,
                      ),
                      child: Center(
                        child: isDone
                            ? Icon(Icons.check_rounded,
                                color: color, size: 16)
                            : isSkippedDay
                                ? Icon(Icons.remove_rounded,
                                    color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.4),
                                    size: 14)
                                : Text(
                                    '$dayNum',
                                    style: TextStyle(
                                      color: isFuture
                                          ? AppTheme.textSecondaryColor(context)
                                              .withValues(alpha: 0.35)
                                          : !isScheduled
                                              ? AppTheme.textSecondaryColor(context)
                                                  .withValues(alpha: 0.45)
                                              : AppTheme.textPrimaryColor(context),
                                      fontSize: 12,
                                      fontWeight: isToday
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                    ),
                                  ),
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentActivity(BuildContext context, Habit h, Color color) {
    if (h.completedDates.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.cardBorderColor(context),
          ),
        ),
        child: Center(
          child: Text(
            'No activity yet',
            style: TextStyle(
              color: AppTheme.textSecondaryColor(context),
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    final sorted = h.completedDates.toList()..sort((a, b) => b.compareTo(a));
    final recent = sorted.take(7).toList();

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
        children: recent.asMap().entries.map((entry) {
          final dateStr = entry.value;
          final date = DateTime.parse(dateStr);
          final isLast = entry.key == recent.length - 1;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.check_rounded,
                          color: color, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _formatFullDate(date),
                        style: TextStyle(
                          color: AppTheme.textPrimaryColor(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Text(
                      _timeAgo(date),
                      style: TextStyle(
                        color: AppTheme.textSecondaryColor(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!isLast)
                Divider(
                  color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.06),
                  height: 1,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStartButton(BuildContext context, Habit h, Color color) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => _TimerDialog(color: color, habitName: h.name),
          );
        },
        icon: const Icon(Icons.play_arrow_rounded, size: 24),
        label: const Text(
          'Start Timer',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildToggleButton(
      BuildContext context, Habit h, Color color, bool isCompleted) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          habitService.toggleHabitToday(h.id);
        },
        icon: Icon(
          isCompleted ? Icons.undo_rounded : Icons.check_rounded,
          size: 22,
        ),
        label: Text(
          isCompleted ? 'Mark as Incomplete' : 'Mark as Complete',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isCompleted ? AppTheme.surface(context) : color,
          foregroundColor: isCompleted ? AppTheme.textSecondaryColor(context) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildSkipFreezeButtons(
      BuildContext context, Habit h, Color color, bool isSkipped) {
    return Row(
      children: [
        // Skip Today button
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () {
                if (isSkipped) {
                  habitService.unskipHabitToday(h.id);
                } else {
                  habitService.skipHabitToday(h.id);
                }
              },
              icon: Icon(
                isSkipped ? Icons.undo_rounded : Icons.skip_next_rounded,
                size: 18,
              ),
              label: Text(
                isSkipped ? 'Unskip' : 'Skip Today',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppTheme.textSecondaryColor(context),
                side: BorderSide(
                  color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.2),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Streak Freeze button
        Expanded(
          child: SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: h.streakFreezes > 0 && !isSkipped
                  ? () {
                      habitService.useStreakFreeze(h.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Streak freeze used! ${h.streakFreezes - 1} remaining',
                          ),
                          backgroundColor: const Color(0xFF42A5F5),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          margin: const EdgeInsets.all(16),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.ac_unit_rounded, size: 18),
              label: Text(
                'Freeze (${h.streakFreezes})',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF42A5F5),
                side: BorderSide(
                  color: h.streakFreezes > 0 && !isSkipped
                      ? const Color(0xFF42A5F5).withValues(alpha: 0.3)
                      : AppTheme.textSecondaryColor(context).withValues(alpha: 0.1),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  String _formatFullDate(DateTime date) {
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

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    final diff = today.difference(d).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    if (diff < 7) return '$diff days ago';
    if (diff < 30) return '${diff ~/ 7}w ago';
    return '${diff ~/ 30}mo ago';
  }
}

// ─── Timer Dialog ───
class _TimerDialog extends StatefulWidget {
  final Color color;
  final String habitName;

  const _TimerDialog({required this.color, required this.habitName});

  @override
  State<_TimerDialog> createState() => _TimerDialogState();
}

class _TimerDialogState extends State<_TimerDialog> {
  final TimerService _timerService = TimerService();
  int _selectedMinutes = 25;
  bool _isCustom = false;
  int _customHours = 0;
  int _customMins = 0;
  final _customController = TextEditingController();
  final _customHoursController = TextEditingController();

  static const _presets = [5, 10, 15, 25, 30, 45, 60, 90, 120];

  @override
  void initState() {
    super.initState();
    // If timer is already running for this habit, sync state
    if (_timerService.hasStarted) {
      _selectedMinutes = _timerService.totalSeconds ~/ 60;
    }
    _timerService.addListener(_onTimerUpdate);
  }

  @override
  void dispose() {
    _timerService.removeListener(_onTimerUpdate);
    _customController.dispose();
    _customHoursController.dispose();
    super.dispose();
  }

  void _onTimerUpdate() {
    if (mounted) setState(() {});
  }

  void _updateCustomTime({int? hours, int? minutes}) {
    if (hours != null) _customHours = hours.clamp(0, 24);
    if (_customHours == 24) {
      _customMins = 0;
      _customController.clear();
    }
    if (minutes != null && _customHours < 24) _customMins = minutes.clamp(0, 59);
    final total = (_customHours * 60 + _customMins).clamp(1, 1440);
    setState(() => _selectedMinutes = total);
  }

  String _formatTime(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String _presetLabel(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      if (m == 0) return '${h}h';
      return '${h}h${m}m';
    }
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final ts = _timerService;
    final hasStarted = ts.hasStarted;
    final isRunning = ts.isRunning;
    final isDone = ts.isDone;
    final progress = ts.progress;
    final remaining = ts.remainingSeconds;

    return Dialog(
      backgroundColor: AppTheme.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.habitName,
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                // Minimize button (when timer is running)
                if (hasStarted && !isDone) ...[
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: widget.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.minimize_rounded,
                        color: widget.color,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                GestureDetector(
                  onTap: () {
                    if (hasStarted && !isDone) {
                      // Just minimize, don't stop
                      Navigator.of(context).pop();
                    } else {
                      ts.reset();
                      Navigator.of(context).pop();
                    }
                  },
                  child: Icon(
                    Icons.close_rounded,
                    color: AppTheme.textSecondaryColor(context),
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Timer circle
            SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                painter: _TimerRingPainter(
                  progress: progress,
                  color: isDone ? const Color(0xFF4CAF50) : widget.color,
                  trackColor: AppTheme.cardBorderColor(context),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        hasStarted
                            ? _formatTime(remaining)
                            : _formatTime(_selectedMinutes * 60),
                        style: TextStyle(
                          color: AppTheme.textPrimaryColor(context),
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                      if (isDone)
                        const Text(
                          'Done!',
                          style: TextStyle(
                            color: Color(0xFF4CAF50),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Presets + Custom (only show when not started)
            if (!hasStarted) ...[
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  ..._presets.map((m) {
                    final isActive = !_isCustom && _selectedMinutes == m;
                    return GestureDetector(
                      onTap: () => setState(() {
                        _isCustom = false;
                        _selectedMinutes = m;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? widget.color.withValues(alpha: 0.15)
                              : AppTheme.background(context),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isActive
                                ? widget.color
                                : AppTheme.cardBorderColor(context),
                          ),
                        ),
                        child: Text(
                          _presetLabel(m),
                          style: TextStyle(
                            color: isActive
                                ? widget.color
                                : AppTheme.textSecondaryColor(context),
                            fontSize: 13,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ),
                    );
                  }),
                  // Custom chip
                  GestureDetector(
                    onTap: () => setState(() => _isCustom = true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _isCustom
                            ? widget.color.withValues(alpha: 0.15)
                            : AppTheme.background(context),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _isCustom
                              ? widget.color
                              : AppTheme.cardBorderColor(context),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.edit_rounded,
                            size: 13,
                            color: _isCustom
                                ? widget.color
                                : AppTheme.textSecondaryColor(context),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Custom',
                            style: TextStyle(
                              color: _isCustom
                                  ? widget.color
                                  : AppTheme.textSecondaryColor(context),
                              fontSize: 13,
                              fontWeight: _isCustom
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Custom input field (hours + minutes)
              if (_isCustom) ...[
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Hours
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: _customHoursController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        autofocus: true,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        style: TextStyle(
                          color: AppTheme.textPrimaryColor(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondaryColor(context)
                                .withValues(alpha: 0.4),
                          ),
                          filled: true,
                          fillColor: AppTheme.background(context),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: AppTheme.cardBorderColor(context)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: widget.color, width: 1.5),
                          ),
                        ),
                        onChanged: (val) {
                          final h = int.tryParse(val) ?? 0;
                          if (h > 24) {
                            _customHoursController.text = '24';
                            _customHoursController.selection = const TextSelection.collapsed(offset: 2);
                          }
                          _updateCustomTime(hours: h);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'h',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Minutes
                    SizedBox(
                      width: 60,
                      child: TextField(
                        controller: _customController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        enabled: _customHours < 24,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(2),
                        ],
                        style: TextStyle(
                          color: _customHours < 24
                              ? AppTheme.textPrimaryColor(context)
                              : AppTheme.textSecondaryColor(context).withValues(alpha: 0.3),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: '0',
                          hintStyle: TextStyle(
                            color: AppTheme.textSecondaryColor(context)
                                .withValues(alpha: 0.4),
                          ),
                          filled: true,
                          fillColor: _customHours < 24
                              ? AppTheme.background(context)
                              : AppTheme.background(context).withValues(alpha: 0.5),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: AppTheme.cardBorderColor(context)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: widget.color, width: 1.5),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                                color: AppTheme.cardBorderColor(context).withValues(alpha: 0.3)),
                          ),
                        ),
                        onChanged: (val) {
                          final m = int.tryParse(val) ?? 0;
                          if (m > 59) {
                            _customController.text = '59';
                            _customController.selection = const TextSelection.collapsed(offset: 2);
                          }
                          _updateCustomTime(minutes: m);
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        'm',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor(context),
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
            ],

            // Action buttons
            Row(
              children: [
                if (hasStarted && !isDone) ...[
                  // Reset
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => ts.reset(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor:
                              AppTheme.textSecondaryColor(context),
                          side: BorderSide(
                            color: AppTheme.cardBorderColor(context),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Reset',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Pause / Resume
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: isRunning ? () => ts.pause() : () => ts.resume(),
                        icon: Icon(
                          isRunning
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 20,
                        ),
                        label: Text(
                          isRunning ? 'Pause' : 'Resume',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ] else if (isDone) ...[
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          ts.reset();
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: const Text('Done',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ] else ...[
                  // Start
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ts.start(_selectedMinutes, widget.habitName, widget.color);
                        },
                        icon: const Icon(Icons.play_arrow_rounded, size: 22),
                        label: const Text(
                          'Start',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: widget.color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),

            // Minimize hint when running
            if (hasStarted && !isDone) ...[
              const SizedBox(height: 12),
              Text(
                'Minimize to continue using the app',
                style: TextStyle(
                  color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.6),
                  fontSize: 11,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimerRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;

  _TimerRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Track
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8,
    );

    if (progress <= 0) return;

    // Progress arc
    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      rect,
      -pi / 2,
      sweepAngle,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _TimerRingPainter old) =>
      old.progress != progress || old.color != color;
}
