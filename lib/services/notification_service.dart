import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:alarm/alarm.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../models/habit.dart';
import 'storage_service.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _permissionGranted = false;
  static bool _initialized = false;

  static bool get _isDesktop =>
      defaultTargetPlatform == TargetPlatform.linux ||
      defaultTargetPlatform == TargetPlatform.windows;

  static Future<void> init() async {
    if (_isDesktop) return;
    if (_initialized) return;

    tz.initializeTimeZones();

    // Set local timezone from device
    try {
      final now = DateTime.now();
      final offset = now.timeZoneOffset;
      final tzName = now.timeZoneName;

      // First, try to match by the Dart-reported timezone name (e.g. "EST",
      // "CET"). This is more reliable than offset alone because multiple
      // timezones can share the same UTC offset.
      tz.Location? bestMatch;
      try {
        bestMatch = tz.getLocation(tzName);
      } catch (e) {
        debugPrint('Notification error: $e');
      }

      if (bestMatch == null) {
        // Fallback: find the first location whose current UTC offset matches.
        final candidates = tz.timeZoneDatabase.locations.values.where((loc) {
          try {
            return tz.TZDateTime.now(loc).timeZoneOffset == offset;
          } catch (e) {
            debugPrint('Notification error: $e');
            return false;
          }
        });
        if (candidates.isNotEmpty) {
          bestMatch = candidates.first;
        }
      }

      if (bestMatch != null) {
        tz.setLocalLocation(bestMatch);
        debugPrint('Timezone set to ${bestMatch.name}');
      } else {
        // Ultimate fallback: UTC so scheduled notifications still work.
        tz.setLocalLocation(tz.getLocation('UTC'));
        debugPrint('Could not detect timezone; defaulting to UTC');
      }
    } catch (e) {
      debugPrint('Failed to set local timezone: $e');
      // Ensure we always have a valid local location even on failure.
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (e) { debugPrint('Notification error: $e'); }
    }

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Create notification channel for pre-reminders and follow-ups
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.createNotificationChannel(
        const AndroidNotificationChannel(
          'habit_reminders',
          'Habit Reminders',
          description: 'Pre-reminder and follow-up notifications',
          importance: Importance.high,
          playSound: true,
          enableVibration: true,
        ),
      );

      await android.requestExactAlarmsPermission();
    }

    _initialized = true;
    await requestPermission();
  }

  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  static Future<bool> requestPermission() async {
    if (_isDesktop) return false;
    if (_permissionGranted) return true;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      _permissionGranted = granted ?? true;
      return _permissionGranted;
    }

    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      _permissionGranted = granted ?? false;
      return _permissionGranted;
    }

    return false;
  }

  /// Whether notification permission has already been granted
  static bool get isPermissionGranted => _permissionGranted;

  /// Shows an explanation dialog before requesting notification permission.
  /// Returns true if permission was granted.
  static Future<bool> requestPermissionWithExplanation(BuildContext context) async {
    if (_isDesktop) return false;
    if (_permissionGranted) return true;

    // Show explanation dialog first
    final shouldProceed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.notifications_active_rounded, color: Color(0xFFFFB74D), size: 24),
            SizedBox(width: 10),
            Text('Enable Notifications'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'StreakUp uses notifications to help you stay on track with your habits.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            const _PermissionBullet(icon: Icons.alarm_rounded, text: 'Alarm reminders for each habit'),
            const SizedBox(height: 6),
            const _PermissionBullet(icon: Icons.schedule_send_rounded, text: 'Smart pre-reminders before your alarm'),
            const SizedBox(height: 6),
            const _PermissionBullet(icon: Icons.follow_the_signs_rounded, text: 'Follow-up nudges if you forget'),
            const SizedBox(height: 12),
            const Text(
              'You can change this anytime in Settings.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Not Now'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Enable'),
          ),
        ],
      ),
    );

    if (shouldProceed != true) return false;

    return await requestPermission();
  }

  /// How many weeks of alarms to schedule ahead.
  /// The alarm package fires ONE-TIME alarms, so we pre-schedule multiple
  /// weeks to ensure alarms ring even if the app is never opened.
  /// Smart reminder & follow-up use flutter_local_notifications with
  /// weekly recurrence, so they only need one schedule per weekday.
  static const int _weeksAhead = 3;

  /// Schedule alarms + notifications for a habit.
  /// Main alarm uses the `alarm` package (rings continuously until dismissed).
  /// Pre-reminder and follow-up use flutter_local_notifications.
  static Future<void> scheduleHabitReminder(Habit habit) async {
    if (_isDesktop) return;
    if (!StorageService.notifications) return;
    if (!habit.hasReminder) return;

    if (!_initialized) await init();
    final hasPermission = await requestPermission();
    if (!hasPermission) return;

    await cancelHabitReminder(habit);

    final now = DateTime.now();
    final tzNow = tz.TZDateTime.now(tz.local);

    for (final weekday in habit.repeatDays) {
      // Calculate next occurrence of this weekday
      var baseScheduled = DateTime(
        now.year,
        now.month,
        now.day,
        habit.reminderHour!,
        habit.reminderMinute!,
      );
      while (baseScheduled.weekday != weekday) {
        baseScheduled = baseScheduled.add(const Duration(days: 1));
      }
      if (baseScheduled.isBefore(now)) {
        baseScheduled = baseScheduled.add(const Duration(days: 7));
      }

      try {
        // ── MAIN ALARM (alarm package) ──
        // Schedule for the next _weeksAhead weeks so the alarm keeps
        // ringing daily even if the user never opens the app.
        for (int week = 0; week < _weeksAhead; week++) {
          final scheduled =
              baseScheduled.add(Duration(days: week * 7));
          final alarmId = _alarmId(habit.id, weekday, week);
          await Alarm.set(
            alarmSettings: AlarmSettings(
              id: alarmId,
              dateTime: scheduled,
              loopAudio: true,
              vibrate: true,
              androidFullScreenIntent: true,
              notificationSettings: NotificationSettings(
                title: 'StreakUp Alarm',
                body: "Time for ${habit.name}! Don't break your streak",
                stopButton: 'Stop',
              ),
              volumeSettings: VolumeSettings.fade(
                volume: 1.0,
                fadeDuration: const Duration(seconds: 10),
              ),
            ),
          );
        }

        // ── SMART PRE-REMINDER (notification, weekly recurring) ──
        if (StorageService.smartReminder) {
          final minutes = StorageService.smartReminderMinutes;
          final preScheduled = tz.TZDateTime(
            tz.local,
            baseScheduled.year,
            baseScheduled.month,
            baseScheduled.day,
            baseScheduled.hour,
            baseScheduled.minute,
          ).subtract(Duration(minutes: minutes));

          if (preScheduled.isAfter(tzNow)) {
            final preId = _smartReminderId(habit.id, weekday);
            await _plugin.zonedSchedule(
              preId,
              'Coming up soon',
              '${habit.name} in $minutes minutes',
              preScheduled,
              NotificationDetails(
                android: AndroidNotificationDetails(
                  'habit_reminders',
                  'Habit Reminders',
                  channelDescription: 'Pre-reminder and follow-up notifications',
                  importance: Importance.high,
                  priority: Priority.high,
                  icon: '@mipmap/ic_launcher',
                  playSound: true,
                  enableVibration: true,
                ),
                iOS: const DarwinNotificationDetails(
                  presentAlert: true,
                  presentBadge: true,
                  presentSound: true,
                  sound: 'default',
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
              matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
            );
          }
        }

        // ── FOLLOW-UP NOTIFICATION (2 hours later, weekly recurring) ──
        final followUpScheduled = tz.TZDateTime(
          tz.local,
          baseScheduled.year,
          baseScheduled.month,
          baseScheduled.day,
          baseScheduled.hour,
          baseScheduled.minute,
        ).add(const Duration(hours: 2));

        final followUpId = _followUpNotificationId(habit.id, weekday);
        await _plugin.zonedSchedule(
          followUpId,
          'StreakUp Follow-up',
          "You haven't completed ${habit.name} yet! Keep your streak alive",
          followUpScheduled,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'habit_reminders',
              'Habit Reminders',
              channelDescription: 'Pre-reminder and follow-up notifications',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
              playSound: true,
              enableVibration: true,
            ),
            iOS: const DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              sound: 'default',
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );

        debugPrint(
            'Scheduled $_weeksAhead weeks of alarms for ${habit.name} on weekday $weekday at ${habit.reminderHour}:${habit.reminderMinute}');
      } catch (e) {
        debugPrint('Failed to schedule alarm for ${habit.name}: $e');
      }
    }
  }


  static Future<void> cancelHabitReminder(Habit habit) async {
    if (_isDesktop) return;
    for (final weekday in [1, 2, 3, 4, 5, 6, 7]) {
      // Cancel all weeks of alarm package alarms
      for (int week = 0; week < _weeksAhead; week++) {
        await Alarm.stop(_alarmId(habit.id, weekday, week));
      }

      // Cancel notification reminders
      await _plugin.cancel(_smartReminderId(habit.id, weekday));
      await _plugin.cancel(_followUpNotificationId(habit.id, weekday));
    }
  }

  static Future<void> cancelAll() async {
    if (_isDesktop) return;
    await _plugin.cancelAll();
    await Alarm.stopAll();
  }

  static Future<void> rescheduleAll(List<Habit> habits) async {
    if (_isDesktop) return;
    final hasPermission = await requestPermission();
    if (!hasPermission) return;
    await cancelAll();
    for (final habit in habits) {
      await scheduleHabitReminder(habit);
    }
  }

  /// Alarm ID for the alarm package (main alarm).
  /// Unique per (habit, weekday, weekOffset).
  static int _alarmId(String habitId, int weekday, [int weekOffset = 0]) {
    return (habitId.hashCode.abs() % 100000) * 100 + weekday * 10 + weekOffset;
  }

  /// Smart pre-reminder notification ID (flutter_local_notifications).
  static int _smartReminderId(String habitId, int weekday) {
    return (habitId.hashCode.abs() % 100000) * 10 + weekday + 5000000;
  }

  /// Follow-up notification ID (flutter_local_notifications).
  static int _followUpNotificationId(String habitId, int weekday) {
    return (habitId.hashCode.abs() % 100000) * 10 + weekday + 6000000;
  }
}

/// Helper widget used in the permission explanation dialog
class _PermissionBullet extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PermissionBullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFFFFB74D)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, height: 1.3),
          ),
        ),
      ],
    );
  }
}
