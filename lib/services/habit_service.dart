import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/habit.dart';
import 'notification_service.dart';
import 'firestore_service.dart';
import 'storage_service.dart';

class HabitService extends ChangeNotifier {
  static const String _key = 'habits_data';
  List<Habit> _habits = [];

  /// All habits including deleted ones (full list)
  List<Habit> get allHabitsIncludingDeleted => _habits;

  /// Only active (non-deleted) habits — used by home tab, add habit, etc.
  List<Habit> get activeHabits =>
      _habits.where((h) => !h.isDeleted).toList()
        ..sort((a, b) {
          // Pinned first, then by sortOrder
          if (a.isPinned && !b.isPinned) return -1;
          if (!a.isPinned && b.isPinned) return 1;
          return a.sortOrder.compareTo(b.sortOrder);
        });

  /// Legacy getter — now returns only active habits
  List<Habit> get habits => activeHabits;

  int get todayCompleted =>
      activeHabits.where((h) => h.isCompletedOn(DateTime.now())).length;

  int get totalHabits => activeHabits.length;

  double get todayProgress =>
      totalHabits == 0 ? 0.0 : todayCompleted / totalHabits;

  /// Returns habits that were active on a specific date (for calendar/stats)
  /// A habit is active on a date if: createdAt <= date AND (not deleted OR deletedAt > date)
  List<Habit> habitsActiveOnDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day, 23, 59, 59);
    return _habits.where((h) {
      final createdDate = DateTime(h.createdAt.year, h.createdAt.month, h.createdAt.day);
      if (createdDate.isAfter(dateOnly)) return false;
      if (h.deletedAt == null) return true;
      final deletedDate = DateTime(h.deletedAt!.year, h.deletedAt!.month, h.deletedAt!.day);
      return deletedDate.isAfter(DateTime(date.year, date.month, date.day));
    }).toList();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data != null && data.isNotEmpty) {
      _habits = Habit.decode(data);
    }

    // Cloud sync: try to merge with Firestore
    try {
      final cloudHabits = await FirestoreService.fetchAllHabits();
      if (cloudHabits.isNotEmpty) {
        // Cloud has data → use cloud as source of truth
        _habits = cloudHabits;
        await _save();
      } else if (_habits.isNotEmpty) {
        // Cloud empty but local has data → migrate to cloud
        await FirestoreService.uploadAll(_habits);
      }
    } catch (_) {
      // Offline or Firestore not configured — use local data
    }

    // Capture yesterday's snapshot if missing
    await _captureYesterdaySnapshotIfNeeded();

    notifyListeners();

    // Reschedule all alarms on every app startup.
    // The alarm package fires ONE-TIME alarms that are not automatically
    // rescheduled after firing, reboot, or app kill. This ensures the next
    // occurrence is always scheduled for every habit.
    await NotificationService.rescheduleAll(activeHabits);
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, Habit.encode(_habits));
  }

  Future<void> addHabit(Habit habit) async {
    // Shift all existing habits down so the new one appears at the top
    for (final h in _habits) {
      if (!h.isDeleted) h.sortOrder++;
    }
    habit.sortOrder = 0;
    _habits.add(habit);
    await _save();
    notifyListeners();
    await NotificationService.scheduleHabitReminder(habit);
    try { await FirestoreService.upsertHabit(habit); } catch (_) {}
  }

  Future<void> updateHabit(Habit habit) async {
    final index = _habits.indexWhere((h) => h.id == habit.id);
    if (index != -1) {
      _habits[index] = habit;
      await _save();
      notifyListeners();
      await NotificationService.scheduleHabitReminder(habit);
      try { await FirestoreService.upsertHabit(habit); } catch (_) {}
    }
  }

  /// Soft-delete: sets deletedAt instead of removing
  Future<void> deleteHabit(String id) async {
    final index = _habits.indexWhere((h) => h.id == id);
    if (index != -1) {
      final habit = _habits[index];
      await NotificationService.cancelHabitReminder(habit);
      habit.deletedAt = DateTime.now();
      await _save();
      notifyListeners();
      try { await FirestoreService.upsertHabit(habit); } catch (_) {}
    }
  }

  Habit? _findHabit(String id) {
    final idx = _habits.indexWhere((h) => h.id == id);
    return idx == -1 ? null : _habits[idx];
  }

  Future<void> toggleHabitToday(String id) async {
    final habit = _findHabit(id);
    if (habit == null) return;
    habit.toggleDate(DateTime.now());
    await _save();
    notifyListeners();
    try { await FirestoreService.upsertHabit(habit); } catch (_) {}
  }

  Future<void> toggleHabitOnDate(String id, DateTime date) async {
    final habit = _findHabit(id);
    if (habit == null) return;
    habit.toggleDate(date);
    await _save();
    notifyListeners();
    try { await FirestoreService.upsertHabit(habit); } catch (_) {}
  }

  Future<void> skipHabitToday(String id) async {
    final habit = _findHabit(id);
    if (habit == null) return;
    habit.skipDate(DateTime.now());
    await _save();
    notifyListeners();
    try { await FirestoreService.upsertHabit(habit); } catch (_) {}
  }

  Future<void> unskipHabitToday(String id) async {
    final habit = _findHabit(id);
    if (habit == null) return;
    habit.unskipDate(DateTime.now());
    await _save();
    notifyListeners();
    try { await FirestoreService.upsertHabit(habit); } catch (_) {}
  }

  Future<void> useStreakFreeze(String id) async {
    final habit = _findHabit(id);
    if (habit == null) return;
    if (habit.streakFreezes > 0) {
      habit.streakFreezes--;
      habit.skipDate(DateTime.now());
      await _save();
      notifyListeners();
      try { await FirestoreService.upsertHabit(habit); } catch (_) {}
    }
  }

  // --- Reorder & Pin ---

  Future<void> reorderHabit(int oldIndex, int newIndex) async {
    final active = activeHabits;
    if (oldIndex < 0 || oldIndex >= active.length) return;
    if (newIndex < 0 || newIndex >= active.length) return;

    final movedHabit = active[oldIndex];
    active.removeAt(oldIndex);
    active.insert(newIndex, movedHabit);

    // Update sortOrder for all active habits
    for (var i = 0; i < active.length; i++) {
      active[i].sortOrder = i;
    }

    await _save();
    notifyListeners();
    try {
      for (final h in active) {
        await FirestoreService.upsertHabit(h);
      }
    } catch (_) {}
  }

  Future<void> togglePin(String id) async {
    final habit = _findHabit(id);
    if (habit == null) return;
    habit.isPinned = !habit.isPinned;
    await _save();
    notifyListeners();
    try { await FirestoreService.upsertHabit(habit); } catch (_) {}
  }

  // --- Snapshot System ---

  Future<void> _captureYesterdaySnapshotIfNeeded() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final key = Habit.dateKeyFor(yesterday);
    final snapshots = StorageService.dailySnapshots;

    if (snapshots.containsKey(key)) return; // Already captured

    _captureSnapshotForDate(yesterday, snapshots);
    await StorageService.setDailySnapshots(snapshots);
  }

  void _captureSnapshotForDate(DateTime date, Map<String, dynamic> snapshots) {
    final key = Habit.dateKeyFor(date);
    final activeOnDate = habitsActiveOnDate(date);

    int totalScheduled = 0;
    int totalCompleted = 0;
    final List<Map<String, dynamic>> habitDetails = [];

    for (final habit in activeOnDate) {
      if (habit.isScheduledFor(date)) {
        totalScheduled++;
        final completed = habit.isCompletedOn(date);
        if (completed) totalCompleted++;
        habitDetails.add({
          'id': habit.id,
          'name': habit.name,
          'completed': completed,
        });
      }
    }

    final percentage = totalScheduled == 0
        ? 0.0
        : (totalCompleted / totalScheduled * 100).roundToDouble();

    snapshots[key] = {
      'date': key,
      'totalScheduled': totalScheduled,
      'totalCompleted': totalCompleted,
      'percentage': percentage,
      'habits': habitDetails,
    };
  }

  /// Get snapshot data for a specific date (returns null if not found)
  Map<String, dynamic>? getSnapshotForDate(DateTime date) {
    final key = Habit.dateKeyFor(date);
    final snapshots = StorageService.dailySnapshots;
    return snapshots[key] as Map<String, dynamic>?;
  }

  /// Get all snapshots
  Map<String, dynamic> get allSnapshots => StorageService.dailySnapshots;
}
