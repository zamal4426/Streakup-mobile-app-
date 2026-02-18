import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String _keyFirstTime = 'is_first_time';
  static const String _keyLoggedIn = 'is_logged_in';
  static const String _keyUserName = 'user_name';

  static late SharedPreferences _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  static bool get isFirstTime => _prefs.getBool(_keyFirstTime) ?? true;

  static Future<void> setFirstTimeDone() async {
    await _prefs.setBool(_keyFirstTime, false);
  }

  static bool get isLoggedIn => _prefs.getBool(_keyLoggedIn) ?? false;

  static Future<void> setLoggedIn(bool value) async {
    await _prefs.setBool(_keyLoggedIn, value);
  }

  static String get userName => _prefs.getString(_keyUserName) ?? '';

  static Future<void> setUserName(String name) async {
    await _prefs.setString(_keyUserName, name);
  }

  static bool get darkMode => _prefs.getBool('dark_mode') ?? true;

  static Future<void> setDarkMode(bool value) async {
    await _prefs.setBool('dark_mode', value);
  }

  static bool get notifications => _prefs.getBool('notifications') ?? true;

  static Future<void> setNotifications(bool value) async {
    await _prefs.setBool('notifications', value);
  }

  static String get userEmail => _prefs.getString('user_email') ?? '';

  static Future<void> setUserEmail(String email) async {
    await _prefs.setString('user_email', email);
  }

  static String get signInMethod => _prefs.getString('sign_in_method') ?? '';

  static Future<void> setSignInMethod(String method) async {
    await _prefs.setString('sign_in_method', method);
  }

  static String get profilePhotoPath =>
      _prefs.getString('profile_photo_path') ?? '';

  static Future<void> setProfilePhotoPath(String path) async {
    await _prefs.setString('profile_photo_path', path);
  }

  static List<String> get customCategories =>
      _prefs.getStringList('custom_categories') ?? [];

  static Future<void> setCustomCategories(List<String> cats) async {
    await _prefs.setStringList('custom_categories', cats);
  }

  static List<String> get customTags =>
      _prefs.getStringList('custom_tags') ?? [];

  static Future<void> setCustomTags(List<String> tags) async {
    await _prefs.setStringList('custom_tags', tags);
  }

  // --- Daily Snapshots ---
  static Map<String, dynamic> get dailySnapshots {
    final data = _prefs.getString('daily_snapshots');
    if (data == null || data.isEmpty) return {};
    return jsonDecode(data) as Map<String, dynamic>;
  }

  static Future<void> setDailySnapshots(Map<String, dynamic> snapshots) async {
    await _prefs.setString('daily_snapshots', jsonEncode(snapshots));
  }

  // --- Smart Reminder ---
  static bool get smartReminder => _prefs.getBool('smart_reminder') ?? false;

  static Future<void> setSmartReminder(bool value) async {
    await _prefs.setBool('smart_reminder', value);
  }

  static int get smartReminderMinutes =>
      _prefs.getInt('smart_reminder_minutes') ?? 5;

  static Future<void> setSmartReminderMinutes(int minutes) async {
    await _prefs.setInt('smart_reminder_minutes', minutes);
  }
}
