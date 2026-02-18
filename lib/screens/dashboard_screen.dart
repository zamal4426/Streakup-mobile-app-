import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:alarm/alarm.dart';
import 'package:alarm/utils/alarm_set.dart';
import '../theme/app_theme.dart';
import '../services/habit_service.dart';
import '../services/notification_service.dart';
import '../services/timer_service.dart';
import '../models/habit.dart';
import 'add_habit_screen.dart';
import 'alarm_screen.dart';
import 'habit_detail_screen.dart';
import 'tabs/home_tab.dart';
import 'tabs/calendar_tab.dart';
import 'tabs/statistics_tab.dart';
import 'tabs/profile_tab.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  final HabitService _habitService = HabitService();
  StreamSubscription<AlarmSet>? _alarmSubscription;

  static bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _habitService.load();
    _listenForAlarms();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _alarmSubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // When app returns to foreground, reschedule all alarms.
      // This handles the case where an alarm was dismissed from the
      // native notification while the app was in the background.
      NotificationService.rescheduleAll(_habitService.habits);
    }
  }

  void _listenForAlarms() {
    if (_isDesktop) return;
    _alarmSubscription = Alarm.ringing.listen((alarmSet) {
      if (alarmSet.alarms.isNotEmpty) {
        final alarmSettings = alarmSet.alarms.first;
        _showAlarmScreen(alarmSettings);
      }
    });
  }

  void _showAlarmScreen(AlarmSettings alarmSettings) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) =>
            AlarmScreen(alarmSettings: alarmSettings),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 300),
      ),
    ).then((result) {
      // After alarm is dismissed or snoozed, reschedule all alarms
      // for the next occurrences
      NotificationService.rescheduleAll(_habitService.habits);
    });
  }

  Future<void> _openAddHabit({Habit? editHabit}) async {
    final result = await Navigator.of(context).push<Habit>(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            AddHabitScreen(editHabit: editHabit),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
    if (result != null) {
      if (editHabit != null) {
        await _habitService.updateHabit(result);
      } else {
        await _habitService.addHabit(result);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background(context),
      body: SafeArea(
        child: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                HomeTab(
                  habitService: _habitService,
                  onAddHabit: () => _openAddHabit(),
                  onEditHabit: (habit) => _openAddHabit(editHabit: habit),
                ),
                CalendarTab(habitService: _habitService),
                StatisticsTab(habitService: _habitService),
                ProfileTab(habitService: _habitService),
              ],
            ),
            // Floating mini timer
            _FloatingMiniTimer(),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppTheme.surface(context),
          border: Border(
            top: BorderSide(
              color: AppTheme.cardBorderColor(context),
            ),
          ),
          boxShadow: Theme.of(context).brightness == Brightness.light
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ]
              : [],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(0, Icons.home_rounded, Icons.home_outlined, 'Home'),
                _buildNavItem(1, Icons.calendar_month_rounded, Icons.calendar_month_outlined, 'Calendar'),
                _buildNavItem(2, Icons.bar_chart_rounded, Icons.bar_chart_outlined, 'Stats'),
                _buildNavItem(3, Icons.person_rounded, Icons.person_outlined, 'Profile'),
              ],
            ),
          ),
        ),
      ),
      floatingActionButton: _currentIndex == 0
          ? FloatingActionButton(
              onPressed: () => _openAddHabit(),
              backgroundColor: AppTheme.primaryColor,
              elevation: 4,
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
    );
  }

  Widget _buildNavItem(int index, IconData activeIcon, IconData inactiveIcon, String label) {
    final isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppTheme.primaryColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isActive ? activeIcon : inactiveIcon,
              color: isActive ? AppTheme.primaryColor : AppTheme.textSecondaryColor(context),
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? AppTheme.primaryColor : AppTheme.textSecondaryColor(context),
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Floating Mini Timer ───
class _FloatingMiniTimer extends StatefulWidget {
  @override
  State<_FloatingMiniTimer> createState() => _FloatingMiniTimerState();
}

class _FloatingMiniTimerState extends State<_FloatingMiniTimer> {
  final TimerService _timerService = TimerService();

  @override
  void initState() {
    super.initState();
    _timerService.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _timerService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  void _openTimerDialog() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => _FullTimerDialog(
        timerService: _timerService,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_timerService.isActive) return const SizedBox.shrink();

    final ts = _timerService;
    return Positioned(
      bottom: 8,
      left: 16,
      right: 16,
      child: GestureDetector(
        onTap: _openTimerDialog,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: ts.color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: ts.color.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Mini progress ring
              SizedBox(
                width: 32,
                height: 32,
                child: CustomPaint(
                  painter: _MiniRingPainter(
                    progress: ts.progress,
                    color: Colors.white,
                    trackColor: Colors.white.withValues(alpha: 0.3),
                  ),
                  child: Center(
                    child: Icon(
                      ts.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ts.habitName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      ts.isRunning ? 'Running' : 'Paused',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                ts.formattedTime,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Full timer dialog opened from the mini timer
class _FullTimerDialog extends StatefulWidget {
  final TimerService timerService;

  const _FullTimerDialog({required this.timerService});

  @override
  State<_FullTimerDialog> createState() => _FullTimerDialogState();
}

class _FullTimerDialogState extends State<_FullTimerDialog> {
  @override
  void initState() {
    super.initState();
    widget.timerService.addListener(_onUpdate);
  }

  @override
  void dispose() {
    widget.timerService.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
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

  @override
  Widget build(BuildContext context) {
    final ts = widget.timerService;
    final isDone = ts.isDone;

    return Dialog(
      backgroundColor: AppTheme.surface(context),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ts.habitName,
                    style: TextStyle(
                      color: AppTheme.textPrimaryColor(context),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppTheme.textSecondaryColor(context),
                    size: 22,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 180,
              height: 180,
              child: CustomPaint(
                painter: _MiniRingPainter(
                  progress: ts.progress,
                  color: isDone ? const Color(0xFF4CAF50) : ts.color,
                  trackColor: AppTheme.cardBorderColor(context),
                  strokeWidth: 8,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _formatTime(ts.remainingSeconds),
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
            Row(
              children: [
                if (!isDone) ...[
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () {
                          ts.reset();
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.textSecondaryColor(context),
                          side: BorderSide(color: AppTheme.cardBorderColor(context)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Stop',
                            style: TextStyle(fontWeight: FontWeight.w500)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: ts.isRunning ? () => ts.pause() : () => ts.resume(),
                        icon: Icon(
                          ts.isRunning ? Icons.pause_rounded : Icons.play_arrow_rounded,
                          size: 20,
                        ),
                        label: Text(
                          ts.isRunning ? 'Pause' : 'Resume',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ts.color,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
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
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
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
}

class _MiniRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _MiniRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    this.strokeWidth = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth;

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _MiniRingPainter old) =>
      old.progress != progress || old.color != color;
}
