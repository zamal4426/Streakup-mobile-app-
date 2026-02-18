import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../theme/app_theme.dart';
import '../../services/storage_service.dart';
import '../../services/auth_service.dart';
import '../../services/habit_service.dart';
import '../../services/celebration_sound.dart';
import '../../models/habit.dart';
import '../habit_detail_screen.dart';

class HomeTab extends StatefulWidget {
  final HabitService habitService;
  final VoidCallback onAddHabit;
  final void Function(Habit habit) onEditHabit;

  const HomeTab({
    super.key,
    required this.habitService,
    required this.onAddHabit,
    required this.onEditHabit,
  });

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> with TickerProviderStateMixin {
  double _prevProgress = -1;
  bool _showConfetti = false;
  bool _hasInitialized = false;
  late AnimationController _confettiController;
  late List<_ConfettiParticle> _particles;
  final math.Random _random = math.Random();

  // Search & filter state
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _activeFilter = 'All'; // 'All', 'Completed', 'Incomplete', or a category/tag name
  bool _isTagFilter = false;

  @override
  void initState() {
    super.initState();
    _confettiController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() => _showConfetti = false);
        }
      });
    _particles = [];
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _triggerConfetti() {
    _particles = List.generate(60, (_) => _ConfettiParticle(_random));
    _confettiController.reset();
    setState(() => _showConfetti = true);
    _confettiController.forward();

    // Play celebration chime + haptic feedback
    CelebrationSound.play();
    HapticFeedback.mediumImpact();
  }

  String _getMotivationalMessage(double progress, int total) {
    if (total == 0) return 'Add your first habit to get started!';
    final pct = (progress * 100).toInt();
    if (pct == 0) return "Let's get started! Your habits are waiting.";
    if (pct <= 25) return 'Good start! Keep the momentum going.';
    if (pct <= 50) return "You're on a roll! Halfway there.";
    if (pct <= 75) return 'Amazing progress! Keep pushing.';
    if (pct < 100) return 'So close! Just a few more to go.';
    return 'You nailed it! All habits completed!';
  }

  IconData _getMotivationalIcon(double progress, int total) {
    if (total == 0) return Icons.add_circle_outline_rounded;
    final pct = (progress * 100).toInt();
    if (pct == 0) return Icons.play_arrow_rounded;
    if (pct <= 25) return Icons.trending_up_rounded;
    if (pct <= 50) return Icons.speed_rounded;
    if (pct <= 75) return Icons.bolt_rounded;
    if (pct < 100) return Icons.whatshot_rounded;
    return Icons.celebration_rounded;
  }

  Color _getMotivationalColor(double progress) {
    final pct = (progress * 100).toInt();
    if (pct == 0) return AppTheme.primaryColor;
    if (pct <= 50) return AppTheme.primaryColor;
    if (pct < 100) return const Color(0xFFFFB74D);
    return const Color(0xFF4CAF50);
  }

  List<Habit> _filterHabits(List<Habit> habits) {
    var filtered = habits.toList();

    // Apply search
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((h) => h.name.toLowerCase().contains(q)).toList();
    }

    // Apply filter
    if (_activeFilter == 'Completed') {
      filtered = filtered.where((h) => h.isCompletedOn(DateTime.now())).toList();
    } else if (_activeFilter == 'Incomplete') {
      filtered = filtered.where((h) => !h.isCompletedOn(DateTime.now())).toList();
    } else if (_activeFilter != 'All') {
      if (_isTagFilter) {
        filtered = filtered.where((h) => h.tags.contains(_activeFilter)).toList();
      } else {
        filtered = filtered.where((h) => h.category == _activeFilter).toList();
      }
    }

    return filtered;
  }

  Set<String> _collectCategories(List<Habit> habits) {
    return habits.map((h) => h.category).toSet();
  }

  Set<String> _collectTags(List<Habit> habits) {
    final tags = <String>{};
    for (final h in habits) {
      tags.addAll(h.tags);
    }
    return tags;
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final name = user?.displayName ?? StorageService.userName;
    final firstName = name.isNotEmpty ? name.split(' ').first : 'User';

    return ListenableBuilder(
      listenable: widget.habitService,
      builder: (context, _) {
        final habits = widget.habitService.habits;
        final completed = widget.habitService.todayCompleted;
        final total = widget.habitService.totalHabits;
        final progress = widget.habitService.todayProgress;
        final filteredHabits = _filterHabits(habits);
        final categories = _collectCategories(habits);
        final tags = _collectTags(habits);

        // Detect 100% completion (skip initial data load)
        if (!_hasInitialized && total > 0) {
          _hasInitialized = true;
          _prevProgress = progress;
        } else if (_hasInitialized &&
            _prevProgress >= 0 &&
            _prevProgress < 1.0 &&
            progress >= 1.0 &&
            total > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _triggerConfetti();
          });
        }
        _prevProgress = progress;

        return Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Horizontal calendar strip
                  _CalendarStrip(),
                  const SizedBox(height: 16),

                  // Greeting + progress
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          'Hey, $firstName!',
                          style: AppTheme.appNameStyle.copyWith(
                            fontSize: 24,
                            color: AppTheme.textPrimaryColor(context),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Progress circle
                      _ProgressCircle(
                        progress: progress,
                        completed: completed,
                        total: total,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Motivational message
                  _MotivationBanner(
                    message: _getMotivationalMessage(progress, total),
                    icon: _getMotivationalIcon(progress, total),
                    color: _getMotivationalColor(progress),
                    progress: progress,
                  ),
                  const SizedBox(height: 16),

                  // Search bar
                  if (habits.isNotEmpty) ...[
                    _buildSearchBar(context),
                    const SizedBox(height: 10),
                    // Filter chips
                    _buildFilterChips(context, categories, tags),
                    const SizedBox(height: 14),
                  ],

                  // My Habits header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'My Habits',
                        style: TextStyle(
                          color: AppTheme.textPrimaryColor(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '$completed / $total done',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor(context),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Habit list or empty state
                  Expanded(
                    child: habits.isEmpty
                        ? _buildEmptyState(context)
                        : filteredHabits.isEmpty
                            ? _buildNoResultsState(context)
                            : ReorderableListView.builder(
                                padding: const EdgeInsets.only(bottom: 80),
                                itemCount: filteredHabits.length,
                                onReorder: (oldIndex, newIndex) {
                                  if (newIndex > oldIndex) newIndex--;
                                  widget.habitService
                                      .reorderHabit(oldIndex, newIndex);
                                },
                                proxyDecorator: (child, index, animation) {
                                  return AnimatedBuilder(
                                    animation: animation,
                                    builder: (context, child) {
                                      final elevate = Tween<double>(
                                        begin: 0,
                                        end: 4,
                                      ).animate(animation);
                                      return Material(
                                        elevation: elevate.value,
                                        color: Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        child: child,
                                      );
                                    },
                                    child: child,
                                  );
                                },
                                itemBuilder: (context, index) {
                                  final habit = filteredHabits[index];
                                  return Padding(
                                    key: ValueKey(habit.id),
                                    padding:
                                        const EdgeInsets.only(bottom: 10),
                                    child: _HabitTile(
                                      habit: habit,
                                      index: index,
                                      onToggle: () {
                                        widget.habitService
                                            .toggleHabitToday(habit.id);
                                      },
                                      onTap: () =>
                                          _openDetail(context, habit),
                                      onEdit: () =>
                                          _editHabit(context, habit),
                                      onDelete: () =>
                                          _deleteHabit(context, habit),
                                      onPin: () {
                                        widget.habitService
                                            .togglePin(habit.id);
                                      },
                                      onStreakMilestone: () {
                                        _triggerConfetti();
                                      },
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),

            // Confetti overlay
            if (_showConfetti)
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _confettiController,
                    builder: (context, _) {
                      return CustomPaint(
                        painter: _ConfettiPainter(
                          particles: _particles,
                          progress: _confettiController.value,
                        ),
                      );
                    },
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      controller: _searchController,
      style: TextStyle(color: AppTheme.textPrimaryColor(context), fontSize: 14),
      onChanged: (val) => setState(() => _searchQuery = val.trim()),
      decoration: InputDecoration(
        hintText: 'Search habits...',
        hintStyle: TextStyle(
            color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.4),
            fontSize: 13),
        filled: true,
        fillColor: AppTheme.surface(context),
        prefixIcon: Icon(Icons.search_rounded,
            color: AppTheme.textSecondaryColor(context), size: 20),
        suffixIcon: _searchQuery.isNotEmpty
            ? GestureDetector(
                onTap: () {
                  _searchController.clear();
                  setState(() => _searchQuery = '');
                },
                child: Icon(Icons.close_rounded,
                    color: AppTheme.textSecondaryColor(context), size: 18),
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
    );
  }

  Widget _buildFilterChips(BuildContext context, Set<String> categories, Set<String> tags) {
    return SizedBox(
      height: 34,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(context, 'All', false),
          const SizedBox(width: 6),
          _buildFilterChip(context, 'Completed', false),
          const SizedBox(width: 6),
          _buildFilterChip(context, 'Incomplete', false),
          ...categories.map((cat) {
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _buildFilterChip(context, cat, false),
            );
          }),
          ...tags.map((tag) {
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: _buildFilterChip(context, tag, true),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context, String label, bool isTag) {
    final isActive = _activeFilter == label && _isTagFilter == isTag;
    // For 'All', 'Completed', 'Incomplete' — isTagFilter doesn't matter
    final isStatusFilter = label == 'All' || label == 'Completed' || label == 'Incomplete';
    final active = isStatusFilter ? (_activeFilter == label && !_isTagFilter) : isActive;

    return GestureDetector(
      onTap: () => setState(() {
        _activeFilter = label;
        _isTagFilter = isTag;
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppTheme.primaryColor.withValues(alpha: 0.15)
              : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active
                ? AppTheme.primaryColor
                : AppTheme.textSecondaryColor(context).withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTag) ...[
              Icon(Icons.tag_rounded,
                  color: active
                      ? AppTheme.primaryColor
                      : AppTheme.textSecondaryColor(context),
                  size: 12),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: TextStyle(
                color: active
                    ? AppTheme.primaryColor
                    : AppTheme.textSecondaryColor(context),
                fontSize: 12,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.trending_up_rounded,
            size: 72,
            color: AppTheme.primaryColor.withValues(alpha: 0.25),
          ),
          const SizedBox(height: 16),
          Text(
            'No habits yet',
            style: TextStyle(
              color: AppTheme.textSecondaryColor(context),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap + to add your first habit',
            style: AppTheme.taglineStyle.copyWith(
              color: AppTheme.textSecondaryColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_rounded,
            size: 56,
            color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.3),
          ),
          const SizedBox(height: 12),
          Text(
            'No habits match your filter',
            style: TextStyle(
              color: AppTheme.textSecondaryColor(context),
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => setState(() {
              _activeFilter = 'All';
              _isTagFilter = false;
              _searchController.clear();
              _searchQuery = '';
            }),
            child: Text(
              'Clear filters',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context, Habit habit) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HabitDetailScreen(
          habit: habit,
          habitService: widget.habitService,
          onEdit: () => widget.onEditHabit(habit),
        ),
      ),
    );
  }

  void _editHabit(BuildContext context, Habit habit) {
    widget.onEditHabit(habit);
  }

  Future<void> _deleteHabit(BuildContext context, Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface(context),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Delete Habit',
            style: TextStyle(color: AppTheme.textPrimaryColor(context))),
        content: Text(
          'Delete "${habit.name}"? This will remove all streak data.',
          style: TextStyle(color: AppTheme.textSecondaryColor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel',
                style:
                    TextStyle(color: AppTheme.textSecondaryColor(context))),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete',
                style: TextStyle(color: AppTheme.accentColor)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await widget.habitService.deleteHabit(habit.id);
    }
  }

}

// ─── Motivational Message Banner ───
class _MotivationBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color color;
  final double progress;

  const _MotivationBanner({
    required this.message,
    required this.icon,
    required this.color,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.15),
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: Container(
        key: ValueKey(message),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Progress Circle Widget (animated, color-shifting, glow) ───
class _ProgressCircle extends StatefulWidget {
  final double progress;
  final int completed;
  final int total;

  const _ProgressCircle({
    required this.progress,
    required this.completed,
    required this.total,
  });

  @override
  State<_ProgressCircle> createState() => _ProgressCircleState();
}

class _ProgressCircleState extends State<_ProgressCircle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animation = Tween<double>(begin: 0, end: widget.progress).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant _ProgressCircle old) {
    super.didUpdateWidget(old);
    if (old.progress != widget.progress) {
      _oldProgress = _animation.value;
      _animation = Tween<double>(
        begin: _oldProgress,
        end: widget.progress,
      ).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
      );
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static List<Color> _arcColors(double p) {
    if (p >= 1.0) return [const Color(0xFF4CAF50), const Color(0xFF2E7D32)];
    if (p >= 0.8) return [const Color(0xFF4CAF50), const Color(0xFF66BB6A)];
    if (p >= 0.5) return [AppTheme.primaryColor, const Color(0xFFFFB74D)];
    if (p >= 0.25) return [AppTheme.primaryColor, AppTheme.accentColor];
    return [AppTheme.accentColor, AppTheme.primaryColor];
  }

  static Color _percentColor(double p) {
    if (p >= 1.0) return const Color(0xFF4CAF50);
    if (p >= 0.8) return const Color(0xFF66BB6A);
    if (p >= 0.5) return AppTheme.primaryColor;
    return AppTheme.accentColor;
  }

  @override
  Widget build(BuildContext context) {
    final trackColor = Theme.of(context).brightness == Brightness.dark
        ? AppTheme.surfaceColor
        : const Color(0xFFE0E0E0);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final animVal = _animation.value.clamp(0.0, 1.0);
        final showGlow = animVal >= 1.0;
        final colors = _arcColors(animVal);
        final pctColor = _percentColor(animVal);

        return Container(
          width: 68,
          height: 68,
          decoration: showGlow
              ? BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: colors.first.withValues(alpha: 0.10),
                      blurRadius: 6,
                      spreadRadius: 0,
                    ),
                  ],
                )
              : null,
          child: SizedBox(
            width: 64,
            height: 64,
            child: CustomPaint(
              painter: _CirclePainter(
                progress: animVal,
                trackColor: trackColor,
                arcColors: colors,
                glowing: showGlow,
              ),
              child: Center(
                child: widget.total == 0
                    ? Icon(
                        Icons.trending_up_rounded,
                        color:
                            AppTheme.primaryColor.withValues(alpha: 0.5),
                        size: 24,
                      )
                    : Text(
                        '${(animVal * 100).toInt()}%',
                        style: TextStyle(
                          color: pctColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CirclePainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final List<Color> arcColors;
  final bool glowing;

  _CirclePainter({
    required this.progress,
    required this.trackColor,
    required this.arcColors,
    required this.glowing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // Background track
    final bgPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawCircle(center, radius, bgPaint);

    if (progress <= 0) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweepAngle = 2 * math.pi * progress;

    // Subtle glow layer behind arc
    if (glowing) {
      final glowPaint = Paint()
        ..shader = SweepGradient(
          startAngle: -math.pi / 2,
          endAngle: -math.pi / 2 + sweepAngle,
          colors: arcColors,
          tileMode: TileMode.clamp,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);

      canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, glowPaint);
    }

    // Main arc
    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweepAngle,
        colors: arcColors,
        tileMode: TileMode.clamp,
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweepAngle, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _CirclePainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.trackColor != trackColor ||
      oldDelegate.glowing != glowing ||
      oldDelegate.arcColors != arcColors;
}

// ─── Habit Tile Widget (with streak animation) ───
class _HabitTile extends StatefulWidget {
  final Habit habit;
  final int index;
  final VoidCallback onToggle;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onPin;
  final VoidCallback onStreakMilestone;

  const _HabitTile({
    super.key,
    required this.habit,
    required this.index,
    required this.onToggle,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onPin,
    required this.onStreakMilestone,
  });

  @override
  State<_HabitTile> createState() => _HabitTileState();
}

class _HabitTileState extends State<_HabitTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _streakAnimController;
  late Animation<double> _streakScale;
  late Animation<double> _checkScale;
  bool _wasCompleted = false;
  int _previousStreak = 0;

  @override
  void initState() {
    super.initState();
    _wasCompleted = widget.habit.isCompletedOn(DateTime.now());
    _previousStreak = widget.habit.currentStreak;
    _streakAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _streakScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.35), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 1.35, end: 0.9), weight: 25),
      TweenSequenceItem(tween: Tween(begin: 0.9, end: 1.1), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.1, end: 1.0), weight: 25),
    ]).animate(_streakAnimController);
    _checkScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.95), weight: 30),
      TweenSequenceItem(tween: Tween(begin: 0.95, end: 1.0), weight: 30),
    ]).animate(_streakAnimController);
  }

  @override
  void didUpdateWidget(covariant _HabitTile old) {
    super.didUpdateWidget(old);
    final nowCompleted = widget.habit.isCompletedOn(DateTime.now());
    final newStreak = widget.habit.currentStreak;

    if (!_wasCompleted && nowCompleted) {
      _streakAnimController.forward(from: 0);

      // Detect streak milestone crossings (3-day and 7-day)
      if ((_previousStreak < 3 && newStreak >= 3) ||
          (_previousStreak < 7 && newStreak >= 7)) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.onStreakMilestone();
        });
      }
    }

    _wasCompleted = nowCompleted;
    _previousStreak = newStreak;
  }

  @override
  void dispose() {
    _streakAnimController.dispose();
    super.dispose();
  }

  static IconData _difficultyIcon(int difficulty) {
    switch (difficulty) {
      case 2: return Icons.local_fire_department_rounded;
      case 3: return Icons.bolt_rounded;
      default: return Icons.eco_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCompleted = widget.habit.isCompletedOn(DateTime.now());
    final isSkipped = widget.habit.isSkippedOn(DateTime.now());
    final color = Color(widget.habit.colorValue);
    final streak = widget.habit.currentStreak;

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: () => _showOptions(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSkipped
              ? AppTheme.textSecondaryColor(context).withValues(alpha: 0.05)
              : isCompleted
                  ? color.withValues(alpha: 0.1)
                  : AppTheme.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSkipped
                ? AppTheme.textSecondaryColor(context).withValues(alpha: 0.15)
                : isCompleted
                    ? color.withValues(alpha: 0.3)
                    : AppTheme.cardBorderColor(context),
          ),
          boxShadow: isCompleted || isSkipped ? [] : AppTheme.cardShadow(context),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                IconData(widget.habit.iconCodePoint,
                    fontFamily: 'MaterialIcons'),
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),

            // Name + streak + tags
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Pin icon for pinned habits
                      if (widget.habit.isPinned)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.push_pin_rounded,
                            color: AppTheme.textSecondaryColor(context),
                            size: 13,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          widget.habit.name,
                          style: TextStyle(
                            color: AppTheme.textPrimaryColor(context),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                            decorationColor:
                                AppTheme.textSecondaryColor(context),
                          ),
                        ),
                      ),
                      // Difficulty badge
                      if (widget.habit.difficulty > 1)
                        Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: Icon(
                            _difficultyIcon(widget.habit.difficulty),
                            color: widget.habit.difficulty == 3
                                ? const Color(0xFFFFB74D)
                                : AppTheme.textSecondaryColor(context),
                            size: 14,
                          ),
                        ),
                    ],
                  ),
                  if (streak >= 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: AnimatedBuilder(
                        animation: _streakScale,
                        builder: (context, child) {
                          return Transform.scale(
                            scale: _streakScale.value,
                            alignment: Alignment.centerLeft,
                            child: child,
                          );
                        },
                        child: Row(
                          children: [
                            Text(
                              '\u{1F525}',
                              style: TextStyle(fontSize: 12),
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              child: Text(
                                '$streak Day Streak',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: color.withValues(alpha: 0.75),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (isSkipped)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        'Skipped today',
                        style: TextStyle(
                          color: AppTheme.textSecondaryColor(context),
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  // Tags
                  if (widget.habit.tags.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 4,
                        runSpacing: 2,
                        children: widget.habit.tags.map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: color.withValues(alpha: 0.8),
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                ],
              ),
            ),

            // Drag handle
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: ReorderableDragStartListener(
                index: widget.index,
                child: Icon(
                  Icons.drag_handle_rounded,
                  color: AppTheme.textSecondaryColor(context).withValues(alpha: 0.4),
                  size: 20,
                ),
              ),
            ),

            const SizedBox(width: 8),

            // Checkbox
            GestureDetector(
              onTap: widget.onToggle,
              child: AnimatedBuilder(
                animation: _checkScale,
                builder: (context, _) {
                  return Transform.scale(
                    scale: isCompleted && _streakAnimController.isAnimating
                        ? _checkScale.value
                        : 1.0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color:
                            isCompleted ? color : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCompleted
                              ? color
                              : AppTheme.textSecondaryColor(context)
                                  .withValues(alpha: 0.5),
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check_rounded,
                              color: Colors.white, size: 18)
                          : null,
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

  void _showOptions(BuildContext context) {
    final isPinned = widget.habit.isPinned;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textSecondaryColor(context)
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.habit.name,
              style: TextStyle(
                color: AppTheme.textPrimaryColor(context),
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              onTap: () {
                Navigator.of(context).pop();
                widget.onPin();
              },
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.background(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isPinned
                      ? Icons.push_pin_outlined
                      : Icons.push_pin_rounded,
                  color: AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              title: Text(
                isPinned ? 'Unpin Habit' : 'Pin to Top',
                style: TextStyle(
                  color: AppTheme.textPrimaryColor(context),
                  fontSize: 15,
                ),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(height: 4),
            ListTile(
              onTap: () {
                Navigator.of(context).pop();
                widget.onEdit();
              },
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.background(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_rounded,
                    color: AppTheme.primaryColor, size: 20),
              ),
              title: Text('Edit Habit',
                  style: TextStyle(
                      color: AppTheme.textPrimaryColor(context),
                      fontSize: 15)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(height: 4),
            ListTile(
              onTap: () {
                Navigator.of(context).pop();
                widget.onDelete();
              },
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.delete_rounded,
                    color: AppTheme.accentColor, size: 20),
              ),
              title: const Text('Delete Habit',
                  style: TextStyle(
                      color: AppTheme.accentColor, fontSize: 15)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

// ─── Calendar Strip Widget ───
class _CalendarStrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Show 9 days centered on today (-4 to +4)
    final days = List.generate(9, (i) => today.add(Duration(days: i - 4)));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorderColor(context)),
        boxShadow: AppTheme.cardShadow(context),
      ),
      child: Column(
        children: [
          // "Today" header
          Text(
            'Today',
            style: TextStyle(
              color: AppTheme.textPrimaryColor(context),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: days.map((day) {
              final isToday = day.isAtSameMomentAs(today);
              final dayLabel = _weekdayShort(day.weekday);
              final dateNum = day.day.toString();

              return Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      dayLabel,
                      style: TextStyle(
                        color: isToday
                            ? AppTheme.primaryColor
                            : AppTheme.textSecondaryColor(context)
                                .withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: isToday
                            ? AppTheme.primaryColor
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          dateNum,
                          style: TextStyle(
                            color: isToday
                                ? Colors.white
                                : AppTheme.textPrimaryColor(context),
                            fontSize: 13,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  static String _weekdayShort(int weekday) {
    const labels = ['MO', 'TU', 'WE', 'TH', 'FR', 'SA', 'SU'];
    return labels[weekday - 1];
  }
}

// ─── Confetti System ───
class _ConfettiParticle {
  late double x;
  late double y;
  late double vx;
  late double vy;
  late double size;
  late double rotation;
  late double rotationSpeed;
  late Color color;
  late int shape; // 0=circle, 1=rect, 2=star

  static const _colors = [
    Color(0xFFFF6B35),
    Color(0xFFE94560),
    Color(0xFF4CAF50),
    Color(0xFFFFB74D),
    Color(0xFF6C63FF),
    Color(0xFF42A5F5),
    Color(0xFF00C9A7),
  ];

  _ConfettiParticle(math.Random rng) {
    x = 0.3 + rng.nextDouble() * 0.4;
    y = 0.2 + rng.nextDouble() * 0.15;
    vx = (rng.nextDouble() - 0.5) * 0.6;
    vy = -(rng.nextDouble() * 0.5 + 0.3);
    size = rng.nextDouble() * 6 + 4;
    rotation = rng.nextDouble() * math.pi * 2;
    rotationSpeed = (rng.nextDouble() - 0.5) * 8;
    color = _colors[rng.nextInt(_colors.length)];
    shape = rng.nextInt(3);
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<_ConfettiParticle> particles;
  final double progress;

  _ConfettiPainter({required this.particles, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final gravity = 1.2;
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    for (final p in particles) {
      final t = progress;
      final px = (p.x + p.vx * t) * size.width;
      final py = (p.y + p.vy * t + gravity * t * t * 0.5) * size.height;
      final rot = p.rotation + p.rotationSpeed * t;

      if (py > size.height || px < 0 || px > size.width) continue;

      canvas.save();
      canvas.translate(px, py);
      canvas.rotate(rot);

      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.9)
        ..style = PaintingStyle.fill;

      switch (p.shape) {
        case 0:
          canvas.drawCircle(Offset.zero, p.size / 2, paint);
          break;
        case 1:
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromCenter(
                  center: Offset.zero, width: p.size, height: p.size * 0.6),
              const Radius.circular(1),
            ),
            paint,
          );
          break;
        case 2:
          final path = Path();
          for (var i = 0; i < 5; i++) {
            final angle = (i * 4 * math.pi / 5) - math.pi / 2;
            final r = p.size * 0.4;
            if (i == 0) {
              path.moveTo(r * math.cos(angle), r * math.sin(angle));
            } else {
              path.lineTo(r * math.cos(angle), r * math.sin(angle));
            }
          }
          path.close();
          canvas.drawPath(path, paint);
          break;
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter old) =>
      old.progress != progress;
}
