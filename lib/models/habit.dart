import 'dart:convert';

class Habit {
  final String id;
  String name;
  String category;
  int iconCodePoint;
  int colorValue;
  int? reminderHour;
  int? reminderMinute;
  List<int> repeatDays; // 1=Mon, 2=Tue, ... 7=Sun
  final DateTime createdAt;
  List<String> completedDates; // stored as 'yyyy-MM-dd'
  String notes;
  int difficulty; // 1=Easy, 2=Medium, 3=Hard
  List<String> tags;
  List<String> skippedDates; // stored as 'yyyy-MM-dd'
  int streakFreezes; // remaining freeze count
  int? targetPerWeek; // null = use repeatDays, e.g. 3 = any 3 days/week
  DateTime? deletedAt; // soft delete timestamp
  bool isPinned;
  int sortOrder;

  Habit({
    required this.id,
    required this.name,
    this.category = 'General',
    required this.iconCodePoint,
    required this.colorValue,
    this.reminderHour,
    this.reminderMinute,
    List<int>? repeatDays,
    required this.createdAt,
    List<String>? completedDates,
    this.notes = '',
    this.difficulty = 1,
    List<String>? tags,
    List<String>? skippedDates,
    this.streakFreezes = 2,
    this.targetPerWeek,
    this.deletedAt,
    this.isPinned = false,
    this.sortOrder = 0,
  })  : repeatDays = repeatDays ?? [1, 2, 3, 4, 5, 6, 7],
        completedDates = completedDates ?? [],
        tags = tags ?? [],
        skippedDates = skippedDates ?? [];

  bool get isDeleted => deletedAt != null;

  bool get hasReminder => reminderHour != null && reminderMinute != null;

  String get reminderText {
    if (!hasReminder) return 'No reminder';
    final h = reminderHour!;
    final m = reminderMinute!.toString().padLeft(2, '0');
    final period = h >= 12 ? 'PM' : 'AM';
    final hour = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$hour:$m $period';
  }

  String get repeatText {
    if (targetPerWeek != null) {
      return '$targetPerWeek times/week';
    }
    if (repeatDays.length == 7) return 'Every day';
    if (repeatDays.length == 5 &&
        repeatDays.every((d) => d >= 1 && d <= 5)) {
      return 'Weekdays';
    }
    if (repeatDays.length == 2 &&
        repeatDays.contains(6) &&
        repeatDays.contains(7)) {
      return 'Weekends';
    }
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return repeatDays.map((d) => names[d - 1]).join(', ');
  }

  String get difficultyText {
    switch (difficulty) {
      case 1:
        return 'Easy';
      case 2:
        return 'Medium';
      case 3:
        return 'Hard';
      default:
        return 'Easy';
    }
  }

  bool isScheduledFor(DateTime date) {
    if (targetPerWeek != null) return true; // any day counts
    return repeatDays.contains(date.weekday);
  }

  bool isCompletedOn(DateTime date) {
    return completedDates.contains(_dateKey(date));
  }

  bool isSkippedOn(DateTime date) {
    return skippedDates.contains(_dateKey(date));
  }

  void skipDate(DateTime date) {
    final key = _dateKey(date);
    if (!skippedDates.contains(key)) {
      skippedDates.add(key);
    }
  }

  void unskipDate(DateTime date) {
    skippedDates.remove(_dateKey(date));
  }

  void toggleDate(DateTime date) {
    final key = _dateKey(date);
    if (completedDates.contains(key)) {
      completedDates.remove(key);
    } else {
      completedDates.add(key);
    }
  }

  int get currentStreak {
    if (completedDates.isEmpty) return 0;
    final sorted = completedDates.toList()..sort((a, b) => b.compareTo(a));
    int streak = 0;
    var checkDate = DateTime.now();
    if (!isCompletedOn(checkDate)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }
    for (var i = 0; i < 365; i++) {
      final key = _dateKey(checkDate);
      if (sorted.contains(key)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else if (!isScheduledFor(checkDate) || isSkippedOn(checkDate)) {
        // Skip non-scheduled days and skipped dates
        checkDate = checkDate.subtract(const Duration(days: 1));
        continue;
      } else {
        break;
      }
    }
    return streak;
  }

  int get bestStreak {
    if (completedDates.isEmpty) return 0;
    final sorted = completedDates.toList()..sort();
    int best = 1;
    int current = 1;
    for (var i = 1; i < sorted.length; i++) {
      final prev = DateTime.parse(sorted[i - 1]);
      final curr = DateTime.parse(sorted[i]);
      final daysDiff = curr.difference(prev).inDays;
      if (daysDiff == 1) {
        current++;
        if (current > best) best = current;
      } else if (daysDiff > 1) {
        // Check if gap days are all non-scheduled or skipped
        bool allSkipped = true;
        for (var d = 1; d < daysDiff; d++) {
          final between = prev.add(Duration(days: d));
          if (isScheduledFor(between) && !isSkippedOn(between)) {
            allSkipped = false;
            break;
          }
        }
        if (allSkipped) {
          current++;
          if (current > best) best = current;
        } else {
          current = 1;
        }
      }
    }
    return best;
  }

  static String _dateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  static String todayKey() => _dateKey(DateTime.now());

  static String dateKeyFor(DateTime date) => _dateKey(date);

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'iconCodePoint': iconCodePoint,
        'colorValue': colorValue,
        'reminderHour': reminderHour,
        'reminderMinute': reminderMinute,
        'repeatDays': repeatDays,
        'createdAt': createdAt.toIso8601String(),
        'completedDates': completedDates,
        'notes': notes,
        'difficulty': difficulty,
        'tags': tags,
        'skippedDates': skippedDates,
        'streakFreezes': streakFreezes,
        'targetPerWeek': targetPerWeek,
        'deletedAt': deletedAt?.toIso8601String(),
        'isPinned': isPinned,
        'sortOrder': sortOrder,
      };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
        id: json['id'] as String,
        name: json['name'] as String,
        category: json['category'] as String? ?? 'General',
        iconCodePoint: json['iconCodePoint'] as int,
        colorValue: json['colorValue'] as int,
        reminderHour: json['reminderHour'] as int?,
        reminderMinute: json['reminderMinute'] as int?,
        repeatDays: (json['repeatDays'] as List<dynamic>?)
                ?.map((e) => e as int)
                .toList() ??
            [1, 2, 3, 4, 5, 6, 7],
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedDates: (json['completedDates'] as List<dynamic>)
            .map((e) => e as String)
            .toList(),
        notes: json['notes'] as String? ?? '',
        difficulty: json['difficulty'] as int? ?? 1,
        tags: (json['tags'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        skippedDates: (json['skippedDates'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        streakFreezes: json['streakFreezes'] as int? ?? 2,
        targetPerWeek: json['targetPerWeek'] as int?,
        deletedAt: json['deletedAt'] != null
            ? DateTime.parse(json['deletedAt'] as String)
            : null,
        isPinned: json['isPinned'] as bool? ?? false,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );

  static String encode(List<Habit> habits) =>
      jsonEncode(habits.map((h) => h.toJson()).toList());

  static List<Habit> decode(String source) =>
      (jsonDecode(source) as List<dynamic>)
          .map((e) => Habit.fromJson(e as Map<String, dynamic>))
          .toList();
}
